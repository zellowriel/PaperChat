using PaperChat.Service.DTOs.Auth;
using PaperChat.Service.DTOs.Documents;
using PaperChat.Service.DTOs.Users;
using PaperChat.Service.Models;

namespace PaperChat.Service.Implementations;

internal static class ServiceMappings
{
    public const long StorageLimitBytes = 10L * 1024 * 1024 * 1024;

    public static UserProfileResponse ToProfile(UserAccount user) => new(
        user.Id, user.Email, user.FullName, user.StorageUsedBytes,
        StorageLimitBytes, user.PlanType, user.CreatedAt);

    public static DocumentResponse ToDocument(DocumentRecord document) => new(
        document.Id, document.Title, document.Authors, document.SizeBytes,
        document.PageCount, document.ReadingProgress, document.IsProcessed,
        document.CreatedAt, $"/api/v1/documents/{document.Id}/file");
}
