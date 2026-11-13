using PaperChat.Service.DTOs.Auth;

namespace PaperChat.Service.Interfaces;

public interface ITokenService
{
    GeneratedAccessToken CreateAccessToken(Guid userId, string email);
}
