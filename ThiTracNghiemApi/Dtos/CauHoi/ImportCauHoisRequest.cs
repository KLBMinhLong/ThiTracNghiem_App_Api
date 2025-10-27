using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace ThiTracNghiemApi.Dtos.CauHoi
{
    public class ImportCauHoisRequest
    {
        [Required]
        public IFormFile File { get; set; }

        [Required]
        public int TopicId { get; set; }
    }
}
