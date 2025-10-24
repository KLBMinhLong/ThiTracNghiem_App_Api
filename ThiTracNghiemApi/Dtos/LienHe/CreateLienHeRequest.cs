using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.LienHe
{
    public class CreateLienHeRequest
    {
        [Required]
        [StringLength(200)]
        public string TieuDe { get; set; } = string.Empty;

        [Required]
        [StringLength(2000)]
        public string NoiDung { get; set; } = string.Empty;
    }
}
