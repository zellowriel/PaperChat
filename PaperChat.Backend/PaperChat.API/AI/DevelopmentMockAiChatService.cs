using PaperChat.Service.DTOs.Chat;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.AI;

/// <summary>Chỉ dùng khi chạy Development. Đây không phải tích hợp AI thật.</summary>
public sealed class DevelopmentMockAiChatService : IAiChatService
{
    public Task<AiChatResult> GenerateAnswerAsync(
    Guid userId,
    Guid documentId,
    string question,
    string? quote,
    string documentText,
    int pageCount,
    IReadOnlyList<ChatHistoryItemDto> history,
    CancellationToken cancellationToken = default)
    {
        var answer = string.IsNullOrWhiteSpace(quote)
            ? $"[DEVELOPMENT MOCK] PaperChat đã nhận câu hỏi: \"{question}\". Hãy thay DevelopmentMockAiChatService bằng adapter OpenAI/Gemini để tạo câu trả lời dựa trên nội dung PDF."
            : $"[DEVELOPMENT MOCK] Bạn đang hỏi về đoạn trích: \"{TrimQuote(quote)}\". Hãy cấu hình RAG/AI provider để nhận lời giải thích có căn cứ và số trang trích dẫn.";
        return Task.FromResult(new AiChatResult(answer, null));
    }

    private static string TrimQuote(string quote) => quote.Length <= 500 ? quote : quote[..500] + "…";
}
