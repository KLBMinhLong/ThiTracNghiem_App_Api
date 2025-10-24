using System;
using System.Collections.Generic;

namespace ThiTracNghiemApi.Dtos.Users
{
    public class UserDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? SoDienThoai { get; set; }
        public DateTime? NgaySinh { get; set; }
        public string? GioiTinh { get; set; }
        public string? AvatarUrl { get; set; }
        public bool TrangThaiKhoa { get; set; }
        public DateTime CreatedAt { get; set; }
        public IEnumerable<string> Roles { get; set; } = Array.Empty<string>();
    }
}
