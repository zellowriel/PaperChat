namespace PaperChat.Service.Models;

public sealed record ChatMessageRecord(
    Guid Id,
    Guid DocumentId,
    Guid UserId,
    string SenderRole,
    string Content,
    string? QuoteReference,
    int? CitationPage,
    DateTimeOffset CreatedAt);

public sealed record NewChatMessage(
    Guid Id,
    Guid DocumentId,
    Guid UserId,
    string SenderRole,
    string Content,
    string? QuoteReference,
    int? CitationPage,
    DateTimeOffset CreatedAt);
