using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Dtos.Thi;
using ThiTracNghiemApi.Extensions;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ThiController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ThiController(ApplicationDbContext context) => _context = context;

    // Bắt đầu thi: Tạo KetQuaThi và ChiTietKetQuaThi cho từng câu
    [HttpPost("start/{deThiId}")]
    public async Task<ActionResult<StartThiResponse>> StartThi(int deThiId)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Phiên đăng nhập không hợp lệ, vui lòng đăng nhập lại.");
        }

        var deThi = await _context.DeThis
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == deThiId);

        if (deThi == null || !string.Equals(deThi.TrangThai, "Mo", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound("Đề thi không tồn tại hoặc chưa mở.");
        }

        var existing = await _context.KetQuaThis
            .Include(k => k.ChiTietKetQuaThis)
                .ThenInclude(ct => ct.CauHoi)
            .FirstOrDefaultAsync(k => k.DeThiId == deThiId && k.TaiKhoanId == userId && k.TrangThai == "DangLam");

        if (existing != null)
        {
            var existingQuestions = existing.ChiTietKetQuaThis
                .Select(ct => ct.CauHoi)
                .Where(c => c != null)
                .Select(c => new ThiQuestionDto
                {
                    Id = c!.Id,
                    NoiDung = c.NoiDung,
                    HinhAnh = c.HinhAnh,
                    AmThanh = c.AmThanh,
                    DapAnA = c.DapAnA,
                    DapAnB = c.DapAnB,
                    DapAnC = c.DapAnC,
                    DapAnD = c.DapAnD
                })
                .ToList();

            return Ok(new StartThiResponse
            {
                KetQuaThiId = existing.Id,
                DeThiId = existing.DeThiId,
                TenDeThi = deThi.TenDeThi,
                SoCauHoi = existingQuestions.Count,
                ThoiGianThi = deThi.ThoiGianThi,
                NgayBatDau = existing.NgayThi,
                CauHois = existingQuestions
            });
        }

        // Nếu đề thi không cho phép làm lại và người dùng đã hoàn thành trước đó -> chặn
        if (!deThi.AllowMultipleAttempts && await _context.KetQuaThis.AnyAsync(k => k.TaiKhoanId == userId && k.DeThiId == deThiId && k.TrangThai == "HoanThanh"))
        {
            return BadRequest("Bạn đã hoàn thành đề thi này.");
        }

        if (deThi.SoCauHoi <= 0)
        {
            return BadRequest("Đề thi chưa cấu hình số câu hỏi hợp lệ.");
        }

        var cauHoiNguon = await _context.CauHois
            .AsNoTracking()
            .Where(c => c.ChuDeId == deThi.ChuDeId)
            .ToListAsync();

        if (!cauHoiNguon.Any())
        {
            return BadRequest("Chủ đề chưa có câu hỏi.");
        }

        var soCauCanLay = Math.Min(deThi.SoCauHoi, cauHoiNguon.Count);

        var randomQuestions = cauHoiNguon
            .OrderBy(_ => Guid.NewGuid())
            .Take(soCauCanLay)
            .ToList();

        if (!randomQuestions.Any())
        {
            return BadRequest("Không đủ câu hỏi cho đề thi.");
        }

        var ketQuaThi = new KetQuaThi
        {
            TaiKhoanId = userId,
            DeThiId = deThiId,
            NgayThi = DateTime.UtcNow,
            TrangThai = "DangLam"
        };

        _context.KetQuaThis.Add(ketQuaThi);
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.InnerException?.Message.Contains("FK_KetQuaThis_AspNetUsers_TaiKhoanId", StringComparison.OrdinalIgnoreCase) == true)
        {
            return Unauthorized("Phiên đăng nhập không hợp lệ, vui lòng đăng nhập lại.");
        }

        foreach (var item in randomQuestions)
        {
            _context.ChiTietKetQuaThis.Add(new ChiTietKetQuaThi
            {
                KetQuaThiId = ketQuaThi.Id,
                CauHoiId = item.Id
            });
        }

        await _context.SaveChangesAsync();

        var response = new StartThiResponse
        {
            KetQuaThiId = ketQuaThi.Id,
            DeThiId = deThi.Id,
            TenDeThi = deThi.TenDeThi,
            SoCauHoi = randomQuestions.Count,
            ThoiGianThi = deThi.ThoiGianThi,
            NgayBatDau = ketQuaThi.NgayThi,
            CauHois = randomQuestions.Select(c => new ThiQuestionDto
            {
                Id = c.Id,
                NoiDung = c.NoiDung,
                HinhAnh = c.HinhAnh,
                AmThanh = c.AmThanh,
                DapAnA = c.DapAnA,
                DapAnB = c.DapAnB,
                DapAnC = c.DapAnC,
                DapAnD = c.DapAnD
            }).ToList()
        };

        return Ok(response);
    }

    // Update đáp án cho một câu
    [HttpPut("update/{ketQuaThiId}/{cauHoiId}")]
    public async Task<IActionResult> UpdateDapAn(int ketQuaThiId, int cauHoiId, [FromBody] UpdateAnswerRequest request)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Phiên đăng nhập không hợp lệ, vui lòng đăng nhập lại.");
        }

        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var ketQua = await _context.KetQuaThis.FirstOrDefaultAsync(k => k.Id == ketQuaThiId);
        if (ketQua == null)
        {
            return NotFound();
        }

        if (ketQua.TaiKhoanId != userId)
        {
            return Forbid();
        }

        if (ketQua.TrangThai == "HoanThanh")
        {
            return BadRequest("Bài thi đã được nộp, không thể cập nhật thêm.");
        }

        var chiTiet = await _context.ChiTietKetQuaThis
            .Include(ct => ct.CauHoi)
            .FirstOrDefaultAsync(c => c.KetQuaThiId == ketQuaThiId && c.CauHoiId == cauHoiId);

        if (chiTiet == null)
        {
            return NotFound();
        }

        chiTiet.DapAnChon = request.DapAnChon;
        if (chiTiet.CauHoi != null)
        {
            chiTiet.DungHaySai = string.Equals(request.DapAnChon, chiTiet.CauHoi.DapAnDung, StringComparison.OrdinalIgnoreCase);
        }

        await _context.SaveChangesAsync();
        return Ok();
    }

    // Submit thi: Tính điểm và cập nhật KetQuaThi
    [HttpPost("submit/{ketQuaThiId}")]
    public async Task<ActionResult<SubmitThiResponse>> SubmitThi(int ketQuaThiId)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Phiên đăng nhập không hợp lệ, vui lòng đăng nhập lại.");
        }
        var ketQuaThi = await _context.KetQuaThis.Include(k => k.ChiTietKetQuaThis).ThenInclude(c => c.CauHoi)
            .FirstOrDefaultAsync(k => k.Id == ketQuaThiId && k.TaiKhoanId == userId);
        if (ketQuaThi == null) return NotFound();

        if (ketQuaThi.TrangThai == "HoanThanh")
        {
            return BadRequest("Bài thi đã được nộp.");
        }

        var tongSoCau = ketQuaThi.ChiTietKetQuaThis.Count;
        if (tongSoCau == 0)
        {
            return BadRequest("Không tìm thấy câu hỏi nào trong bài thi.");
        }

        var soCauDung = 0;
        var chiTietDtos = new List<ChiTietKetQuaThiDto>();

        foreach (var chiTiet in ketQuaThi.ChiTietKetQuaThis)
        {
            var cauHoi = chiTiet.CauHoi;
            if (cauHoi == null)
            {
                continue;
            }

            var dung = !string.IsNullOrEmpty(chiTiet.DapAnChon) && string.Equals(chiTiet.DapAnChon, cauHoi.DapAnDung, StringComparison.OrdinalIgnoreCase);
            if (dung)
            {
                soCauDung++;
            }

            chiTiet.DungHaySai = dung;

            chiTietDtos.Add(new ChiTietKetQuaThiDto
            {
                CauHoiId = cauHoi.Id,
                NoiDung = cauHoi.NoiDung,
                HinhAnh = cauHoi.HinhAnh,
                AmThanh = cauHoi.AmThanh,
                DapAnA = cauHoi.DapAnA,
                DapAnB = cauHoi.DapAnB,
                DapAnC = cauHoi.DapAnC,
                DapAnD = cauHoi.DapAnD,
                DapAnChon = chiTiet.DapAnChon,
                DapAnDung = cauHoi.DapAnDung,
                DungHaySai = dung
            });
        }

        var diem = Math.Round((double)soCauDung / tongSoCau * 10, 2);
        ketQuaThi.Diem = diem;
        ketQuaThi.SoCauDung = soCauDung;
        ketQuaThi.TrangThai = "HoanThanh";
        ketQuaThi.NgayNopBai = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        var response = new SubmitThiResponse
        {
            Diem = diem,
            SoCauDung = soCauDung,
            TongSoCau = tongSoCau,
            ChiTiet = chiTietDtos
        };

        return Ok(response);
    }
}