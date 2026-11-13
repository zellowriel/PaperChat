namespace PaperChat.Service.DTOs.Documents;

public sealed record DocumentFileResult(Stream Content, string FileName, string ContentType);
