using System.Text;
using Microsoft.Extensions.Options;
using PaperChat.Repositories.Commons;
using PaperChat.Service.Interfaces;

namespace PaperChat.Repositories.Implementations;

public sealed class LocalFileStorage : IFileStorage
{
    private readonly string _rootPath;

    public LocalFileStorage(IOptions<StorageOptions> options)
    {
        _rootPath = Path.GetFullPath(options.Value.RootPath);

        Directory.CreateDirectory(_rootPath);
    }

    public async Task<string> SavePdfAsync(
        Guid userId,
        Stream content,
        CancellationToken cancellationToken = default)
    {
        var userFolder = Path.Combine(
            "documents",
            userId.ToString("N")
        );

        var absoluteFolder = GetAbsolutePath(userFolder);

        Directory.CreateDirectory(absoluteFolder);

        var storageKey = Path.Combine(
            userFolder,
            $"{Guid.NewGuid():N}.pdf"
        ).Replace('\\', '/');

        var absolutePath = GetAbsolutePath(storageKey);

        try
        {
            await using var output = new FileStream(
                absolutePath,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None,
                81920,
                useAsync: true
            );

            await content.CopyToAsync(
                output,
                cancellationToken
            );

            await output.FlushAsync(cancellationToken);

            return storageKey;
        }
        catch
        {
            if (File.Exists(absolutePath))
                File.Delete(absolutePath);

            throw;
        }
    }

    // Lưu file text có tên bắt đầu bằng dấu chấm.
    public async Task SaveExtractedTextAsync(
        string pdfStorageKey,
        string text,
        CancellationToken cancellationToken = default)
    {
        var textPath = GetExtractedTextAbsolutePath(pdfStorageKey);

        var directory = Path.GetDirectoryName(textPath)!;

        Directory.CreateDirectory(directory);

        await File.WriteAllTextAsync(
            textPath,
            text,
            new UTF8Encoding(false),
            cancellationToken
        );

        // Windows không tự động ẩn file chỉ vì tên bắt đầu bằng dấu chấm.
        if (OperatingSystem.IsWindows())
        {
            var attributes = File.GetAttributes(textPath);

            File.SetAttributes(
                textPath,
                attributes | FileAttributes.Hidden
            );
        }
    }

    // Đọc file text đã lưu.
    public Task<Stream> OpenExtractedTextAsync(
        string pdfStorageKey,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var textPath = GetExtractedTextAbsolutePath(pdfStorageKey);

        Stream stream = new FileStream(
            textPath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            81920,
            useAsync: true
        );

        return Task.FromResult(stream);
    }

    public Task<Stream> OpenReadAsync(
        string storageKey,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        Stream stream = new FileStream(
            GetAbsolutePath(storageKey),
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            81920,
            useAsync: true
        );

        return Task.FromResult(stream);
    }

    // Xóa cả PDF và file text liên quan.
    public Task DeleteAsync(
        string storageKey,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var pdfPath = GetAbsolutePath(storageKey);

        var textPath = GetExtractedTextAbsolutePath(storageKey);

        if (File.Exists(pdfPath))
            File.Delete(pdfPath);

        if (File.Exists(textPath))
            File.Delete(textPath);

        return Task.CompletedTask;
    }

    // Tạo đường dẫn file text ẩn từ đường dẫn PDF.
    private string GetExtractedTextAbsolutePath(
        string pdfStorageKey)
    {
        var pdfPath = GetAbsolutePath(pdfStorageKey);

        var directory = Path.GetDirectoryName(pdfPath)!;

        var fileName = Path.GetFileNameWithoutExtension(pdfPath);

        return Path.Combine(
            directory,
            $".{fileName}.txt"
        );
    }

    // Ngăn path traversal ra khỏi Storage Root.
    private string GetAbsolutePath(string relativePath)
    {
        var normalized = relativePath
            .Replace('/', Path.DirectorySeparatorChar)
            .Replace('\\', Path.DirectorySeparatorChar);

        var fullPath = Path.GetFullPath(
            Path.Combine(_rootPath, normalized)
        );

        var rootWithSeparator = _rootPath.EndsWith(
            Path.DirectorySeparatorChar
        )
            ? _rootPath
            : _rootPath + Path.DirectorySeparatorChar;

        if (!fullPath.StartsWith(
                rootWithSeparator,
                StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "Đường dẫn lưu trữ không hợp lệ."
            );
        }

        return fullPath;
    }
}