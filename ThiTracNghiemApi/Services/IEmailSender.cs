namespace ThiTracNghiemApi.Services;

public interface IEmailSender
{
    Task SendEmailAsync(string toEmail, string subject, string body, bool isHtml = false);
}
