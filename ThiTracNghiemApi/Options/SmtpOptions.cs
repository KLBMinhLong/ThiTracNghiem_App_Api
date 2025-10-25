namespace ThiTracNghiemApi.Options;

public class SmtpOptions
{
    public string Host { get; set; } = "smtp.gmail.com";
    public int Port { get; set; } = 587;
    public bool EnableSsl { get; set; } = true;
    public string? User { get; set; }
        = null; // Defaults pulled from environment if not configured.
    public string? Password { get; set; }
        = null; // Defaults pulled from environment if not configured.
    public string? FromEmail { get; set; }
        = null; // Defaults to User if left empty.
    public string? FromName { get; set; }
        = null;
}
