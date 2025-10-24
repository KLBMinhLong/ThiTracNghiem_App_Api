using System.Collections.Generic;
using ThiTracNghiemApi.Dtos.Users;
using ThiTracNghiemApi;

namespace ThiTracNghiemApi.Extensions
{
    public static class UserMappingExtensions
    {
        public static UserDto ToDto(this ApplicationUser user, IEnumerable<string> roles)
        {
            return new UserDto
            {
                Id = user.Id,
                UserName = user.UserName ?? string.Empty,
                Email = user.Email ?? string.Empty,
                FullName = user.FullName ?? string.Empty,
                SoDienThoai = user.SoDienThoai ?? user.PhoneNumber,
                NgaySinh = user.NgaySinh,
                GioiTinh = user.GioiTinh,
                AvatarUrl = user.AvatarUrl,
                TrangThaiKhoa = user.TrangThaiKhoa,
                CreatedAt = user.CreatedAt,
                Roles = roles
            };
        }
    }
}
