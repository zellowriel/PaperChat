using Microsoft.EntityFrameworkCore;
using PaperChat.Repositories.Context;
using PaperChat.Repositories.Entities;
using PaperChat.Service.Common;

namespace PaperChat.API.Extensions;

public sealed class FirebaseUserProvisioner(AppDbContext dbContext)
{
    public async Task<Guid> GetOrCreateAsync(
        string firebaseUid,
        string email,
        string? fullName,
        bool emailVerified,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await dbContext.Users
            .SingleOrDefaultAsync(x => x.FirebaseUid == firebaseUid, cancellationToken);

        if (user is null)
        {
            user = await dbContext.Users
                .SingleOrDefaultAsync(x => x.Email == normalizedEmail, cancellationToken);
            if (user?.FirebaseUid is not null && user.FirebaseUid != firebaseUid)
                throw new UnauthorizedAppException("Email đã được liên kết với một tài khoản Firebase khác.");

            if (user is null)
            {
                user = new User
                {
                    Email = normalizedEmail,
                    FirebaseUid = firebaseUid,
                    FullName = fullName,
                    PasswordHash = string.Empty,
                    PlanType = "FREE",
                    StorageUsedBytes = 0
                };
                await dbContext.Users.AddAsync(user, cancellationToken);
            }
            else
            {
                if (!emailVerified)
                    throw new UnauthorizedAppException(
                        "Hãy xác minh email trước khi liên kết tài khoản PaperChat hiện có.");
                user.FirebaseUid = firebaseUid;
                user.FullName ??= fullName;
            }
        }
        else
        {
            if (emailVerified) user.Email = normalizedEmail;
            user.FullName ??= fullName;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return user.Id;
    }
}
