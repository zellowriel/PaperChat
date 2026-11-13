using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Chat;
using PaperChat.Service.Interfaces;

namespace PaperChat.Service.Implementations;

public sealed class GeminiAiChatService(
    HttpClient httpClient,
    IOptions<GeminiOptions> options,
    ILogger<GeminiAiChatService> logger
) : IAiChatService
{
    private readonly GeminiOptions _options = options.Value;

    private const int MaxHistoryItems = 20;
    private const int MaxRetries = 3;
    private static readonly TimeSpan MaxRetryAfter = TimeSpan.FromSeconds(30);

    public async Task<AiChatResult> GenerateAnswerAsync(
        Guid userId,
        Guid documentId,
        string question,
        string? quote,
        string documentText,
        int pageCount,
        IReadOnlyList<ChatHistoryItemDto> history,
        CancellationToken cancellationToken = default)
    {
        // 1. Validate configuration and input.
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            throw new ServiceUnavailableException(
                "Gemini API Key chưa được cấu hình.");
        }

        if (string.IsNullOrWhiteSpace(_options.Model))
        {
            throw new ServiceUnavailableException(
                "Gemini Model chưa được cấu hình.");
        }

        if (string.IsNullOrWhiteSpace(documentText))
        {
            throw new ValidationAppException(
                "Nội dung PDF không được để trống.");
        }

        if (pageCount <= 0)
        {
            throw new ValidationAppException(
                "PageCount không hợp lệ.");
        }

        if (documentText.Length > _options.MaxDocumentCharacters)
        {
            throw new PayloadTooLargeException(
                $"Nội dung PDF vượt quá giới hạn " +
                $"{_options.MaxDocumentCharacters:N0} ký tự.");
        }

        // 2. Build Gemini history.
        var contents = new List<object>();

        foreach (var item in history.TakeLast(MaxHistoryItems))
        {
            var role = NormalizeRole(item.Role);

            if (role is null || string.IsNullOrWhiteSpace(item.Content))
                continue;

            contents.Add(new
            {
                role,
                parts = new[]
                {
                    new { text = item.Content }
                }
            });
        }

        // 3. Build the current user message with the entire extracted PDF text.
        var promptBuilder = new StringBuilder();
        promptBuilder.AppendLine(
            "Dưới đây là toàn bộ nội dung tài liệu PDF mà bạn cần tham khảo.");
        promptBuilder.AppendLine(
            $"Tài liệu có tổng cộng {pageCount} trang.");
        promptBuilder.AppendLine();
        promptBuilder.AppendLine("========== BEGIN PDF DOCUMENT ==========");
        promptBuilder.AppendLine(documentText);
        promptBuilder.AppendLine("========== END PDF DOCUMENT ==========");
        promptBuilder.AppendLine();

        if (!string.IsNullOrWhiteSpace(quote))
        {
            promptBuilder.AppendLine(
                "ĐOẠN VĂN BẢN NGƯỜI DÙNG ĐANG QUAN TÂM:");
            promptBuilder.AppendLine(quote.Trim());
            promptBuilder.AppendLine();
        }

        promptBuilder.AppendLine("CÂU HỎI CỦA NGƯỜI DÙNG:");
        promptBuilder.AppendLine(question.Trim());

        contents.Add(new
        {
            role = "user",
            parts = new[]
            {
                new { text = promptBuilder.ToString() }
            }
        });

        // 4. Build system instruction separately from the PDF content.
        var systemInstruction = new
        {
            parts = new[]
            {
                new { text = _options.SystemPrompt }
            }
        };

        // 5. Build request body.
        var requestBody = new
        {
            systemInstruction,
            contents,
            generationConfig = new
            {
                maxOutputTokens = _options.MaxOutputTokens
            }
        };

        var endpoint =
            $"{_options.BaseUrl.TrimEnd('/')}" +
            $"/v1beta/models/{Uri.EscapeDataString(_options.Model)}" +
            ":generateContent";

        HttpResponseMessage response;

        try
        {
            // 6. Send request. Retry only transient HTTP 503 responses.
            response = await SendWithRetryAsync(
                endpoint,
                requestBody,
                cancellationToken);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("Gemini API request timed out.");
            throw new ServiceUnavailableException(
                "Gemini phản hồi quá thời gian cho phép.");
        }
        catch (HttpRequestException exception)
        {
            logger.LogError(exception, "Cannot connect to Gemini API.");
            throw new ServiceUnavailableException(
                "Không thể kết nối tới Gemini API.");
        }

        using (response)
        {
            // 7. Preserve and log the actual error returned by Google.
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(
                    cancellationToken);

                var apiError = ParseGeminiError(errorBody);
                var httpCode = (int)response.StatusCode;
                var httpStatusName = response.StatusCode.ToString();
                var contentType = response.Content.Headers.ContentType?.ToString()
                    ?? "(no content-type)";

                var safeBody = errorBody;
                if (!string.IsNullOrWhiteSpace(_options.ApiKey))
                {
                    safeBody = safeBody.Replace(
                        _options.ApiKey,
                        "[REDACTED]",
                        StringComparison.Ordinal);
                }

                const int maxLogLength = 4000;
                if (safeBody.Length > maxLogLength)
                    safeBody = safeBody[..maxLogLength] + "... [TRUNCATED]";

                logger.LogError(
                    """
                    ================= GEMINI API ERROR =================
                    Model: {Model}
                    Endpoint: {Endpoint}
                    HTTP Code: {HttpCode}
                    HTTP Status Name: {HttpStatusName}
                    Content-Type: {ContentType}
                    Google Error Code: {GoogleErrorCode}
                    Google Status: {GoogleStatus}
                    Google Message: {GoogleMessage}
                    Raw Response Body: {RawBody}
                    ====================================================
                    """,
                    _options.Model,
                    endpoint,
                    httpCode,
                    httpStatusName,
                    contentType,
                    apiError.Code,
                    apiError.Status,
                    apiError.Message,
                    safeBody);

                var detailedMessage =
                    $"Gemini API Error: HTTP {httpCode} ({httpStatusName}). " +
                    $"Google Status: {apiError.Status ?? "Unknown"}. " +
                    $"Message: {apiError.Message ?? "No error message returned."}.";

                if (_options.ExposeDetailedErrors)
                    throw new ServiceUnavailableException(detailedMessage);

                throw new ServiceUnavailableException(
                    $"Gemini API không thể xử lý yêu cầu (HTTP {httpCode}).");
            }

            var responseJson = await response.Content.ReadAsStringAsync(
                cancellationToken);

            // 8. Parse Gemini response.
            try
            {
                using var json = JsonDocument.Parse(responseJson);
                var root = json.RootElement;

                if (!root.TryGetProperty("candidates", out var candidates) ||
                    candidates.ValueKind != JsonValueKind.Array ||
                    candidates.GetArrayLength() == 0)
                {
                    throw new ServiceUnavailableException(
                        "Gemini không trả về câu trả lời.");
                }

                var candidate = candidates[0];

                if (!candidate.TryGetProperty("content", out var content) ||
                    !content.TryGetProperty("parts", out var parts))
                {
                    throw new ServiceUnavailableException(
                        "Không tìm thấy nội dung phản hồi từ Gemini.");
                }

                var answerBuilder = new StringBuilder();

                foreach (var part in parts.EnumerateArray())
                {
                    // Do not include internal thought parts in the user-facing answer.
                    if (part.TryGetProperty("thought", out var thought) &&
                        thought.ValueKind == JsonValueKind.True)
                    {
                        continue;
                    }

                    if (part.TryGetProperty("text", out var textElement))
                        answerBuilder.AppendLine(textElement.GetString());
                }

                var answer = answerBuilder.ToString().Trim();

                if (string.IsNullOrWhiteSpace(answer))
                {
                    throw new ServiceUnavailableException(
                        "Gemini trả về nội dung rỗng.");
                }

                // 9. Extract and validate page citation.
                var (cleanAnswer, citationPage) = ExtractCitation(
                    answer,
                    pageCount);

                return new AiChatResult(cleanAnswer, citationPage);
            }
            catch (JsonException exception)
            {
                logger.LogError(exception, "Cannot parse Gemini response.");
                throw new ServiceUnavailableException(
                    "Không thể đọc phản hồi từ Gemini.");
            }
        }
    }

    /// <summary>
    /// Sends a fresh HTTP request for each attempt. Only HTTP 503 is retried.
    /// This avoids reusing a disposed HttpRequestMessage or HttpContent.
    /// </summary>
    private async Task<HttpResponseMessage> SendWithRetryAsync(
        string endpoint,
        object requestBody,
        CancellationToken cancellationToken)
    {
        for (var attempt = 0; ; attempt++)
        {
            using var request = new HttpRequestMessage(
                HttpMethod.Post,
                endpoint);

            request.Headers.TryAddWithoutValidation(
                "x-goog-api-key",
                _options.ApiKey.Trim());

            request.Content = JsonContent.Create(requestBody);

            var response = await httpClient.SendAsync(
                request,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken);

            // Do not retry client/configuration errors (400, 401, 403, 404),
            // quota errors (429), or successful responses.
            if (response.StatusCode != HttpStatusCode.ServiceUnavailable ||
                attempt >= MaxRetries)
            {
                return response;
            }

            var delay = GetRetryDelay(response, attempt);

            // If Google explicitly asks us to wait longer than our 30-second
            // retry budget, return the 503 rather than retrying too early.
            if (delay is null)
            {
                logger.LogWarning(
                    "Gemini returned HTTP 503 with Retry-After greater than {MaxSeconds}s. Stop retrying and return the response.",
                    MaxRetryAfter.TotalSeconds);
                return response;
            }

            logger.LogWarning(
                "Gemini returned HTTP 503 (high demand/unavailable). Retry {RetryNumber}/{MaxRetries} after {DelaySeconds:F1} seconds.",
                attempt + 1,
                MaxRetries,
                delay.Value.TotalSeconds);

            response.Dispose();
            await Task.Delay(delay.Value, cancellationToken);
        }
    }

    /// <summary>
    /// Honors Retry-After when it is within the retry budget; otherwise uses
    /// exponential backoff (2, 4, 8 seconds) plus a small random jitter.
    /// </summary>
    private static TimeSpan? GetRetryDelay(
        HttpResponseMessage response,
        int attempt)
    {
        var retryAfter = response.Headers.RetryAfter;

        if (retryAfter?.Delta is { } delta && delta > TimeSpan.Zero)
        {
            return delta <= MaxRetryAfter ? delta : null;
        }

        if (retryAfter?.Date is { } retryDate)
        {
            var remaining = retryDate - DateTimeOffset.UtcNow;

            if (remaining > TimeSpan.Zero)
                return remaining <= MaxRetryAfter ? remaining : null;
        }

        var exponentialSeconds = Math.Pow(2, attempt + 1); // 2, 4, 8
        var jitterSeconds = Random.Shared.NextDouble();
        var totalSeconds = Math.Min(
            exponentialSeconds + jitterSeconds,
            MaxRetryAfter.TotalSeconds);

        return TimeSpan.FromSeconds(totalSeconds);
    }

    private sealed record GeminiErrorInfo(
        int? Code,
        string? Status,
        string? Message);

    private static GeminiErrorInfo ParseGeminiError(string responseBody)
    {
        if (string.IsNullOrWhiteSpace(responseBody))
        {
            return new GeminiErrorInfo(
                null,
                null,
                "Google returned an empty response body.");
        }

        try
        {
            using var json = JsonDocument.Parse(responseBody);
            var root = json.RootElement;

            if (!root.TryGetProperty("error", out var error))
            {
                return new GeminiErrorInfo(
                    null,
                    null,
                    "JSON response does not contain an error object.");
            }

            int? code = null;
            string? status = null;
            string? message = null;

            if (error.TryGetProperty("code", out var codeElement) &&
                codeElement.ValueKind == JsonValueKind.Number &&
                codeElement.TryGetInt32(out var parsedCode))
            {
                code = parsedCode;
            }

            if (error.TryGetProperty("status", out var statusElement))
                status = statusElement.GetString();

            if (error.TryGetProperty("message", out var messageElement))
                message = messageElement.GetString();

            return new GeminiErrorInfo(code, status, message);
        }
        catch (JsonException)
        {
            return new GeminiErrorInfo(
                null,
                null,
                "Response body is not valid JSON.");
        }
    }

    // Map database roles to Gemini roles.
    private static string? NormalizeRole(string role)
    {
        if (string.Equals(role, "USER", StringComparison.OrdinalIgnoreCase))
            return "user";

        if (string.Equals(role, "AI", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(role, "ASSISTANT", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(role, "MODEL", StringComparison.OrdinalIgnoreCase))
        {
            return "model";
        }

        return null;
    }

    // Read [[PAGE: N]] marker and ensure N exists in the PDF.
    private static (string Answer, int? CitationPage) ExtractCitation(
        string answer,
        int pageCount)
    {
        const string pattern = @"(?im)^\s*\[\[PAGE:\s*(\d+)\s*\]\]\s*$";

        var matches = Regex.Matches(answer, pattern);
        var cleanAnswer = Regex.Replace(answer, pattern, string.Empty).Trim();

        if (matches.Count != 1)
            return (cleanAnswer, null);

        if (!int.TryParse(matches[0].Groups[1].Value, out var page))
            return (cleanAnswer, null);

        if (page < 1 || page > pageCount)
            return (cleanAnswer, null);

        return (cleanAnswer, page);
    }
}
