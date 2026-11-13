using PaperChat.Service.Models;

namespace PaperChat.Service.Interfaces;

public interface IDocumentRepository
{
    Task<(IReadOnlyList<DocumentRecord> Items, int TotalCount)> GetPageByUserAsync(Guid userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<DocumentRecord?> GetByIdForUserAsync(Guid documentId, Guid userId, CancellationToken cancellationToken = default);
    Task<DocumentRecord> AddAsync(NewDocumentRecord document, CancellationToken cancellationToken = default);
    Task<bool> UpdateReadingProgressAsync(Guid documentId, Guid userId, int progress, CancellationToken cancellationToken = default);
    Task<DocumentRecord?> DeleteAndReleaseStorageAsync(Guid documentId, Guid userId, CancellationToken cancellationToken = default);
}
