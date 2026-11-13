namespace PaperChat.Service.Models;

public sealed record DocumentRecord(
    Guid Id,
    Guid UserId,
    string Title,
    string? Authors,
    string FileKey,
    long SizeBytes,
    int PageCount,
    int ReadingProgress,
    bool IsProcessed,
    DateTimeOffset CreatedAt
);

public sealed record NewDocumentRecord(
    Guid UserId,
    string Title,
    string? Authors,
    string FileKey,
    long SizeBytes,
    int PageCount,
    bool IsProcessed
);