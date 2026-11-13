using Microsoft.EntityFrameworkCore;
using PaperChat.Repositories.Context;
using PaperChat.Repositories.Interfaces;

namespace PaperChat.Repositories.Implementations;

public sealed class EfRepository<TEntity>(AppDbContext dbContext) : IRepository<TEntity>
    where TEntity : class
{
    public IQueryable<TEntity> Query => dbContext.Set<TEntity>();

    public async Task AddAsync(TEntity entity, CancellationToken cancellationToken = default)
        => await dbContext.Set<TEntity>().AddAsync(entity, cancellationToken);

    public async Task AddRangeAsync(IEnumerable<TEntity> entities, CancellationToken cancellationToken = default)
        => await dbContext.Set<TEntity>().AddRangeAsync(entities, cancellationToken);

    public void Remove(TEntity entity) => dbContext.Set<TEntity>().Remove(entity);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => dbContext.SaveChangesAsync(cancellationToken);
}
