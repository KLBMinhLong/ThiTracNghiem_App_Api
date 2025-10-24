using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class CauHoi
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string NoiDung { get; set; } = string.Empty;
        public string? HinhAnh { get; set; }
        public string? AmThanh { get; set; }
        [Required]
        public string DapAnA { get; set; } = string.Empty;
        [Required]
        public string DapAnB { get; set; } = string.Empty;
        public string? DapAnC { get; set; }
        public string? DapAnD { get; set; }
        [Required]
        public string DapAnDung { get; set; } = string.Empty;  // e.g., "A"
        public int ChuDeId { get; set; }
        public ChuDe? ChuDe { get; set; }
        public ICollection<ChiTietKetQuaThi> ChiTietKetQuaThis { get; set; } = new List<ChiTietKetQuaThi>();
    }
}