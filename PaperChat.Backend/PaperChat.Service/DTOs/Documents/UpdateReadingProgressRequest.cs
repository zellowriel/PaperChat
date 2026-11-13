using System.ComponentModel.DataAnnotations;

namespace PaperChat.Service.DTOs.Documents;

public sealed class UpdateReadingProgressRequest
{
    [Range(0, 100)]
    public int ReadingProgress { get; init; }
}
