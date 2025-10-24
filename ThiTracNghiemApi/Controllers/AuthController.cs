using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Dtos.Auth;
using ThiTracNghiemApi.Dtos.Users;
using ThiTracNghiemApi.Extensions;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IConfiguration _config;

    public AuthController(UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager, IConfiguration config)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _config = config;
    }

    [HttpPost("register")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        request.UserName = request.UserName.Trim();
        request.Email = request.Email.Trim();
        request.FullName = request.FullName.Trim();

        if (await _userManager.Users.AnyAsync(u => u.UserName == request.UserName))
        {
            return Conflict("Tên đăng nhập đã tồn tại.");
        }

        if (await _userManager.Users.AnyAsync(u => u.Email == request.Email))
        {
            return Conflict("Email đã được sử dụng.");
        }

        var user = new ApplicationUser
        {
            UserName = request.UserName,
            Email = request.Email,
            FullName = request.FullName,
            NgaySinh = request.NgaySinh,
            GioiTinh = request.GioiTinh,
            AvatarUrl = request.AvatarUrl,
            PhoneNumber = request.SoDienThoai,
            SoDienThoai = request.SoDienThoai
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors)
            {
                ModelState.AddModelError(error.Code, error.Description);
            }
            return ValidationProblem(ModelState);
        }

        await _userManager.AddToRoleAsync(user, "User");

        var response = await BuildAuthResponseAsync(user);
        return Ok(response);
    }

    [HttpPost("login")]
    [ProducesResponseType(StatusCodes.Status200OK, Type = typeof(object))]  // Trả về { Token, UserId, Roles }
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var user = await _userManager.FindByNameAsync(request.UserName);
        if (user == null)
        {
            return Unauthorized("Thông tin đăng nhập không hợp lệ.");
        }

        if (user.TrangThaiKhoa || await _userManager.IsLockedOutAsync(user))
        {
            return Forbid("Tài khoản đã bị khóa, liên hệ quản trị viên.");
        }

        if (!await _userManager.CheckPasswordAsync(user, request.Password))
        {
            return Unauthorized("Thông tin đăng nhập không hợp lệ.");
        }

        await _signInManager.SignInAsync(user, false);

        var response = await BuildAuthResponseAsync(user);
        return Ok(response);
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> GetCurrentUser()
    {
        var user = await GetCurrentUserEntityAsync();
        if (user == null)
        {
            return NotFound();
        }

        var roles = await _userManager.GetRolesAsync(user);
    return Ok(user.ToDto(roles));
    }

    [Authorize]
    [HttpPut("me")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var user = await GetCurrentUserEntityAsync();
        if (user == null)
        {
            return NotFound();
        }

        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.Email) && !string.Equals(user.Email, request.Email, StringComparison.OrdinalIgnoreCase))
        {
            if (await _userManager.Users.AnyAsync(u => u.Email == request.Email && u.Id != user.Id))
            {
                return Conflict("Email đã được sử dụng bởi tài khoản khác.");
            }
            user.Email = request.Email;
            user.UserName ??= request.Email;
        }

        if (request.SoDienThoai != null)
        {
            var normalizedPhone = request.SoDienThoai.Trim();
            if (string.IsNullOrEmpty(normalizedPhone))
            {
                user.PhoneNumber = null;
                user.SoDienThoai = null;
            }
            else
            {
                user.PhoneNumber = normalizedPhone;
                user.SoDienThoai = normalizedPhone;
            }
        }

        user.NgaySinh = request.NgaySinh;
        user.GioiTinh = request.GioiTinh;
        user.AvatarUrl = request.AvatarUrl;

        var updateResult = await _userManager.UpdateAsync(user);
        if (!updateResult.Succeeded)
        {
            foreach (var error in updateResult.Errors)
            {
                ModelState.AddModelError(error.Code, error.Description);
            }
            return ValidationProblem(ModelState);
        }

    var roles = await _userManager.GetRolesAsync(user);
    return Ok(user.ToDto(roles));
    }

    [Authorize]
    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var user = await GetCurrentUserEntityAsync();
        if (user == null)
        {
            return NotFound();
        }

        var changeResult = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        if (!changeResult.Succeeded)
        {
            foreach (var error in changeResult.Errors)
            {
                ModelState.AddModelError(error.Code, error.Description);
            }
            return ValidationProblem(ModelState);
        }

        return NoContent();
    }

    private async Task<ApplicationUser?> GetCurrentUserEntityAsync()
    {
        var identifier = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? User.FindFirstValue("username")
            ?? User.FindFirstValue(ClaimTypes.Email);

        if (string.IsNullOrEmpty(identifier))
        {
            return null;
        }

        var user = await _userManager.FindByIdAsync(identifier);
        if (user != null)
        {
            return user;
        }

        user = await _userManager.FindByNameAsync(identifier);
        if (user != null)
        {
            return user;
        }

        if (identifier.Contains("@", StringComparison.Ordinal))
        {
            user = await _userManager.FindByEmailAsync(identifier);
        }

        return user;
    }

    private async Task<AuthResponseDto> BuildAuthResponseAsync(ApplicationUser user)
    {
        var roles = await _userManager.GetRolesAsync(user);
        var token = GenerateJwtToken(user, roles);

        return new AuthResponseDto
        {
            Token = token.Token,
            ExpiresAt = token.Expires,
            User = user.ToDto(roles)
        };
    }

    private (string Token, DateTime Expires) GenerateJwtToken(ApplicationUser user, IList<string> roles)
    {
        var claims = new List<Claim>
           {
               new Claim(JwtRegisteredClaimNames.Sub, user.Id),
               new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
               new Claim(ClaimTypes.NameIdentifier, user.Id),
               new Claim(ClaimTypes.Name, user.FullName ?? string.Empty),
               new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty)
           };
        if (!string.IsNullOrWhiteSpace(user.UserName))
        {
            claims.Add(new Claim("username", user.UserName));
        }
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var jwtKey = _config["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key is not configured.");
        var jwtIssuer = _config["Jwt:Issuer"] ?? throw new InvalidOperationException("Jwt:Issuer is not configured.");
        var jwtAudience = _config["Jwt:Audience"] ?? throw new InvalidOperationException("Jwt:Audience is not configured.");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddHours(2);
        var token = new JwtSecurityToken(
            issuer: jwtIssuer,
            audience: jwtAudience,
            claims: claims,
            expires: expires,
            signingCredentials: creds);
        return (new JwtSecurityTokenHandler().WriteToken(token), expires);
    }

}
