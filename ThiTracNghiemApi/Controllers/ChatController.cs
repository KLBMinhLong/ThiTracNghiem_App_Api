using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi.Dtos.Chat;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Extensions;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ChatController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpPost("explain")]
    public async Task<ActionResult<ChatMessageResponse>> Explain([FromBody] ChatMessageRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { message = "Message is required" });
        }

        var userId = await User.ResolveUserIdAsync(_context);
        var isAdmin = User.IsInRole("Admin");
        if (!isAdmin && string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var ketQua = await _context.KetQuaThis
            .AsNoTracking()
            .Include(k => k.DeThi)
            .Include(k => k.ChiTietKetQuaThis)
                .ThenInclude(ct => ct.CauHoi)
            .FirstOrDefaultAsync(k => k.Id == request.KetQuaThiId);

        if (ketQua == null)
        {
            return NotFound(new { message = "Không tìm thấy kết quả thi" });
        }
        if (!isAdmin && ketQua.TaiKhoanId != userId)
        {
            return Forbid();
        }

        // Build exam context text
        var sb = new StringBuilder();
        sb.AppendLine($"Đề thi: {ketQua.DeThi?.TenDeThi ?? ketQua.DeThiId.ToString()} | Ngày thi: {ketQua.NgayThi:yyyy-MM-dd HH:mm} | Điểm: {ketQua.Diem}");
        var i = 1;
        foreach (var ct in ketQua.ChiTietKetQuaThis.OrderBy(x => x.Id))
        {
            var q = ct.CauHoi;
            if (q == null) continue;
            sb.AppendLine($"Câu {i}: {q.NoiDung}");
            sb.AppendLine($"A. {q.DapAnA}");
            sb.AppendLine($"B. {q.DapAnB}");
            if (!string.IsNullOrWhiteSpace(q.DapAnC)) sb.AppendLine($"C. {q.DapAnC}");
            if (!string.IsNullOrWhiteSpace(q.DapAnD)) sb.AppendLine($"D. {q.DapAnD}");
            sb.AppendLine($"Đã chọn: {ct.DapAnChon ?? "(không chọn)"} | Đúng: {ct.DungHaySai?.ToString() ?? "?"} | Đáp án đúng: {q.DapAnDung}");
            sb.AppendLine();
            i++;
        }

        var systemPrompt = "Bạn là trợ lý giảng dạy hữu ích. Hãy trả lời bằng tiếng Việt, giải thích rõ ràng, trích dẫn nội dung câu hỏi/đáp án khi cần. Nếu người dùng hỏi về một câu, tham chiếu theo số câu (Câu 1, Câu 2, ...).";
        var contextText = sb.ToString();

        var apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY") ?? string.Empty;
        var model = Environment.GetEnvironmentVariable("OPENAI_MODEL") ?? "gpt-4o-mini";

        if (!string.IsNullOrWhiteSpace(apiKey))
        {
            try
            {
                using var client = new HttpClient();
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                var payload = new
                {
                    model,
                    messages = new object[]
                    {
                        new { role = "system", content = systemPrompt },
                        new { role = "user", content = $"Ngữ cảnh đề thi và câu hỏi:\n\n{contextText}\n\nCâu hỏi của tôi: {request.Message}" }
                    },
                    temperature = 0.2
                };
                var json = JsonSerializer.Serialize(payload);
                var resp = await client.PostAsync("https://api.openai.com/v1/chat/completions", new StringContent(json, Encoding.UTF8, "application/json"));
                var respBody = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode)
                {
                    // Fallback to simple reply
                    var fallback = SimpleExplainReply(request.Message, ketQua);
                    return Ok(new ChatMessageResponse { Reply = fallback + $"\n\n(Lưu ý: Gọi AI thất bại {resp.StatusCode})" });
                }

                using var doc = JsonDocument.Parse(respBody);
                var content = doc.RootElement
                    .GetProperty("choices")[0]
                    .GetProperty("message")
                    .GetProperty("content")
                    .GetString() ?? string.Empty;
                return Ok(new ChatMessageResponse { Reply = content });
            }
            catch (Exception ex)
            {
                var fallback = SimpleExplainReply(request.Message, ketQua);
                return Ok(new ChatMessageResponse { Reply = fallback + $"\n\n(Lưu ý: AI không khả dụng: {ex.Message})" });
            }
        }
        else
        {
            // No API key -> fallback simple rule-based reply
            var reply = SimpleExplainReply(request.Message, ketQua);
            reply += "\n\n(Gợi ý: Thiết lập biến môi trường OPENAI_API_KEY để bật câu trả lời AI chi tiết.)";
            return Ok(new ChatMessageResponse { Reply = reply });
        }
    }

    private static string SimpleExplainReply(string userMessage, KetQuaThi ketQua)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Tóm tắt nhanh đề và đáp án:");
        int i = 1;
        foreach (var ct in ketQua.ChiTietKetQuaThis.OrderBy(x => x.Id))
        {
            var q = ct.CauHoi;
            if (q == null) continue;
            sb.Append($"Câu {i}: Đáp án đúng là {q.DapAnDung}");
            if (!string.IsNullOrWhiteSpace(ct.DapAnChon))
            {
                sb.Append($", bạn đã chọn {ct.DapAnChon} {(ct.DungHaySai == true ? "(đúng)" : "(sai)")}");
            }
            sb.AppendLine(".");
            i++;
        }
        sb.AppendLine();
        sb.AppendLine("Lưu ý: Chức năng AI đầy đủ chưa được bật trên máy chủ này. Nội dung trên chỉ là tóm tắt.");
        return sb.ToString();
    }
}
