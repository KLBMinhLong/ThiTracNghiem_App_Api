using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Auth
{
    public class TwoFaSetupResponse
    {
        public string SharedKey { get; set; } = string.Empty;
        public string AuthenticatorUri { get; set; } = string.Empty;
        public bool Enabled { get; set; }
    }

    public class TwoFaEnableRequest
    {
        [Required]
        public string Code { get; set; } = string.Empty;
    }

    public class TwoFaLoginRequest
    {
        [Required]
        public string UserId { get; set; } = string.Empty;
        [Required]
        public string Code { get; set; } = string.Empty;
    }

    public class TwoFaStatusResponse
    {
        public bool Enabled { get; set; }
    }
}
