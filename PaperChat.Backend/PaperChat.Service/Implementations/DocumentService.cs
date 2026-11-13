using System.ComponentModel.DataAnnotations;
using System.Text;
using Microsoft.Extensions.Logging;
using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Common;
using PaperChat.Service.DTOs.Documents;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Service.Implementations;

public sealed class DocumentService(
    ICurrentUserService currentUser,
    IUserRepository users,
    IDocumentRepository documents,
    IFileStorage fileStorage,
    IPdfProcessingService pdfProcessing,
    ILogger<DocumentService> logger
) : IDocumentService
{
    private const long MaxPdfSizeBytes = 50L * 1024 * 1024;
    private const int MaxPageSize = 100;

    public async Task<PagedResponse<DocumentResponse>> GetListAsync(int page, int pageSize, CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, MaxPageSize);
        var result = await documents.GetPageByUserAsync(currentUser.UserId, page, pageSize, cancellationToken);
        return new PagedResponse<DocumentResponse>(result.Items.Select(ServiceMappings.ToDocument).ToList(), page, pageSize, result.TotalCount);
    }

    public async Task<DocumentResponse> UploadAsync(
    UploadDocumentCommand command,
    CancellationToken cancellationToken = default)
    {
        // ==========================================
        // 1. VALIDATE FILE
        // ==========================================

        if (command.Length <= 0)
            throw new ValidationAppException(
                "File PDF không được để trống."
            );

        if (command.Length > MaxPdfSizeBytes)
            throw new PayloadTooLargeException(
                "Kích thước file PDF tối đa là 50 MB."
            );

        if (command.Content is null ||
            !command.Content.CanRead ||
            !command.Content.CanSeek)
        {
            throw new ValidationAppException(
                "Không thể đọc nội dung file được tải lên."
            );
        }

        // Kiểm tra chữ ký PDF.
        var originalPosition = command.Content.Position;

        var header = new byte[5];

        var totalRead = 0;

        while (totalRead < header.Length)
        {
            var read = await command.Content.ReadAsync(
                header.AsMemory(
                    totalRead,
                    header.Length - totalRead
                ),
                cancellationToken
            );

            if (read == 0)
                break;

            totalRead += read;
        }

        command.Content.Position = originalPosition;

        if (totalRead != 5 ||
            Encoding.ASCII.GetString(header) != "%PDF-")
        {
            throw new ValidationAppException(
                "File tải lên không có định dạng PDF hợp lệ."
            );
        }

        // ==========================================
        // 2. VALIDATE METADATA
        // ==========================================

        var safeUploadName = Path.GetFileName(
            command.FileName.Replace('\\', '/')
        );

        var title = string.IsNullOrWhiteSpace(command.Title)
            ? Path.GetFileNameWithoutExtension(safeUploadName).Trim()
            : command.Title.Trim();

        if (string.IsNullOrWhiteSpace(title))
            title = "Untitled document";

        if (title.Length > 255)
            title = title[..255];

        var authors = string.IsNullOrWhiteSpace(command.Authors)
            ? null
            : command.Authors.Trim();

        if (authors?.Length > 255)
            throw new ValidationAppException(
                "Authors không được vượt quá 255 ký tự."
            );

        // ==========================================
        // 3. CHECK USER + STORAGE QUOTA
        // ==========================================

        var userId = currentUser.UserId;

        if (await users.GetByIdAsync(
                userId,
                cancellationToken) is null)
        {
            throw new NotFoundException(
                "Không tìm thấy tài khoản."
            );
        }

        if (!await users.TryIncreaseStorageAsync(
                userId,
                command.Length,
                ServiceMappings.StorageLimitBytes,
                cancellationToken))
        {
            throw new PayloadTooLargeException(
                "Dung lượng lưu trữ tối đa của tài khoản là 10 GB."
            );
        }

        string? storageKey = null;

        try
        {
            // ==========================================
            // 4. SAVE PDF PHYSICAL FILE
            // ==========================================

            command.Content.Position = originalPosition;

            storageKey = await fileStorage.SavePdfAsync(
                userId,
                command.Content,
                cancellationToken
            );

            // ==========================================
            // 5. EXTRACT PDF TEXT + PAGE COUNT
            // ==========================================

            PdfProcessingResult pdfResult;

            await using (var pdfStream =
                await fileStorage.OpenReadAsync(
                    storageKey,
                    cancellationToken))
            {
                pdfResult = await pdfProcessing.ProcessAsync(
                    pdfStream,
                    cancellationToken
                );
            }

            // Kiểm tra PDF có trang hay không.
            if (pdfResult.PageCount <= 0)
            {
                throw new ValidationAppException(
                    "Không thể xác định số trang của PDF."
                );
            }

            // PDF scan không có text sẽ cần OCR.
            // Không đánh dấu IsProcessed = true trong trường hợp này.
            if (string.IsNullOrWhiteSpace(pdfResult.Text))
            {
                throw new ValidationAppException(
                    "Không tìm thấy văn bản trong PDF. " +
                    "Tài liệu có thể là PDF scan và cần xử lý OCR."
                );
            }

            // ==========================================
            // 6. SAVE EXTRACTED TEXT
            // ==========================================

            await fileStorage.SaveExtractedTextAsync(
                storageKey,
                pdfResult.Text,
                cancellationToken
            );

            // ==========================================
            // 7. SAVE DOCUMENT METADATA TO DATABASE
            // ==========================================

            var document = await documents.AddAsync(
                new NewDocumentRecord(
                    UserId: userId,
                    Title: title,
                    Authors: authors,
                    FileKey: storageKey,
                    SizeBytes: command.Length,
                    PageCount: pdfResult.PageCount,
                    IsProcessed: true
                ),
                cancellationToken
            );

            // Trả thông tin document cho Flutter.
            return ServiceMappings.ToDocument(document);
        }
        catch
        {
            // ==========================================
            // 8. ROLLBACK IF ANY STEP FAILS
            // ==========================================

            // DeleteAsync đã được sửa để xóa cả PDF và TXT.
            if (storageKey is not null)
            {
                try
                {
                    await fileStorage.DeleteAsync(
                        storageKey,
                        CancellationToken.None
                    );
                }
                catch (Exception cleanupException)
                {
                    logger.LogError(
                        cleanupException,
                        "Không thể dọn file sau khi upload thất bại: {StorageKey}",
                        storageKey
                    );
                }
            }

            // Hoàn lại dung lượng đã chiếm của user.
            try
            {
                await users.DecreaseStorageAsync(
                    userId,
                    command.Length,
                    CancellationToken.None
                );
            }
            catch (Exception cleanupException)
            {
                logger.LogError(
                    cleanupException,
                    "Không thể hoàn tác dung lượng cho user {UserId}",
                    userId
                );
            }

            throw;
        }
    }

    public async Task<DocumentResponse> GetByIdAsync(Guid documentId, CancellationToken cancellationToken = default)
    {
        var document = await documents.GetByIdForUserAsync(documentId, currentUser.UserId, cancellationToken)
            ?? throw new NotFoundException("Không tìm thấy tài liệu.");
        return ServiceMappings.ToDocument(document);
    }

    public async Task DeleteAsync(Guid documentId, CancellationToken cancellationToken = default)
    {
        var deleted = await documents.DeleteAndReleaseStorageAsync(documentId, currentUser.UserId, cancellationToken)
            ?? throw new NotFoundException("Không tìm thấy tài liệu.");

        try
        {
            await fileStorage.DeleteAsync(deleted.FileKey, cancellationToken);
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Không thể xóa file vật lý {StorageKey} của document {DocumentId}", deleted.FileKey, deleted.Id);
        }
    }

    public async Task UpdateReadingProgressAsync(Guid documentId, int progress, CancellationToken cancellationToken = default)
    {
        if (progress is < 0 or > 100)
            throw new ValidationException("ReadingProgress phải nằm trong khoảng 0 đến 100.");

        var updated = await documents.UpdateReadingProgressAsync(documentId, currentUser.UserId, progress, cancellationToken);
        if (!updated) throw new NotFoundException("Không tìm thấy tài liệu.");
    }

    public async Task<DocumentFileResult> OpenFileAsync(Guid documentId, CancellationToken cancellationToken = default)
    {
        var document = await documents.GetByIdForUserAsync(documentId, currentUser.UserId, cancellationToken)
            ?? throw new NotFoundException("Không tìm thấy tài liệu.");

        try
        {
            var stream = await fileStorage.OpenReadAsync(document.FileKey, cancellationToken);
            var safeFileName = $"{document.Id:N}.pdf";
            return new DocumentFileResult(stream, safeFileName, "application/pdf");
        }
        catch (FileNotFoundException)
        {
            throw new NotFoundException("File PDF không còn tồn tại trong storage.");
        }
        catch (DirectoryNotFoundException)
        {
            throw new NotFoundException("File PDF không còn tồn tại trong storage.");
        }
    }
}
