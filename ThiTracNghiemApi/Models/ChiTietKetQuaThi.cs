using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class ChiTietKetQuaThi
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int KetQuaThiId { get; set; }
        public KetQuaThi? KetQuaThi { get; set; }
        [Required]
        public int CauHoiId { get; set; }
        public CauHoi? CauHoi { get; set; }
        public string? DapAnChon { get; set; }  // e.g., "A", null nếu chưa chọn
        public bool? DungHaySai { get; set; }
    }
}