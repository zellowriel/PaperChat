using PaperChat.Service.DTOs.Chat;

namespace PaperChat.Service.Interfaces;

public interface IChatService
{
    Task<ChatResponse> SendAsync(ChatRequest request, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ChatMessageResponse>> GetHistoryAsync(Guid documentId, CancellationToken cancellationToken = default);
}
