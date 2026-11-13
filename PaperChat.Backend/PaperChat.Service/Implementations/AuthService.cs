using Microsoft.AspNetCore.Identity;
using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Auth;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Service.Implementations;

public sealed class AuthService(
    IUserRepository users,
    IPasswordHasher<UserAccount> passwordHasher,
    ITokenService tokenService) : IAuthService
{
    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        var email = NormalizeEmail(request.Email);
        if (await users.GetByEmailAsync(email, cancellationToken) is not null)
            throw new ConflictException("Email này đã được đăng ký.");

        var fullName = string.IsNullOrWhiteSpace(request.FullName) ? null : request.FullName.Trim();
        var hashContext = new UserAccount(Guid.Empty, email, string.Empty, fullName, 0, "FREE", DateTimeOffset.UtcNow);
        var passwordHash = passwordHasher.HashPassword(hashContext, request.Password);
        await users.AddAsync(new NewUserAccount(email, passwordHash, fullName), cancellationToken);

        var created = await users.GetByEmailAsync(email, cancellationToken)
            ?? throw new InvalidOperationException("Không thể đọc lại tài khoản vừa tạo.");
        return CreateResponse(created);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var email = NormalizeEmail(request.Email);
        var user = await users.GetByEmailAsync(email, cancellationToken);
        if (user is null)
            throw new UnauthorizedAppException();

        var verification = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);
        if (verification == PasswordVerificationResult.Failed)
            throw new UnauthorizedAppException();

        if (verification == PasswordVerificationResult.SuccessRehashNeeded)
        {
            var newHash = passwordHasher.HashPassword(user, request.Password);
            await users.UpdatePasswordHashAsync(user.Id, newHash, cancellationToken);
            user = user with { PasswordHash = newHash };
        }

        return CreateResponse(user);
    }

    private AuthResponse CreateResponse(UserAccount user)
    {
        var token = tokenService.CreateAccessToken(user.Id, user.Email);
        return new AuthResponse(token.Value, "Bearer", token.ExpiresAtUtc, ServiceMappings.ToProfile(user));
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
