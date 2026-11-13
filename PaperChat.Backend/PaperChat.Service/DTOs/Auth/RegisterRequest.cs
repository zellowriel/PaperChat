using System.ComponentModel.DataAnnotations;

namespace PaperChat.Service.DTOs.Auth;

public sealed class RegisterRequest
{
    [Required, EmailAddress, StringLength(255)]
    public string Email { get; init; } = string.Empty;

    [Required, MinLength(8), MaxLength(100)]
    public string Password { get; init; } = string.Empty;

    [MaxLength(100)]
    public string? FullName { get; init; }
}
