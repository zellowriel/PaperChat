namespace PaperChat.Service.DTOs.Documents;

public sealed record PdfProcessingResult(
    int PageCount,
    string Text
);