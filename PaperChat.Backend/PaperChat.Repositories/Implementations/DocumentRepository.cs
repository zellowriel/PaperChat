using Microsoft.EntityFrameworkCore;
using PaperChat.Repositories.Context;
using PaperChat.Repositories.Entities;
using PaperChat.Repositories.Interfaces;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Repositories.Implementations;

public sealed class DocumentRepository(IRepository<Document> documents, AppDbContext dbContext) : IDocumentRepository
{
    public async Task<(IReadOnlyList<DocumentRecord> Items, int TotalCount)> GetPageByUserAsync(
        Guid userId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var query = documents.Query.AsNoTracking().Where(x => x.UserId == userId);
        var totalCount = await query.CountAsync(cancellationToken);
        var rows = await query
            .OrderByDescending(x => x.CreatedAt)
            .ThenByDescending(x => x.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return (rows.Select(ToRecord).ToList(), totalCount);
    }

    public async Task<DocumentRecord?> GetByIdForUserAsync(Guid documentId, Guid userId, CancellationToken cancellationToken = default)
    {
        var entity = await documents.Query.AsNoTracking().FirstOrDefaultAsync(
            x => x.Id == documentId && x.UserId == userId, cancellationToken);
        return entity is null ? null : ToRecord(entity);
    }

    public async Task<DocumentRecord> AddAsync(
    NewDocumentRecord record,
    CancellationToken cancellationToken = default)
    {
        var entity = new Document
        {
            UserId = record.UserId,
            Title = record.Title,
            Authors = record.Authors,
            FileUrl = record.FileKey,
            SizeBytes = record.SizeBytes,

            // Nhận kết quả từ PdfProcessingService.
            PageCount = record.PageCount,

            ReadingProgress = 0,

            // True khi đã trích xuất và lưu text thành công.
            IsProcessed = record.IsProcessed
        };

        await documents.AddAsync(entity, cancellationToken);

        await documents.SaveChangesAsync(cancellationToken);

        return ToRecord(entity);
    }

    public async Task<bool> UpdateReadingProgressAsync(Guid documentId, Guid userId, int progress, CancellationToken cancellationToken = default)
    {
        var affected = await dbContext.Documents
            .Where(x => x.Id == documentId && x.UserId == userId)
            .ExecuteUpdateAsync(setters => setters.SetProperty(x => x.ReadingProgress, progress), cancellationToken);
        return affected == 1;
    }

    public async Task<DocumentRecord?> DeleteAndReleaseStorageAsync(Guid documentId, Guid userId, CancellationToken cancellationToken = default)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var document = await documents.Query.FirstOrDefaultAsync(
            x => x.Id == documentId && x.UserId == userId, cancellationToken);
        if (document is null) return null;

        var owner = await dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
        if (owner is not null)
            owner.StorageUsedBytes = Math.Max(0L, owner.StorageUsedBytes - document.SizeBytes);

        var result = ToRecord(document);
        documents.Remove(document);
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return result;
    }

    private static DocumentRecord ToRecord(Document x) => new(
        x.Id, x.UserId, x.Title, x.Authors, x.FileUrl, x.SizeBytes,
        x.PageCount, x.ReadingProgress, x.IsProcessed, x.CreatedAt);
}
