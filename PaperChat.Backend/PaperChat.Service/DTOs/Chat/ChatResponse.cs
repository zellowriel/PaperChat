namespace PaperChat.Service.DTOs.Chat;

public sealed record ChatResponse(
    Guid DocumentId,
    Guid UserMessageId,
    Guid AssistantMessageId,
    string Answer,
    int? CitationPage,
    DateTimeOffset CreatedAt);

public sealed record ChatMessageResponse(
    Guid Id,
    string SenderRole,
    string Content,
    string? QuoteReference,
    int? CitationPage,
    DateTimeOffset CreatedAt);

public sealed record AiChatResult(string Answer, int? CitationPage);
