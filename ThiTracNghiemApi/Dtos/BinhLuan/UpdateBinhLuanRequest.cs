using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.BinhLuan
{
    public class UpdateBinhLuanRequest
    {
        [Required]
        [StringLength(500, MinimumLength = 5)]
        public string NoiDung { get; set; } = string.Empty;
    }
}
