using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaperChat.Service.DTOs.Chat;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/chat")]
[Produces("application/json")]
public sealed class ChatController(IChatService chatService) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(ChatResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ChatResponse>> Send([FromBody] ChatRequest request, CancellationToken cancellationToken)
        => Ok(await chatService.SendAsync(request, cancellationToken));

    [HttpGet("{documentId:guid}")]
    [ProducesResponseType(typeof(IReadOnlyList<ChatMessageResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ChatMessageResponse>>> GetHistory(Guid documentId, CancellationToken cancellationToken)
        => Ok(await chatService.GetHistoryAsync(documentId, cancellationToken));
}
