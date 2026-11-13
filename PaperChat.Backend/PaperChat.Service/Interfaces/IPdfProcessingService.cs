using PaperChat.Service.DTOs.Documents;

namespace PaperChat.Service.Interfaces;

public interface IPdfProcessingService
{
    Task<PdfProcessingResult> ProcessAsync(
        Stream pdfStream,
        CancellationToken cancellationToken = default
    );

    Task<PdfProcessingResult> ProcessAsync(
        string filePath,
        CancellationToken cancellationToken = default
    );
}