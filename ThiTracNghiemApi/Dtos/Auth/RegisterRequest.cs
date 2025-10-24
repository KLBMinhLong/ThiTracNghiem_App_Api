using System;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Auth
{
    public class RegisterRequest
    {
        [Required]
        [StringLength(256)]
        public string UserName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [StringLength(256)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(256, MinimumLength = 6)]
        public string Password { get; set; } = string.Empty;

        [StringLength(256)]
        public string FullName { get; set; } = string.Empty;

        public DateTime? NgaySinh { get; set; }

        [StringLength(20)]
        public string? GioiTinh { get; set; }

        [Phone]
        [StringLength(20)]
        public string? SoDienThoai { get; set; }

        [Url]
        [StringLength(512)]
        public string? AvatarUrl { get; set; }
    }
}
