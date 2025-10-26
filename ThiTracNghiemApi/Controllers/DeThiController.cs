using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DeThiController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public DeThiController(ApplicationDbContext context) => _context = context;

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetDeThis([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.DeThis
            .AsNoTracking()
            .Include(d => d.ChuDe)
            .OrderByDescending(d => d.NgayTao);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(d => new
            {
                d.Id,
                d.TenDeThi,
                ChuDeId = d.ChuDeId,
                TrangThai = d.TrangThai,
                d.AllowMultipleAttempts,
                d.SoCauHoi,
                d.ThoiGianThi,
                d.NgayTao,
                ChuDe = d.ChuDe == null ? null : new { d.ChuDe.Id, d.ChuDe.TenChuDe }
            })
            .ToListAsync();

        return Ok(new { total, items });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetDeThi(int id)
    {
        var deThi = await _context.DeThis
            .AsNoTracking()
            .Include(d => d.ChuDe)
            .FirstOrDefaultAsync(d => d.Id == id);
        if (deThi == null) return NotFound();
        return Ok(deThi);
    }

    [HttpGet("open")]
    [AllowAnonymous]
    public async Task<IActionResult> GetOpenDeThis()
    {
        var openStatuses = new[] { "mo", "mở", "open" };

        var items = await _context.DeThis
            .AsNoTracking()
            .Where(d => openStatuses.Contains((d.TrangThai ?? string.Empty).Trim().ToLower()))
            .Include(d => d.ChuDe)
            .OrderByDescending(d => d.NgayTao)
            .Select(d => new
            {
                d.Id,
                d.TenDeThi,
                ChuDeId = d.ChuDeId,
                TrangThai = d.TrangThai,
                d.AllowMultipleAttempts,
                d.SoCauHoi,
                d.ThoiGianThi,
                d.NgayTao,
                ChuDe = d.ChuDe == null ? null : new { d.ChuDe.Id, d.ChuDe.TenChuDe }
            })
            .ToListAsync();

        return Ok(items);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateDeThi([FromBody] DeThi deThi)
    {
        _context.DeThis.Add(deThi);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetDeThi), new { id = deThi.Id }, deThi);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateDeThi(int id, [FromBody] DeThi deThi)
    {
        if (id != deThi.Id) return BadRequest();
        _context.Entry(deThi).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteDeThi(int id)
    {
        var deThi = await _context.DeThis.FindAsync(id);
        if (deThi == null) return NotFound();
        // Kiểm tra nếu có KetQuaThi liên quan
        if (await _context.KetQuaThis.AnyAsync(k => k.DeThiId == id))
            return BadRequest("Không thể xóa đề thi vì có kết quả thi liên quan.");
        _context.DeThis.Remove(deThi);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}