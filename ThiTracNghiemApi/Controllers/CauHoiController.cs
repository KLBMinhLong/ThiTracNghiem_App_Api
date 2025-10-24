using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ClosedXML.Excel;  // Cho import Excel
using ThiTracNghiemApi;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CauHoiController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CauHoiController(ApplicationDbContext context) => _context = context;

    [HttpGet]
    public async Task<IActionResult> GetCauHois() => Ok(await _context.CauHois.Include(c => c.ChuDe).ToListAsync());

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCauHoi(int id)
    {
        var cauHoi = await _context.CauHois.Include(c => c.ChuDe).FirstOrDefaultAsync(c => c.Id == id);
        if (cauHoi == null) return NotFound();
        return Ok(cauHoi);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateCauHoi([FromBody] CauHoi cauHoi)
    {
        _context.CauHois.Add(cauHoi);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCauHoi), new { id = cauHoi.Id }, cauHoi);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateCauHoi(int id, [FromBody] CauHoi cauHoi)
    {
        if (id != cauHoi.Id) return BadRequest();
        _context.Entry(cauHoi).State = EntityState.Modified;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCauHoi(int id)
    {
        var cauHoi = await _context.CauHois.FindAsync(id);
        if (cauHoi == null) return NotFound();
        _context.CauHois.Remove(cauHoi);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    // Import từ Excel (giống web cũ)
    [HttpPost("import")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ImportCauHois(IFormFile file)
    {
        if (file == null || file.Length == 0) return BadRequest("File không hợp lệ.");
        using var workbook = new XLWorkbook(file.OpenReadStream());
        var worksheet = workbook.Worksheet(1);  // Sheet đầu tiên
        var rows = worksheet.RowsUsed().Skip(1);  // Bỏ header

        foreach (var row in rows)
        {
            var cauHoi = new CauHoi
            {
                NoiDung = row.Cell(1).GetValue<string>(),
                DapAnA = row.Cell(2).GetValue<string>(),
                DapAnB = row.Cell(3).GetValue<string>(),
                DapAnC = row.Cell(4).GetValue<string>(),
                DapAnD = row.Cell(5).GetValue<string>(),
                DapAnDung = row.Cell(6).GetValue<string>(),
                ChuDeId = row.Cell(7).GetValue<int>()
            };
            _context.CauHois.Add(cauHoi);
        }
        await _context.SaveChangesAsync();
        return Ok("Import thành công.");
    }
}