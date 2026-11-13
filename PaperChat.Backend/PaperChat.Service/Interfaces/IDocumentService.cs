using PaperChat.Service.DTOs.Common;
using PaperChat.Service.DTOs.Documents;

namespace PaperChat.Service.Interfaces;

public sealed record UploadDocumentCommand(Stream Content, long Length, string FileName, string? Title, string? Authors);

public interface IDocumentService
{
    Task<PagedResponse<DocumentResponse>> GetListAsync(int page, int pageSize, CancellationToken cancellationToken = default);
    Task<DocumentResponse> UploadAsync(UploadDocumentCommand command, CancellationToken cancellationToken = default);
    Task<DocumentResponse> GetByIdAsync(Guid documentId, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid documentId, CancellationToken cancellationToken = default);
    Task UpdateReadingProgressAsync(Guid documentId, int progress, CancellationToken cancellationToken = default);
    Task<DocumentFileResult> OpenFileAsync(Guid documentId, CancellationToken cancellationToken = default);
}
