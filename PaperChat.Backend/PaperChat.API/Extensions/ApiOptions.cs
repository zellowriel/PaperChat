namespace PaperChat.API.Extensions;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";
    public string Issuer { get; set; } = "PaperChat.API";
    public string Audience { get; set; } = "PaperChat.Client";
    public string Key { get; set; } = string.Empty;
    public int ExpirationMinutes { get; set; } = 60;
}
