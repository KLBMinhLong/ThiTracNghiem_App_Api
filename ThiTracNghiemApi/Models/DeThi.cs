using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class DeThi
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string TenDeThi { get; set; } = string.Empty;
        public int ChuDeId { get; set; }
        public ChuDe? ChuDe { get; set; }
        [Required]
        public int SoCauHoi { get; set; }
        [Required]
        public int ThoiGianThi { get; set; }  // Phút
        [Required]
        public string TrangThai { get; set; } = "Mo";  // "Mo" or "Dong"
        public DateTime NgayTao { get; set; } = DateTime.UtcNow;
        public ICollection<KetQuaThi> KetQuaThis { get; set; } = new List<KetQuaThi>();
        public ICollection<BinhLuan> BinhLuans { get; set; } = new List<BinhLuan>();
    }
}