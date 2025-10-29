using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Chat
{
    public class ChatMessageRequest
    {
        [Required]
        public int KetQuaThiId { get; set; }

        [Required]
        public string Message { get; set; } = string.Empty;
    }
}
