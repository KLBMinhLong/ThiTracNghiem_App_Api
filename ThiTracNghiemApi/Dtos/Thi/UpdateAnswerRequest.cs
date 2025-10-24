using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Thi
{
    public class UpdateAnswerRequest
    {
        [Required]
        [RegularExpression("^[ABCD]$", ErrorMessage = "Đáp án chỉ hợp lệ A, B, C hoặc D")]
        public string DapAnChon { get; set; } = string.Empty;
    }
}
