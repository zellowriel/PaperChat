namespace PaperChat.Repositories.Interfaces;

/// <summary>Abstraction nội bộ của tầng persistence; Service không tham chiếu interface này.</summary>
public interface IRepository<TEntity> where TEntity : class
{
    IQueryable<TEntity> Query { get; }
    Task AddAsync(TEntity entity, CancellationToken cancellationToken = default);
    Task AddRangeAsync(IEnumerable<TEntity> entities, CancellationToken cancellationToken = default);
    void Remove(TEntity entity);
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
