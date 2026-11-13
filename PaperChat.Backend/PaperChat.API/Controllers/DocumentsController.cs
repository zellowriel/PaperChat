using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaperChat.API.Controllers.Requests;
using PaperChat.Service.DTOs.Common;
using PaperChat.Service.DTOs.Documents;
using PaperChat.Service.Interfaces;

namespace PaperChat.API.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/documents")]
[Produces("application/json")]
public sealed class DocumentsController(IDocumentService documentService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(PagedResponse<DocumentResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResponse<DocumentResponse>>> GetList(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
        => Ok(await documentService.GetListAsync(page, pageSize, cancellationToken));

    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(51L * 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = 51L * 1024 * 1024)]
    [ProducesResponseType(typeof(DocumentResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status413PayloadTooLarge)]
    public async Task<IActionResult> Upload([FromForm] UploadDocumentForm form, CancellationToken cancellationToken)
    {
        if (form.File is null) return BadRequest(new ProblemDetails { Title = "Validation error", Detail = "Bạn phải chọn file PDF." });
        await using var stream = form.File.OpenReadStream();
        var result = await documentService.UploadAsync(
            new UploadDocumentCommand(stream, form.File.Length, form.File.FileName, form.Title, form.Authors), cancellationToken);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(DocumentResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<DocumentResponse>> GetById(Guid id, CancellationToken cancellationToken)
        => Ok(await documentService.GetByIdAsync(id, cancellationToken));

    [HttpGet("{id:guid}/file")]
    [Produces("application/pdf")]
    public async Task<IActionResult> Download(Guid id, CancellationToken cancellationToken)
    {
        var file = await documentService.OpenFileAsync(id, cancellationToken);
        return File(file.Content, file.ContentType, file.FileName, enableRangeProcessing: true);
    }

    [HttpPatch("{id:guid}/progress")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateProgress(Guid id, [FromBody] UpdateReadingProgressRequest request, CancellationToken cancellationToken)
    {
        await documentService.UpdateReadingProgressAsync(id, request.ReadingProgress, cancellationToken);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await documentService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
