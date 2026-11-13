using PaperChat.Service.Common;
using PaperChat.Service.DTOs.Users;
using PaperChat.Service.Interfaces;

namespace PaperChat.Service.Implementations;

public sealed class UserService(ICurrentUserService currentUser, IUserRepository users) : IUserService
{
    public async Task<UserProfileResponse> GetMeAsync(CancellationToken cancellationToken = default)
    {
        var user = await users.GetByIdAsync(currentUser.UserId, cancellationToken)
            ?? throw new NotFoundException("Không tìm thấy tài khoản.");
        return ServiceMappings.ToProfile(user);
    }
}
