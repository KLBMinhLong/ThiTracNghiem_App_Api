using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace ThiTracNghiemApi
{
    public class ApplicationUser : IdentityUser
    {
        public string FullName { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? NgaySinh { get; set; }
        public string? GioiTinh { get; set; }
        public string? SoDienThoai { get; set; }
        public string? AvatarUrl { get; set; }
        public bool TrangThaiKhoa { get; set; }
        public ICollection<KetQuaThi> KetQuaThis { get; set; } = new List<KetQuaThi>();
        public ICollection<BinhLuan> BinhLuans { get; set; } = new List<BinhLuan>();
        public ICollection<LienHe> LienHes { get; set; } = new List<LienHe>();
    }
}