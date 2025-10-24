using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<ChuDe> ChuDes { get; set; }
    public DbSet<CauHoi> CauHois { get; set; }
    public DbSet<DeThi> DeThis { get; set; }
    public DbSet<KetQuaThi> KetQuaThis { get; set; }
    public DbSet<ChiTietKetQuaThi> ChiTietKetQuaThis { get; set; }
    public DbSet<BinhLuan> BinhLuans { get; set; }
    public DbSet<LienHe> LienHes { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<ApplicationUser>()
            .Property(u => u.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.Entity<ApplicationUser>()
            .Property(u => u.TrangThaiKhoa)
            .HasDefaultValue(false);

        builder.Entity<KetQuaThi>()
            .Property(k => k.TrangThai)
            .HasDefaultValue("DangLam");

        builder.Entity<KetQuaThi>()
            .Property(k => k.NgayThi)
            .HasDefaultValueSql("GETUTCDATE()");

        // Seed roles
        builder.Entity<IdentityRole>().HasData(
            new IdentityRole { Id = "1", Name = "Admin", NormalizedName = "ADMIN" },
            new IdentityRole { Id = "2", Name = "User", NormalizedName = "USER" }
        );

        // Cấu hình để tránh vòng lặp cascade delete
        builder.Entity<ChiTietKetQuaThi>()
            .HasOne(c => c.KetQuaThi)
            .WithMany(k => k.ChiTietKetQuaThis)
            .HasForeignKey(c => c.KetQuaThiId)
            .OnDelete(DeleteBehavior.NoAction);  // Thay CASCADE bằng NoAction

        // Nếu cần, thêm cho các FK khác để tránh vòng lặp (e.g., nếu có vấn đề với BinhLuan hoặc LienHe)
        builder.Entity<BinhLuan>()
            .HasOne(b => b.DeThi)
            .WithMany(d => d.BinhLuans)
            .HasForeignKey(b => b.DeThiId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.Entity<KetQuaThi>()
            .HasOne(k => k.DeThi)
            .WithMany(d => d.KetQuaThis)
            .HasForeignKey(k => k.DeThiId)
            .OnDelete(DeleteBehavior.NoAction);

        // Giữ CASCADE cho các FK không gây vòng lặp (e.g., CauHoi -> ChuDe, DeThi -> ChuDe)
    }
}