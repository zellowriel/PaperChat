namespace PaperChat.Repositories.Entities;

public sealed class Document
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Authors { get; set; }
    public string FileUrl { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public int PageCount { get; set; }
    public int ReadingProgress { get; set; }
    public bool IsProcessed { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<ChatMessage> ChatMessages { get; set; } = new List<ChatMessage>();
}
