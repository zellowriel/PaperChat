namespace PaperChat.Repositories.Entities;

public sealed class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public long StorageUsedBytes { get; set; }
    public string PlanType { get; set; } = "FREE";
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<Document> Documents { get; set; } = new List<Document>();
    public ICollection<ChatMessage> ChatMessages { get; set; } = new List<ChatMessage>();
}
