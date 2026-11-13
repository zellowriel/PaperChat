using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Chat;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.AI;

public sealed class UnconfiguredAiChatService : IAiChatService
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
        => throw new ServiceUnavailableException(
            "AI provider chưa được cấu hình. Hãy đăng ký adapter OpenAI/Gemini trước khi bật tính năng chat ở môi trường production.");
}
