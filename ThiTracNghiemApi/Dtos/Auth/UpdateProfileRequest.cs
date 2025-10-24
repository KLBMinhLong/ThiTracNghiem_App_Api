using System;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Auth
{
    public class UpdateProfileRequest
    {
        [StringLength(256)]
        public string? FullName { get; set; }

        [EmailAddress]
        [StringLength(256)]
        public string? Email { get; set; }

        [Phone]
        [StringLength(20)]
        public string? SoDienThoai { get; set; }

        public DateTime? NgaySinh { get; set; }

        [StringLength(20)]
        public string? GioiTinh { get; set; }

        [Url]
        [StringLength(512)]
        public string? AvatarUrl { get; set; }
    }
}
