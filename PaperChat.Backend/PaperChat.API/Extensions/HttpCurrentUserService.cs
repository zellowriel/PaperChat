using System.Security.Claims;
using PaperChat.Service.Common;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.Extensions;

public sealed class HttpCurrentUserService(IHttpContextAccessor httpContextAccessor) : ICurrentUserService
{
    public Guid UserId
    {
        get
        {
            var value = httpContextAccessor.HttpContext?.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(value, out var userId))
                throw new UnauthorizedAppException("Không xác định được người dùng hiện tại.");
            return userId;
        }
    }
}
