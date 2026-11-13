namespace PaperChat.Repositories.Entities;

public sealed class ChatMessage
{
    public Guid Id { get; set; }
    public Guid DocumentId { get; set; }
    public Guid UserId { get; set; }
    public string SenderRole { get; set; } = string.Empty; // USER hoặc AI
    public string Content { get; set; } = string.Empty;
    public string? QuoteReference { get; set; }
    public int? CitationPage { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public Document Document { get; set; } = null!;
    public User User { get; set; } = null!;
}
