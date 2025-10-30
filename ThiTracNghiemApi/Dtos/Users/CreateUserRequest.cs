using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Users
{
    public class CreateUserRequest
    {
        [Required]
        [MinLength(3)]
        public string UserName { get; set; } = string.Empty;

        [EmailAddress]
        public string? Email { get; set; }

        public string? FullName { get; set; }

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        public List<string>? Roles { get; set; }
    }
}
