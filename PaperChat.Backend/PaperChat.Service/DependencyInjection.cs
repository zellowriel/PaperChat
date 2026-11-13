using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using PaperChat.Service.Implementations;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Service;

public static class DependencyInjection
{
    public static IServiceCollection AddPaperChatServices(
        this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();

        services.AddScoped<IDocumentService, DocumentService>();

        // PDF processing.
        services.AddScoped<IPdfProcessingService, PdfProcessingService>();

        // Chat.
        services.AddScoped<IChatService, ChatService>();

        services.AddScoped<IPasswordHasher<UserAccount>,
            PasswordHasher<UserAccount>>();

        return services;
    }
}