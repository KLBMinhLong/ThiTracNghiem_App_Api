using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Auth
{
    public class ChangePasswordRequest
    {
        [Required]
        [StringLength(256)]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        [StringLength(256, MinimumLength = 6)]
        public string NewPassword { get; set; } = string.Empty;
    }
}
