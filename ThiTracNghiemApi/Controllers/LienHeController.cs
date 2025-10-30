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

        return CreatedAtAction(
            nameof(GetLienHes),
            new { id = lienHe.Id },
            new { lienHe.Id, lienHe.TieuDe, lienHe.NoiDung, lienHe.NgayGui, lienHe.TaiKhoanId }
        );
    }

    // Cập nhật liên hệ (User chỉ có thể sửa liên hệ của mình; Admin có thể sửa bất kỳ)
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateLienHe(int id, [FromBody] UpdateLienHeRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var currentUser = await User.ResolveUserAsync(_context);
        if (currentUser == null)
        {
            return Unauthorized();
        }

        var lienHe = await _context.LienHes.FirstOrDefaultAsync(l => l.Id == id);
        if (lienHe == null)
        {
            return NotFound();
        }

        var isOwner = lienHe.TaiKhoanId == currentUser.Id;
        var isAdmin = User.IsInRole("Admin");
        if (!isOwner && !isAdmin)
        {
            return Forbid();
        }

        lienHe.TieuDe = request.TieuDe.Trim();
        lienHe.NoiDung = request.NoiDung.Trim();
        await _context.SaveChangesAsync();

        return Ok(new
        {
            lienHe.Id,
            lienHe.TieuDe,
            lienHe.NoiDung,
            lienHe.NgayGui,
            lienHe.TaiKhoanId
        });
    }

    // Xóa liên hệ (Admin hoặc chủ sở hữu)
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteLienHe(int id)
    {
        var currentUser = await User.ResolveUserAsync(_context);
        if (currentUser == null)
        {
            return Unauthorized();
        }

        var lienHe = await _context.LienHes.FirstOrDefaultAsync(l => l.Id == id);
        if (lienHe == null)
        {
            return NotFound();
        }

        var isOwner = lienHe.TaiKhoanId == currentUser.Id;
        var isAdmin = User.IsInRole("Admin");
        if (!isOwner && !isAdmin)
        {
            return Forbid();
        }

        _context.LienHes.Remove(lienHe);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}