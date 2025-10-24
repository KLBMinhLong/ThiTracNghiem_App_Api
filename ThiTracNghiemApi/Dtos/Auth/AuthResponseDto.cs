using System;
using ThiTracNghiemApi.Dtos.Users;

namespace ThiTracNghiemApi.Dtos.Auth
{
    public class AuthResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public UserDto User { get; set; } = new UserDto();
    }
}
