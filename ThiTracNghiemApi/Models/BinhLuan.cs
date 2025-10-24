using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class BinhLuan
    {
        [Key]
        public int Id { get; set; }
        [Required]
    public int DeThiId { get; set; }
    public DeThi? DeThi { get; set; }
    [Required]
    public string TaiKhoanId { get; set; } = string.Empty;
    public ApplicationUser? TaiKhoan { get; set; }
    [Required]
    [StringLength(500)]
    public string NoiDung { get; set; } = string.Empty;
        public DateTime NgayTao { get; set; } = DateTime.UtcNow;
    }
}