using System.Text;
using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Chat;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Service.Implementations;

public sealed class ChatService(
    ICurrentUserService currentUser,
    IDocumentRepository documents,
    IChatMessageRepository messages,
    IFileStorage fileStorage,
    IAiChatService aiChat
) : IChatService
{
    private const int MaxStoredHistory = 100;

    public async Task<ChatResponse> SendAsync(
        ChatRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = currentUser.UserId;

        // ==========================================
        // 1. CHECK DOCUMENT OWNERSHIP
        // ==========================================

        var document = await documents.GetByIdForUserAsync(
            request.DocumentId,
            userId,
            cancellationToken
        ) ?? throw new NotFoundException(
            "Không tìm thấy tài liệu hoặc bạn không có quyền truy cập."
        );

        if (!document.IsProcessed || document.PageCount <= 0)
        {
            throw new ConflictException(
                "Tài liệu chưa được xử lý PDF thành công."
            );
        }

        // ==========================================
        // 2. READ EXTRACTED PDF TEXT
        // ==========================================

        string documentText;

        try
        {
            await using var textStream =
                await fileStorage.OpenExtractedTextAsync(
                    document.FileKey,
                    cancellationToken
                );

            using var reader = new StreamReader(
                textStream,
                Encoding.UTF8,
                detectEncodingFromByteOrderMarks: true
            );

            documentText = await reader.ReadToEndAsync(
                cancellationToken
            );
        }
        catch (FileNotFoundException)
        {
            throw new ConflictException(
                "Không tìm thấy nội dung text đã trích xuất của PDF. " +
                "Tài liệu cần được xử lý lại."
            );
        }
        catch (DirectoryNotFoundException)
        {
            throw new ConflictException(
                "Không tìm thấy thư mục lưu trữ nội dung PDF."
            );
        }

        if (string.IsNullOrWhiteSpace(documentText))
        {
            throw new ConflictException(
                "Nội dung PDF đang trống. Không thể thực hiện hỏi đáp AI."
            );
        }

        // ==========================================
        // 3. GET CHAT HISTORY
        // ==========================================

        var history = request.ChatHistory.Count > 0
            ? request.ChatHistory
            : (await messages.GetHistoryAsync(
                    document.Id,
                    userId,
                    MaxStoredHistory,
                    cancellationToken
                ))
                .Select(x => new ChatHistoryItemDto
                {
                    Role = x.SenderRole,
                    Content = x.Content
                })
                .ToList();

        // ==========================================
        // 4. SEND FULL PDF TEXT TO GEMINI
        // ==========================================

        var aiResult = await aiChat.GenerateAnswerAsync(
            userId,
            document.Id,
            request.Question.Trim(),
            request.Quote,
            documentText,
            document.PageCount,
            history,
            cancellationToken
        );

        // ==========================================
        // 5. SAVE USER + AI MESSAGES
        // ==========================================

        var now = DateTimeOffset.UtcNow;

        var userMessageId = Guid.NewGuid();

        var assistantMessageId = Guid.NewGuid();

        var userMessage = new NewChatMessage(
            userMessageId,
            document.Id,
            userId,
            "USER",
            request.Question.Trim(),
            string.IsNullOrWhiteSpace(request.Quote)
                ? null
                : request.Quote.Trim(),
            null,
            now
        );

        var assistantMessage = new NewChatMessage(
            assistantMessageId,
            document.Id,
            userId,
            "AI",
            aiResult.Answer,
            null,
            aiResult.CitationPage,
            now.AddMilliseconds(1)
        );

        await messages.AddPairAsync(
            userMessage,
            assistantMessage,
            cancellationToken
        );

        // ==========================================
        // 6. RETURN RESPONSE
        // ==========================================

        return new ChatResponse(
            document.Id,
            userMessageId,
            assistantMessageId,
            assistantMessage.Content,
            assistantMessage.CitationPage,
            assistantMessage.CreatedAt
        );
    }

    public async Task<IReadOnlyList<ChatMessageResponse>> GetHistoryAsync(
        Guid documentId,
        CancellationToken cancellationToken = default)
    {
        if (await documents.GetByIdForUserAsync(
                documentId,
                currentUser.UserId,
                cancellationToken
            ) is null)
        {
            throw new NotFoundException("Không tìm thấy tài liệu.");
        }

        var history = await messages.GetHistoryAsync(
            documentId,
            currentUser.UserId,
            MaxStoredHistory,
            cancellationToken
        );

        return history.Select(x => new ChatMessageResponse(
            x.Id,
            x.SenderRole,
            x.Content,
            x.QuoteReference,
            x.CitationPage,
            x.CreatedAt
        )).ToList();
    }
}