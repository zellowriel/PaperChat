using Microsoft.EntityFrameworkCore;
using PaperChat.Repositories.Entities;

namespace PaperChat.Repositories.Context;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Document> Documents => Set<Document>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            entity.Property(x => x.Email).HasColumnName("email").HasMaxLength(255).IsRequired();
            entity.Property(x => x.FirebaseUid).HasColumnName("firebaseuid").HasMaxLength(128);
            entity.Property(x => x.PasswordHash).HasColumnName("passwordhash").HasMaxLength(255).IsRequired();
            entity.Property(x => x.FullName).HasColumnName("fullname").HasMaxLength(100);
            entity.Property(x => x.StorageUsedBytes).HasColumnName("storageusedbytes").HasDefaultValue(0L);
            entity.Property(x => x.PlanType).HasColumnName("plantype").HasMaxLength(50).HasDefaultValue("FREE");
            entity.Property(x => x.CreatedAt).HasColumnName("createdat").HasColumnType("timestamp with time zone").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.HasIndex(x => x.Email).IsUnique().HasDatabaseName("ux_users_email");
            entity.HasIndex(x => x.FirebaseUid).IsUnique()
                .HasFilter("\"firebaseuid\" IS NOT NULL")
                .HasDatabaseName("ux_users_firebaseuid");
        });

        modelBuilder.Entity<Document>(entity =>
        {
            entity.ToTable("documents");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            entity.Property(x => x.UserId).HasColumnName("userid").IsRequired();
            entity.Property(x => x.Title).HasColumnName("title").HasMaxLength(255).IsRequired();
            entity.Property(x => x.Authors).HasColumnName("authors").HasMaxLength(255);
            entity.Property(x => x.FileUrl).HasColumnName("fileurl").HasMaxLength(500).IsRequired();
            entity.Property(x => x.SizeBytes).HasColumnName("sizebytes").IsRequired();
            entity.Property(x => x.PageCount).HasColumnName("pagecount").HasDefaultValue(0);
            entity.Property(x => x.ReadingProgress).HasColumnName("readingprogress").HasDefaultValue(0);
            entity.Property(x => x.IsProcessed).HasColumnName("isprocessed").HasDefaultValue(false);
            entity.Property(x => x.CreatedAt).HasColumnName("createdat").HasColumnType("timestamp with time zone").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.HasIndex(x => x.UserId).HasDatabaseName("idx_documents_userid");
            entity.HasOne(x => x.User)
                .WithMany(x => x.Documents)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ChatMessage>(entity =>
        {
            entity.ToTable("chatmessages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
            entity.Property(x => x.DocumentId).HasColumnName("documentid").IsRequired();
            entity.Property(x => x.UserId).HasColumnName("userid").IsRequired();
            entity.Property(x => x.SenderRole).HasColumnName("senderrole").HasMaxLength(10).IsRequired();
            entity.Property(x => x.Content).HasColumnName("content").HasColumnType("text").IsRequired();
            entity.Property(x => x.QuoteReference).HasColumnName("quotereference").HasColumnType("text");
            entity.Property(x => x.CitationPage).HasColumnName("citationpage");
            entity.Property(x => x.CreatedAt).HasColumnName("createdat").HasColumnType("timestamp with time zone").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.HasIndex(x => x.DocumentId).HasDatabaseName("idx_chatmessages_documentid");
            entity.HasOne(x => x.Document)
                .WithMany(x => x.ChatMessages)
                .HasForeignKey(x => x.DocumentId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.User)
                .WithMany(x => x.ChatMessages)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
