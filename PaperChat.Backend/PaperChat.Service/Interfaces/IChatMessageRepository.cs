using PaperChat.Service.Models;

namespace PaperChat.Service.Interfaces;

public interface IChatMessageRepository
{
    Task<IReadOnlyList<ChatMessageRecord>> GetHistoryAsync(Guid documentId, Guid userId, int take, CancellationToken cancellationToken = default);
    Task AddPairAsync(NewChatMessage userMessage, NewChatMessage assistantMessage, CancellationToken cancellationToken = default);
}
