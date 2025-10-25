using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Auth;

public class GoogleLoginRequest
{
    [Required]
    public string IdToken { get; set; } = string.Empty;
}
