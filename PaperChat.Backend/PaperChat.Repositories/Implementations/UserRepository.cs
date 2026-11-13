using Microsoft.EntityFrameworkCore;
using Npgsql;
using PaperChat.Repositories.Context;
using PaperChat.Repositories.Entities;
using PaperChat.Repositories.Interfaces;
using PaperChat.Service.Common;
using PaperChat.Service.Interfaces;
using PaperChat.Service.Models;

namespace PaperChat.Repositories.Implementations;

public sealed class UserRepository(IRepository<User> users, AppDbContext dbContext) : IUserRepository
{
    public Task<UserAccount?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken = default)
        => users.Query.AsNoTracking()
            .Where(x => x.Email == normalizedEmail)
            .Select(x => new UserAccount(x.Id, x.Email, x.PasswordHash, x.FullName, x.StorageUsedBytes, x.PlanType, x.CreatedAt))
            .FirstOrDefaultAsync(cancellationToken);

    public Task<UserAccount?> GetByIdAsync(Guid userId, CancellationToken cancellationToken = default)
        => users.Query.AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => new UserAccount(x.Id, x.Email, x.PasswordHash, x.FullName, x.StorageUsedBytes, x.PlanType, x.CreatedAt))
            .FirstOrDefaultAsync(cancellationToken);

    public async Task AddAsync(NewUserAccount account, CancellationToken cancellationToken = default)
    {
        var entity = new User
        {
            Email = account.Email,
            PasswordHash = account.PasswordHash,
            FullName = account.FullName,
            PlanType = "FREE",
            StorageUsedBytes = 0
        };
        await users.AddAsync(entity, cancellationToken);
        try
        {
            await users.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (ex.GetBaseException() is PostgresException pg && pg.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            throw new ConflictException("Email này đã được đăng ký.");
        }
    }

    public async Task UpdatePasswordHashAsync(Guid userId, string passwordHash, CancellationToken cancellationToken = default)
    {
        await dbContext.Users.Where(x => x.Id == userId)
            .ExecuteUpdateAsync(setters => setters.SetProperty(x => x.PasswordHash, passwordHash), cancellationToken);
    }

    public async Task<bool> TryIncreaseStorageAsync(Guid userId, long bytes, long limitBytes, CancellationToken cancellationToken = default)
    {
        if (bytes <= 0 || bytes > limitBytes) return false;

        var affected = await dbContext.Users
            .Where(x => x.Id == userId && x.StorageUsedBytes <= limitBytes - bytes)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(x => x.StorageUsedBytes, x => x.StorageUsedBytes + bytes), cancellationToken);
        return affected == 1;
    }

    public async Task DecreaseStorageAsync(Guid userId, long bytes, CancellationToken cancellationToken = default)
    {
        if (bytes <= 0) return;

        await dbContext.Users
            .Where(x => x.Id == userId)
            .ExecuteUpdateAsync(setters => setters.SetProperty(
                x => x.StorageUsedBytes,
                x => x.StorageUsedBytes >= bytes ? x.StorageUsedBytes - bytes : 0L), cancellationToken);
    }
}
