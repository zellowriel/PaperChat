using PaperChat.Service.DTOs.Users;

namespace PaperChat.Service.Interfaces;

public interface IUserService
{
    Task<UserProfileResponse> GetMeAsync(CancellationToken cancellationToken = default);
}
