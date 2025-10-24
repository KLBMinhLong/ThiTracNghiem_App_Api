using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi
{
    public class KetQuaThi
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public string TaiKhoanId { get; set; } = string.Empty;
        public ApplicationUser? TaiKhoan { get; set; }
        [Required]
        public int DeThiId { get; set; }
        public DeThi? DeThi { get; set; }
        public double Diem { get; set; }
        public int SoCauDung { get; set; }
        public DateTime NgayThi { get; set; } = DateTime.UtcNow;
        public DateTime? NgayNopBai { get; set; }
        public string TrangThai { get; set; } = "DangLam";
        public ICollection<ChiTietKetQuaThi> ChiTietKetQuaThis { get; set; } = new List<ChiTietKetQuaThi>();
    }
}