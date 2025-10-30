using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Dtos.Users;
using ThiTracNghiemApi.Extensions;

namespace ThiTracNghiemApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class UsersController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly ApplicationDbContext _context;

        public UsersController(UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager, ApplicationDbContext context)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetUsers([FromQuery] string? keyword, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _userManager.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                keyword = $"%{keyword.Trim()}%";
                query = query.Where(u =>
                    (u.UserName != null && EF.Functions.Like(u.UserName, keyword)) ||
                    (u.Email != null && EF.Functions.Like(u.Email, keyword)) ||
                    EF.Functions.Like(u.FullName, keyword));
            }

            var total = await query.CountAsync();
            var users = await query
                .OrderByDescending(u => u.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userDtos = new System.Collections.Generic.List<UserDto>();
            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                userDtos.Add(user.ToDto(roles));
            }

            return Ok(new { total, items = userDtos });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUser(string id)
        {
            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
            {
                return NotFound();
            }

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(user.ToDto(roles));
        }

        [HttpPut("{id}/roles")]
        public async Task<IActionResult> UpdateRoles(string id, [FromBody] UpdateUserRolesRequest request)
        {
            if (!ModelState.IsValid)
            {
                return ValidationProblem(ModelState);
            }

            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
            {
                return NotFound();
            }

            var validRoles = request.Roles.Select(r => r.Trim()).Where(r => !string.IsNullOrWhiteSpace(r)).Distinct(StringComparer.OrdinalIgnoreCase).ToList();
            foreach (var role in validRoles)
            {
                if (!await _roleManager.RoleExistsAsync(role))
                {
                    return BadRequest($"Role '{role}' không tồn tại.");
                }
            }

            var existingRoles = await _userManager.GetRolesAsync(user);
            var removeResult = await _userManager.RemoveFromRolesAsync(user, existingRoles);
            if (!removeResult.Succeeded)
            {
                return BadRequest(removeResult.Errors);
            }

            var addResult = await _userManager.AddToRolesAsync(user, validRoles);
            if (!addResult.Succeeded)
            {
                return BadRequest(addResult.Errors);
            }

            var updatedRoles = await _userManager.GetRolesAsync(user);
            return Ok(user.ToDto(updatedRoles));
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateUserStatusRequest request)
        {
            if (!ModelState.IsValid)
            {
                return ValidationProblem(ModelState);
            }

            var user = await _userManager.FindByIdAsync(id);
            if (user == null)
            {
                return NotFound();
            }

            user.TrangThaiKhoa = request.TrangThaiKhoa;
            if (request.TrangThaiKhoa)
            {
                await _userManager.SetLockoutEnabledAsync(user, true);
                await _userManager.SetLockoutEndDateAsync(user, DateTimeOffset.MaxValue);
            }
            else
            {
                await _userManager.SetLockoutEndDateAsync(user, null);
                await _userManager.SetLockoutEnabledAsync(user, false);
            }

            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
            {
                return BadRequest(result.Errors);
            }

            var roles = await _userManager.GetRolesAsync(user);
            return Ok(user.ToDto(roles));
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            if (!ModelState.IsValid)
            {
                return ValidationProblem(ModelState);
            }

            var existingByName = await _userManager.FindByNameAsync(request.UserName);
            if (existingByName != null)
            {
                return BadRequest($"Tên đăng nhập '{request.UserName}' đã tồn tại.");
            }

            if (!string.IsNullOrWhiteSpace(request.Email))
            {
                var existingByEmail = await _userManager.FindByEmailAsync(request.Email);
                if (existingByEmail != null)
                {
                    return BadRequest($"Email '{request.Email}' đã được sử dụng.");
                }
            }

            var user = new ApplicationUser
            {
                UserName = request.UserName.Trim(),
                Email = request.Email?.Trim(),
                FullName = request.FullName?.Trim() ?? string.Empty,
                EmailConfirmed = true
            };

            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
            {
                return BadRequest(createResult.Errors);
            }

            var roles = (request.Roles ?? new List<string> { "User" })
                .Where(r => !string.IsNullOrWhiteSpace(r))
                .Select(r => r.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();
            foreach (var role in roles)
            {
                if (!await _roleManager.RoleExistsAsync(role))
                {
                    return BadRequest($"Role '{role}' không tồn tại.");
                }
            }

            if (roles.Count > 0)
            {
                var addRoleResult = await _userManager.AddToRolesAsync(user, roles);
                if (!addRoleResult.Succeeded)
                {
                    return BadRequest(addRoleResult.Errors);
                }
            }

            var finalRoles = await _userManager.GetRolesAsync(user);
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user.ToDto(finalRoles));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _userManager.Users.FirstOrDefaultAsync(u => u.Id == id);
            if (user == null)
            {
                return NotFound();
            }

            // Không cho tự xoá nếu là admin duy nhất (tuỳ chọn). Bỏ qua để đơn giản.

            // Nếu có lịch sử thi hoặc liên hệ -> không xoá, trả thông báo rõ ràng
            var hasHistories = await _context.KetQuaThis.AsNoTracking().AnyAsync(k => k.TaiKhoanId == id);
            var hasContacts = await _context.LienHes.AsNoTracking().AnyAsync(l => l.TaiKhoanId == id);
            if (hasHistories || hasContacts)
            {
                return BadRequest("Không thể xoá tài khoản vì có lịch sử thi hoặc liên hệ liên quan.");
            }

            // Xoá bình luận của người dùng trước khi xoá tài khoản
            await _context.BinhLuans.Where(b => b.TaiKhoanId == id).ExecuteDeleteAsync();

            // Xoá tài khoản
            var result = await _userManager.DeleteAsync(user);
            if (!result.Succeeded)
            {
                return BadRequest(result.Errors);
            }

            return NoContent();
        }
    }
}
