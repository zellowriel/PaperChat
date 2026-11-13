using PaperChat.Service.DTOs.Chat;

namespace PaperChat.Service.Interfaces;

public interface IAiChatService
{
    Task<AiChatResult> GenerateAnswerAsync(
        Guid userId,
        Guid documentId,
        string question,
        string? quote,
        string documentText,
        int pageCount,
        IReadOnlyList<ChatHistoryItemDto> history,
        CancellationToken cancellationToken = default
    );
}