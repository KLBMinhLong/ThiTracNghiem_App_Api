using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Logging;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Dtos.Auth;
using ThiTracNghiemApi.Dtos.Users;
using ThiTracNghiemApi.Extensions;
using ThiTracNghiemApi.Services;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IConfiguration _config;
    private readonly IEmailSender _emailSender;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        IConfiguration config,
        IEmailSender emailSender,
        ILogger<AuthController> logger)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _config = config;
        _emailSender = emailSender;
        _logger = logger;
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

    [AllowAnonymous]
    [HttpPost("forgot-password")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var email = request.Email.Trim();
        var user = await _userManager.FindByEmailAsync(email);
        if (user == null)
        {
            // Trả về accepted để tránh lộ thông tin tài khoản.
            return Accepted(new { message = "Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi." });
        }

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        var encodedToken = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(token));
        var resetBaseUrl = _config["Frontend:ResetPasswordUrl"];

        var builder = new StringBuilder();
        builder.AppendLine($"Xin chào {user.FullName ?? user.UserName ?? email},");
        builder.AppendLine();
        builder.AppendLine("Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản Thi Trắc Nghiệm.");
        if (!string.IsNullOrWhiteSpace(resetBaseUrl))
        {
            var resetLink = string.Concat(
                resetBaseUrl,
                resetBaseUrl.Contains('?') ? "&" : "?",
                "email=",
                Uri.EscapeDataString(email),
                "&token=",
                encodedToken);
            builder.AppendLine("Vui lòng nhấp vào liên kết dưới đây hoặc sao chép vào trình duyệt để tiếp tục:");
            builder.AppendLine(resetLink);
        }
        else
        {
            builder.AppendLine("Sử dụng mã đặt lại mật khẩu sau trong ứng dụng:");
            builder.AppendLine(encodedToken);
        }
        builder.AppendLine();
        builder.AppendLine("Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email này.");
        builder.AppendLine();
        builder.AppendLine("Trân trọng,");
        builder.AppendLine("Thi Trắc Nghiệm Team");

        try
        {
            await _emailSender.SendEmailAsync(
                email,
                "Thi Trắc Nghiệm - Đặt lại mật khẩu",
                builder.ToString());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send forgot password email to {Email}", email);
            return StatusCode(
                StatusCodes.Status500InternalServerError,
                "Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại sau.");
        }

        return Accepted(new { message = "Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi." });
    }

    [AllowAnonymous]
    [HttpPost("reset-password")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        var email = request.Email.Trim();
        var user = await _userManager.FindByEmailAsync(email);
        if (user == null)
        {
            return BadRequest("Không tìm thấy tài khoản với email đã cung cấp.");
        }

        string decodedToken;
        try
        {
            var tokenBytes = WebEncoders.Base64UrlDecode(request.Token);
            decodedToken = Encoding.UTF8.GetString(tokenBytes);
        }
        catch (FormatException)
        {
            return BadRequest("Token đặt lại mật khẩu không hợp lệ.");
        }

        var result = await _userManager.ResetPasswordAsync(user, decodedToken, request.NewPassword);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors)
            {
                ModelState.AddModelError(error.Code, error.Description);
            }
            return ValidationProblem(ModelState);
        }

        return Ok("Đã đặt lại mật khẩu thành công.");
    }

    [AllowAnonymous]
    [HttpPost("login/google")]
    [ProducesResponseType(StatusCodes.Status200OK, Type = typeof(object))]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> LoginWithGoogle([FromBody] GoogleLoginRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        if (string.IsNullOrWhiteSpace(request.IdToken))
        {
            return BadRequest("Token Google không hợp lệ.");
        }

        var audiences = new HashSet<string>(StringComparer.Ordinal);

        void AddAudiences(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return;
            }

            foreach (var part in value.Split(new[] { ';', ',', ' ' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                audiences.Add(part);
            }
        }

        AddAudiences(_config["Google:ClientId"]);
        AddAudiences(Environment.GetEnvironmentVariable("GOOGLE_CLIENT_ID"));
        AddAudiences(Environment.GetEnvironmentVariable("GOOGLE__CLIENTID"));
        AddAudiences(_config["Google:AllowedAudiences"]);
        AddAudiences(_config["Google:AndroidClientId"]);
        AddAudiences(Environment.GetEnvironmentVariable("GOOGLE_ANDROID_CLIENT_ID"));
        AddAudiences(Environment.GetEnvironmentVariable("GOOGLE__ANDROIDCLIENTID"));

        if (audiences.Count == 0)
        {
            _logger.LogError("Google client id configuration does not contain any valid client ids.");
            return StatusCode(StatusCodes.Status500InternalServerError, "Máy chủ chưa cấu hình đăng nhập Google.");
        }

        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(
                request.IdToken,
                new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = audiences.ToArray()
                });
        }
        catch (InvalidJwtException ex)
        {
            _logger.LogWarning(ex, "Google ID token validation failed.");
            return Unauthorized("Token Google không hợp lệ.");
        }

        if (string.IsNullOrWhiteSpace(payload.Email))
        {
            return BadRequest("Không tìm thấy email từ tài khoản Google.");
        }

        var user = await _userManager.FindByEmailAsync(payload.Email);
        if (user == null)
        {
            user = new ApplicationUser
            {
                UserName = payload.Email,
                Email = payload.Email,
                EmailConfirmed = true,
                FullName = payload.Name ?? payload.Email,
                AvatarUrl = payload.Picture,
            };

            var createResult = await _userManager.CreateAsync(user);
            if (!createResult.Succeeded)
            {
                foreach (var error in createResult.Errors)
                {
                    ModelState.AddModelError(error.Code, error.Description);
                }
                return ValidationProblem(ModelState);
            }
        }
        else
        {
            var updated = false;
            if (!user.EmailConfirmed)
            {
                user.EmailConfirmed = true;
                updated = true;
            }
            if (!string.IsNullOrWhiteSpace(payload.Name) && !string.Equals(user.FullName, payload.Name, StringComparison.Ordinal))
            {
                user.FullName = payload.Name;
                updated = true;
            }
            if (!string.IsNullOrWhiteSpace(payload.Picture) && !string.Equals(user.AvatarUrl, payload.Picture, StringComparison.Ordinal))
            {
                user.AvatarUrl = payload.Picture;
                updated = true;
            }
            if (updated)
            {
                await _userManager.UpdateAsync(user);
            }
        }

        var loginInfo = new UserLoginInfo("Google", payload.Subject, "Google");
        var existingLogin = await _userManager.FindByLoginAsync(loginInfo.LoginProvider, loginInfo.ProviderKey);
        if (existingLogin == null)
        {
            var addLoginResult = await _userManager.AddLoginAsync(user, loginInfo);
            if (!addLoginResult.Succeeded)
            {
                _logger.LogWarning("Failed to link Google login for user {Email}", user.Email);
            }
        }

        await _signInManager.SignInAsync(user, isPersistent: false);

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

        var identifier = request.UserName.Trim();
        var user = await _userManager.FindByNameAsync(identifier);

        if (user == null && identifier.Contains("@", StringComparison.Ordinal))
        {
            user = await _userManager.FindByEmailAsync(identifier);
        }

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
