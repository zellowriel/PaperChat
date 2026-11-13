using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using PaperChat.Service.DTOs.Auth;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.Extensions;

public sealed class JwtTokenService(IOptions<JwtOptions> options) : ITokenService
{
    public GeneratedAccessToken CreateAccessToken(Guid userId, string email)
    {
        var settings = options.Value;
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(settings.ExpirationMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new(ClaimTypes.Email, email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.Key));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var jwt = new JwtSecurityToken(settings.Issuer, settings.Audience, claims,
            notBefore: now, expires: expires, signingCredentials: credentials);

        return new GeneratedAccessToken(new JwtSecurityTokenHandler().WriteToken(jwt), new DateTimeOffset(expires, TimeSpan.Zero));
    }
}
