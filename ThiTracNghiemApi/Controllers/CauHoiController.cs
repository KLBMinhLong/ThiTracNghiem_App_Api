using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
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
    public async Task<IActionResult> GetCauHois([FromQuery] int page = 1, [FromQuery] int pageSize = 20, [FromQuery] int? topicId = null)
    {
        if (page < 1)
        {
            return BadRequest("Số trang phải lớn hơn hoặc bằng 1.");
        }

        if (pageSize < 1 || pageSize > 200)
        {
            return BadRequest("Số bản ghi mỗi trang phải nằm trong khoảng 1-200.");
        }

        var query = _context.CauHois
            .AsNoTracking()
            .Include(c => c.ChuDe)
            .OrderByDescending(c => c.Id)
            .AsQueryable();

        if (topicId.HasValue)
        {
            query = query.Where(c => c.ChuDeId == topicId.Value);
        }

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Ok(new
        {
            total,
            page,
            pageSize,
            items
        });
    }

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
    public async Task<IActionResult> ImportCauHois([FromForm] IFormFile file, [FromForm] int topicId)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest("File không hợp lệ.");
        }

        if (topicId <= 0)
        {
            return BadRequest("Vui lòng chọn chủ đề để import câu hỏi.");
        }

        if (!await _context.ChuDes.AnyAsync(c => c.Id == topicId))
        {
            return BadRequest("Chủ đề được chọn không tồn tại.");
        }

        if (!string.Equals(Path.GetExtension(file.FileName), ".xlsx", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest("Vui lòng chọn file Excel định dạng .xlsx.");
        }

        try
        {
            using var workbook = new XLWorkbook(file.OpenReadStream());
            var worksheet = workbook.Worksheet(1);
            var rows = worksheet.RowsUsed().Skip(1);

            var imported = 0;
            var errors = new List<string>();
            var rowNumber = 2;
            foreach (var row in rows)
            {
                var noiDung = row.Cell(1).GetValue<string>().Trim();
                if (string.IsNullOrWhiteSpace(noiDung))
                {
                    rowNumber++;
                    continue; // Bỏ qua dòng trống hoặc không hợp lệ
                }

                var dapAnA = row.Cell(2).GetValue<string>().Trim();
                var dapAnB = row.Cell(3).GetValue<string>().Trim();
                var dapAnC = row.Cell(4).GetValue<string>().Trim();
                var dapAnD = row.Cell(5).GetValue<string>().Trim();
                var dapAnDung = row.Cell(6).GetValue<string>().Trim();

                if (string.IsNullOrWhiteSpace(dapAnA) || string.IsNullOrWhiteSpace(dapAnB) || string.IsNullOrWhiteSpace(dapAnDung))
                {
                    errors.Add($"Dòng {rowNumber}: Thiếu đáp án bắt buộc hoặc đáp án đúng.");
                    rowNumber++;
                    continue;
                }

                var cauHoi = new CauHoi
                {
                    NoiDung = noiDung,
                    DapAnA = dapAnA,
                    DapAnB = dapAnB,
                    DapAnC = string.IsNullOrWhiteSpace(dapAnC) ? null : dapAnC,
                    DapAnD = string.IsNullOrWhiteSpace(dapAnD) ? null : dapAnD,
                    DapAnDung = dapAnDung,
                    ChuDeId = topicId,
                };

                _context.CauHois.Add(cauHoi);
                imported++;
                rowNumber++;
            }

            if (imported == 0)
            {
                var errorMessage = errors.Count > 0
                    ? string.Join(" ", errors)
                    : "File không có dữ liệu câu hỏi hợp lệ.";
                return BadRequest(errorMessage);
            }

            await _context.SaveChangesAsync();
            return Ok(new
            {
                message = $"Import thành công {imported} câu hỏi.",
                imported,
                skipped = errors
            });
        }
        catch (Exception ex)
        {
            return BadRequest($"Không thể import dữ liệu: {ex.Message}");
        }
    }
}