using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace PaperChat.API.Controllers.Requests;

public sealed class UploadDocumentForm
{
    [Required]
    public IFormFile? File { get; init; }

    [StringLength(255)]
    public string? Title { get; init; }

    [StringLength(255)]
    public string? Authors { get; init; }
}
