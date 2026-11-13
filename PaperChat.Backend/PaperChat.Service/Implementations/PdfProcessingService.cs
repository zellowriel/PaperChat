using System.Text;
using Microsoft.Extensions.Logging;
using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Documents;
using PaperChat.Service.Interfaces;
using UglyToad.PdfPig;
using UglyToad.PdfPig.DocumentLayoutAnalysis.TextExtractor;

namespace PaperChat.Service.Implementations;

public sealed class PdfProcessingService(
    ILogger<PdfProcessingService> logger
) : IPdfProcessingService
{
    // Đọc PDF trực tiếp từ đường dẫn.
    public async Task<PdfProcessingResult> ProcessAsync(
        string filePath,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(filePath))
            throw new ValidationAppException("Đường dẫn PDF không hợp lệ.");

        if (!File.Exists(filePath))
            throw new FileNotFoundException("Không tìm thấy file PDF.", filePath);

        await using var stream = new FileStream(
            filePath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            bufferSize: 81920,
            useAsync: true
        );

        return await ProcessAsync(stream, cancellationToken);
    }

    // Đọc PDF từ Stream.
    public async Task<PdfProcessingResult> ProcessAsync(
        Stream pdfStream,
        CancellationToken cancellationToken = default)
    {
        if (pdfStream is null || !pdfStream.CanRead)
            throw new ValidationAppException("Stream PDF không hợp lệ.");

        long? originalPosition = pdfStream.CanSeek
            ? pdfStream.Position
            : null;

        try
        {
            // PdfPig yêu cầu đọc từ đầu file nếu Stream hỗ trợ Seek.
            if (pdfStream.CanSeek)
                pdfStream.Position = 0;

            // PdfPig thực hiện parsing đồng bộ nên đưa phần CPU-bound
            // ra ThreadPool để không chiếm trực tiếp request thread.
            return await Task.Run(
                () => ExtractText(pdfStream, cancellationToken),
                cancellationToken
            );
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            logger.LogWarning(
                exception,
                "PDF processing failed."
            );

            throw new ValidationAppException(
                "Không thể đọc PDF. File có thể bị lỗi hoặc được mã hóa bằng mật khẩu."
            );
        }
        finally
        {
            if (originalPosition.HasValue && pdfStream.CanSeek)
                pdfStream.Position = originalPosition.Value;
        }
    }

    private static PdfProcessingResult ExtractText(
        Stream pdfStream,
        CancellationToken cancellationToken)
    {
        using var pdfDocument = PdfDocument.Open(pdfStream);

        var pageCount = pdfDocument.NumberOfPages;

        if (pageCount <= 0)
            throw new InvalidDataException("PDF không có trang nào.");

        var textBuilder = new StringBuilder();

        var pageNumber = 0;

        foreach (var page in pdfDocument.GetPages())
        {
            cancellationToken.ThrowIfCancellationRequested();

            pageNumber++;

            // Extract text theo content order của từng trang.
            var pageText = ContentOrderTextExtractor.GetText(page);

            // Trang không có text có thể là trang scan.
            // Không thêm marker nếu trang không có nội dung trích xuất.
            if (string.IsNullOrWhiteSpace(pageText))
                continue;

            textBuilder.AppendLine($"[PAGE {pageNumber}]");
            textBuilder.AppendLine(pageText.Trim());
            textBuilder.AppendLine();
        }

        return new PdfProcessingResult(
            pageCount,
            textBuilder.ToString().Trim()
        );
    }
}