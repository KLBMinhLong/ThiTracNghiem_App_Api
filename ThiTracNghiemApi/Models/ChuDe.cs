using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class ChuDe
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string TenChuDe { get; set; } = string.Empty;
        public string MoTa { get; set; } = string.Empty;
        public ICollection<CauHoi> CauHois { get; set; } = new List<CauHoi>();
        public ICollection<DeThi> DeThis { get; set; } = new List<DeThi>();
    }
}