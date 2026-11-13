using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PaperChat.Repositories.Commons;
using PaperChat.Repositories.Context;
using PaperChat.Repositories.Entities;
using PaperChat.Repositories.Implementations;
using PaperChat.Repositories.Interfaces;
using PaperChat.Service.Interfaces;

namespace PaperChat.Repositories;

public static class DependencyInjection
{
    public static IServiceCollection AddPaperChatRepositories(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Thiếu ConnectionStrings:DefaultConnection.");

        services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
        services.Configure<StorageOptions>(configuration.GetSection(StorageOptions.SectionName));

        services.AddScoped(typeof(IRepository<>), typeof(EfRepository<>));
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IDocumentRepository, DocumentRepository>();
        services.AddScoped<IChatMessageRepository, ChatMessageRepository>();
        services.AddScoped<IFileStorage, LocalFileStorage>();

        return services;
    }
}
