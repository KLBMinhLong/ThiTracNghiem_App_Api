using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class LienHe
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string TaiKhoanId { get; set; } = string.Empty;
        public ApplicationUser? TaiKhoan { get; set; }
        [Required]
        public string TieuDe { get; set; } = string.Empty;
        [Required]
        public string NoiDung { get; set; } = string.Empty;
        public DateTime NgayGui { get; set; } = DateTime.UtcNow;
    }
}