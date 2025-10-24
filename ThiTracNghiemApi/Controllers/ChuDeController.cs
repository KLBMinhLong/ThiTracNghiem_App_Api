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
public class ChuDeController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ChuDeController(ApplicationDbContext context) => _context = context;

    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetChuDes([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.ChuDes
            .AsNoTracking()
            .OrderBy(c => c.TenChuDe);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new { c.Id, c.TenChuDe, c.MoTa })
            .ToListAsync();

        return Ok(new { total, items });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetChuDe(int id)
    {
        var chuDe = await _context.ChuDes.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
        if (chuDe == null) return NotFound();
        return Ok(chuDe);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateChuDe([FromBody] ChuDe chuDe)
    {
        _context.ChuDes.Add(chuDe);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetChuDe), new { id = chuDe.Id }, chuDe);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateChuDe(int id, [FromBody] ChuDe chuDe)
    {
        if (id != chuDe.Id) return BadRequest();
        _context.Entry(chuDe).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteChuDe(int id)
    {
        var chuDe = await _context.ChuDes.FindAsync(id);
        if (chuDe == null) return NotFound();
        // Kiểm tra nếu có DeThi hoặc CauHoi liên quan, không cho xóa
        if (await _context.DeThis.AnyAsync(d => d.ChuDeId == id) || await _context.CauHois.AnyAsync(c => c.ChuDeId == id))
            return BadRequest("Không thể xóa chủ đề vì có đề thi hoặc câu hỏi liên quan.");
        _context.ChuDes.Remove(chuDe);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}