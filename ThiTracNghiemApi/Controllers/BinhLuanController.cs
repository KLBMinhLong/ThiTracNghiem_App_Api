using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Dtos.BinhLuan;
using ThiTracNghiemApi.Extensions;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BinhLuanController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public BinhLuanController(ApplicationDbContext context) => _context = context;

    // Lấy bình luận theo đề thi
    [AllowAnonymous]
    [HttpGet("dethi/{deThiId}")]
    public async Task<IActionResult> GetBinhLuans(int deThiId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.BinhLuans
            .AsNoTracking()
            .Include(b => b.TaiKhoan)
            .Where(b => b.DeThiId == deThiId)
            .OrderByDescending(b => b.NgayTao);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(b => new
            {
                b.Id,
                b.NoiDung,
                b.NgayTao,
                b.DeThiId,
                TaiKhoan = b.TaiKhoan == null ? null : new
                {
                    b.TaiKhoan.Id,
                    UserName = b.TaiKhoan.UserName,
                    FullName = b.TaiKhoan.FullName,
                    AvatarUrl = b.TaiKhoan.AvatarUrl
                }
            })
            .ToListAsync();

        return Ok(new { total, items });
    }

    // Tạo bình luận (User)
    [HttpPost]
    public async Task<IActionResult> CreateBinhLuan([FromBody] CreateBinhLuanRequest request)
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

        var binhLuan = new BinhLuan
        {
            DeThiId = request.DeThiId,
            TaiKhoanId = userId,
            NoiDung = request.NoiDung.Trim(),
            NgayTao = DateTime.UtcNow
        };

        _context.BinhLuans.Add(binhLuan);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetBinhLuans), new { deThiId = binhLuan.DeThiId }, new
        {
            binhLuan.Id,
            binhLuan.NoiDung,
            binhLuan.NgayTao,
            binhLuan.DeThiId
        });
    }

    // Cập nhật bình luận (chỉ của chính mình)
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateBinhLuan(int id, [FromBody] UpdateBinhLuanRequest request)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }
        var existing = await _context.BinhLuans.FindAsync(id);
        if (existing == null)
        {
            return NotFound();
        }

        if (existing.TaiKhoanId != userId)
        {
            return Forbid();
        }

        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        existing.NoiDung = request.NoiDung.Trim();
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // Xóa bình luận (chủ sở hữu hoặc Admin)
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteBinhLuan(int id)
    {
        var userId = await User.ResolveUserIdAsync(_context);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }
        var binhLuan = await _context.BinhLuans.FindAsync(id);
        if (binhLuan == null) return NotFound();
        if (binhLuan.TaiKhoanId != userId && !User.IsInRole("Admin")) return Forbid();
        _context.BinhLuans.Remove(binhLuan);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}