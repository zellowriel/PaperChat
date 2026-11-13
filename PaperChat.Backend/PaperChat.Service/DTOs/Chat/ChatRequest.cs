using System.ComponentModel.DataAnnotations;

namespace PaperChat.Service.DTOs.Chat;

public sealed class ChatRequest
{
    [Required]
    public Guid DocumentId { get; init; }

    [Required, MinLength(1), MaxLength(5000)]
    public string Question { get; init; } = string.Empty;

    [MaxLength(10000)]
    public string? Quote { get; init; }

    [MaxLength(20)]
    public List<ChatHistoryItemDto> ChatHistory { get; init; } = [];
}

public sealed class ChatHistoryItemDto
{
    [Required, MaxLength(10)]
    public string Role { get; init; } = string.Empty;

    [Required, MinLength(1), MaxLength(4000)]
    public string Content { get; init; } = string.Empty;
}
