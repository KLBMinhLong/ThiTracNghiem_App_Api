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

        public UsersController(UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager)
        {
            _userManager = userManager;
            _roleManager = roleManager;
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
    }
}
