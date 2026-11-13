namespace PaperChat.Service.Models;

public sealed record UserAccount(
    Guid Id,
    string Email,
    string PasswordHash,
    string? FullName,
    long StorageUsedBytes,
    string PlanType,
    DateTimeOffset CreatedAt);

public sealed record NewUserAccount(string Email, string PasswordHash, string? FullName);
