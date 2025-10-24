using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Dtos.LienHe;
using ThiTracNghiemApi.Extensions;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LienHeController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public LienHeController(ApplicationDbContext context) => _context = context;

    // Lấy liên hệ (Admin)
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetLienHes([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.LienHes
            .AsNoTracking()
            .Include(l => l.TaiKhoan)
            .OrderByDescending(l => l.NgayGui);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new
            {
                l.Id,
                l.TieuDe,
                l.NoiDung,
                l.NgayGui,
                TaiKhoan = l.TaiKhoan == null ? null : new
                {
                    l.TaiKhoan.Id,
                    l.TaiKhoan.FullName,
                    l.TaiKhoan.UserName,
                    l.TaiKhoan.Email
                }
            })
            .ToListAsync();

        return Ok(new { total, items });
    }

    [HttpGet("mine")]
    public async Task<IActionResult> GetMyLienHes()
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var items = await _context.LienHes
            .AsNoTracking()
            .Where(l => l.TaiKhoanId == userId)
            .OrderByDescending(l => l.NgayGui)
            .Select(l => new { l.Id, l.TieuDe, l.NoiDung, l.NgayGui })
            .ToListAsync();

        return Ok(items);
    }

    // Gửi liên hệ (User)
    [HttpPost]
    public async Task<IActionResult> CreateLienHe([FromBody] CreateLienHeRequest request)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var lienHe = new LienHe
        {
            TaiKhoanId = userId,
            TieuDe = request.TieuDe.Trim(),
            NoiDung = request.NoiDung.Trim(),
            NgayGui = DateTime.UtcNow
        };

        _context.LienHes.Add(lienHe);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetLienHes), new { id = lienHe.Id }, new { lienHe.Id, lienHe.TieuDe, lienHe.NgayGui });
    }

    // Xóa liên hệ (Admin)
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteLienHe(int id)
    {
        var lienHe = await _context.LienHes.FindAsync(id);
        if (lienHe == null) return NotFound();
        _context.LienHes.Remove(lienHe);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}