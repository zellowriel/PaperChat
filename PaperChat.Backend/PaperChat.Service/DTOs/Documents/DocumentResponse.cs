namespace PaperChat.Service.DTOs.Documents;

public sealed record DocumentResponse(
    Guid Id,
    string Title,
    string? Authors,
    long SizeBytes,
    int PageCount,
    int ReadingProgress,
    bool IsProcessed,
    DateTimeOffset CreatedAt,
    string DownloadUrl);
