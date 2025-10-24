using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.BinhLuan
{
    public class CreateBinhLuanRequest
    {
        [Required]
        public int DeThiId { get; set; }

        [Required]
        [StringLength(500, MinimumLength = 5)]
        public string NoiDung { get; set; } = string.Empty;
    }
}
