using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Auth
{
    public class LoginRequest
    {
        [Required]
        [StringLength(256)]
        public string UserName { get; set; } = string.Empty;

        [Required]
        [StringLength(256)]
        public string Password { get; set; } = string.Empty;
    }
}
