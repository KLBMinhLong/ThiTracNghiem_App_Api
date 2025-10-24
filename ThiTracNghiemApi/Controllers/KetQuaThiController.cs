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
public class KetQuaThiController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public KetQuaThiController(ApplicationDbContext context) => _context = context;

    [HttpGet]
    public async Task<IActionResult> GetKetQuaThis([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        var isAdmin = User.IsInRole("Admin");

        if (!isAdmin && string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = _context.KetQuaThis
            .AsNoTracking()
            .Include(k => k.DeThi)
            .Include(k => k.TaiKhoan)
            .OrderByDescending(k => k.NgayThi)
            .AsQueryable();

        if (!isAdmin)
        {
            query = query.Where(k => k.TaiKhoanId == userId);
        }

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(k => new
            {
                k.Id,
                k.Diem,
                k.SoCauDung,
                k.TrangThai,
                k.NgayThi,
                k.NgayNopBai,
                DeThi = k.DeThi == null ? null : new { k.DeThi.Id, k.DeThi.TenDeThi, k.DeThi.ThoiGianThi },
                TaiKhoan = isAdmin && k.TaiKhoan != null
                    ? new { k.TaiKhoan.Id, k.TaiKhoan.FullName, k.TaiKhoan.UserName }
                    : null
            })
            .ToListAsync();

        return Ok(new { total, items });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetKetQuaThi(int id)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        var isAdmin = User.IsInRole("Admin");

        if (!isAdmin && string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var ketQuaThi = await _context.KetQuaThis
            .AsNoTracking()
            .Include(k => k.DeThi)
            .Include(k => k.ChiTietKetQuaThis)
                .ThenInclude(c => c.CauHoi)
            .FirstOrDefaultAsync(k => k.Id == id);

        if (ketQuaThi == null)
        {
            return NotFound();
        }

        if (!isAdmin && ketQuaThi.TaiKhoanId != userId)
        {
            return Forbid();
        }

        var response = new
        {
            ketQuaThi.Id,
            ketQuaThi.Diem,
            ketQuaThi.SoCauDung,
            TongSoCau = ketQuaThi.ChiTietKetQuaThis.Count,
            ketQuaThi.TrangThai,
            ketQuaThi.NgayThi,
            ketQuaThi.NgayNopBai,
            ketQuaThi.DeThiId,
            DeThi = ketQuaThi.DeThi == null ? null : new
            {
                ketQuaThi.DeThi.Id,
                ketQuaThi.DeThi.TenDeThi,
                ketQuaThi.DeThi.ThoiGianThi
            },
            ChiTiet = ketQuaThi.ChiTietKetQuaThis.Select(ct => new ChiTietKetQuaThiDto
            {
                CauHoiId = ct.CauHoiId,
                NoiDung = ct.CauHoi?.NoiDung ?? string.Empty,
                HinhAnh = ct.CauHoi?.HinhAnh,
                AmThanh = ct.CauHoi?.AmThanh,
                DapAnA = ct.CauHoi?.DapAnA ?? string.Empty,
                DapAnB = ct.CauHoi?.DapAnB ?? string.Empty,
                DapAnC = ct.CauHoi?.DapAnC,
                DapAnD = ct.CauHoi?.DapAnD,
                DapAnChon = ct.DapAnChon,
                DapAnDung = ct.CauHoi?.DapAnDung ?? string.Empty,
                DungHaySai = ct.DungHaySai
            }).ToList()
        };

        return Ok(response);
    }
}