using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaperChat.Service.DTOs.Users;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/users")]
[Produces("application/json")]
public sealed class UsersController(IUserService userService) : ControllerBase
{
    [HttpGet("me")]
    [ProducesResponseType(typeof(UserProfileResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<UserProfileResponse>> GetMe(CancellationToken cancellationToken)
        => Ok(await userService.GetMeAsync(cancellationToken));
}
