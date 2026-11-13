namespace PaperChat.Service.DTOs.Users;

public sealed record UserProfileResponse(
    Guid Id,
    string Email,
    string? FullName,
    long StorageUsedBytes,
    long StorageLimitBytes,
    string PlanType,
    DateTimeOffset CreatedAt);
