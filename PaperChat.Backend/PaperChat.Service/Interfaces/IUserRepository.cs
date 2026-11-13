using PaperChat.Service.Models;

namespace PaperChat.Service.Interfaces;

public interface IUserRepository
{
    Task<UserAccount?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken = default);
    Task<UserAccount?> GetByIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task AddAsync(NewUserAccount user, CancellationToken cancellationToken = default);
    Task UpdatePasswordHashAsync(Guid userId, string passwordHash, CancellationToken cancellationToken = default);
    Task<bool> TryIncreaseStorageAsync(Guid userId, long bytes, long limitBytes, CancellationToken cancellationToken = default);
    Task DecreaseStorageAsync(Guid userId, long bytes, CancellationToken cancellationToken = default);
}
