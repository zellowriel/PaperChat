using PaperChat.Service.DTOs.Users;

namespace PaperChat.Service.DTOs.Auth;

public sealed record AuthResponse(
    string AccessToken,
    string TokenType,
    DateTimeOffset ExpiresAtUtc,
    UserProfileResponse User);

public sealed record GeneratedAccessToken(string Value, DateTimeOffset ExpiresAtUtc);
