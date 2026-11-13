using Microsoft.EntityFrameworkCore;
using PaperChat.Repositories.Entities;
using PaperChat.Repositories.Interfaces;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Repositories.Implementations;

public sealed class ChatMessageRepository(IRepository<ChatMessage> messages) : IChatMessageRepository
{
    public async Task<IReadOnlyList<ChatMessageRecord>> GetHistoryAsync(
        Guid documentId, Guid userId, int take, CancellationToken cancellationToken = default)
    {
        var rows = await messages.Query.AsNoTracking()
            .Where(x => x.DocumentId == documentId && x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ThenByDescending(x => x.Id)
            .Take(take)
            .ToListAsync(cancellationToken);
        return rows.OrderBy(x => x.CreatedAt).ThenBy(x => x.Id)
            .Select(x => new ChatMessageRecord(x.Id, x.DocumentId, x.UserId, x.SenderRole,
                x.Content, x.QuoteReference, x.CitationPage, x.CreatedAt)).ToList();
    }

    public async Task AddPairAsync(NewChatMessage userMessage, NewChatMessage assistantMessage, CancellationToken cancellationToken = default)
    {
        await messages.AddRangeAsync([ToEntity(userMessage), ToEntity(assistantMessage)], cancellationToken);
        await messages.SaveChangesAsync(cancellationToken);
    }

    private static ChatMessage ToEntity(NewChatMessage x) => new()
    {
        Id = x.Id,
        DocumentId = x.DocumentId,
        UserId = x.UserId,
        SenderRole = x.SenderRole,
        Content = x.Content,
        QuoteReference = x.QuoteReference,
        CitationPage = x.CitationPage,
        CreatedAt = x.CreatedAt
    };
}
