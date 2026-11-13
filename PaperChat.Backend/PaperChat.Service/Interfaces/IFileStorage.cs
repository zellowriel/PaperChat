namespace PaperChat.Service.Interfaces;

public interface IFileStorage
{
    Task<string> SavePdfAsync(
        Guid userId,
        Stream content,
        CancellationToken cancellationToken = default
    );

    Task DeleteAsync(
        string storageKey,
        CancellationToken cancellationToken = default
    );

    Task<Stream> OpenReadAsync(
        string storageKey,
        CancellationToken cancellationToken = default
    );

    // Lưu text trích xuất vào file .txt ẩn bên cạnh PDF.
    Task SaveExtractedTextAsync(
        string pdfStorageKey,
        string text,
        CancellationToken cancellationToken = default
    );

    // Đọc text đã trích xuất từ file .txt.
    Task<Stream> OpenExtractedTextAsync(
        string pdfStorageKey,
        CancellationToken cancellationToken = default
    );
}