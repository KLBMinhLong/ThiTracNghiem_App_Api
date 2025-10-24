using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Users
{
    public class UpdateUserStatusRequest
    {
        [Required]
        public bool TrangThaiKhoa { get; set; }
    }
}
