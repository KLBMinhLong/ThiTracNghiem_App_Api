using System;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Microsoft.Extensions.Configuration;
using ThiTracNghiemApi;
using ThiTracNghiemApi.Options;
using ThiTracNghiemApi.Services;
var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

builder.Services.Configure<SmtpOptions>(options =>
{
    builder.Configuration.GetSection("Smtp").Bind(options);
    var configUser = builder.Configuration["SMTP_EMAIL"]?.Trim();
    var configPassword = builder.Configuration["SMTP_PASSWORD"]?.Trim();
    var envUser = Environment.GetEnvironmentVariable("SMTP_EMAIL")?.Trim();
    var envPassword = Environment.GetEnvironmentVariable("SMTP_PASSWORD")?.Trim();

    if (string.IsNullOrWhiteSpace(options.User))
    {
        options.User = !string.IsNullOrWhiteSpace(configUser) ? configUser : envUser;
    }

    if (string.IsNullOrWhiteSpace(options.Password))
    {
        options.Password = !string.IsNullOrWhiteSpace(configPassword) ? configPassword : envPassword;
    }

    if (!string.IsNullOrEmpty(options.Password))
    {
        options.Password = options.Password.Replace(" ", string.Empty);
    }

    if (string.IsNullOrWhiteSpace(options.FromEmail))
    {
        options.FromEmail = options.User;
    }
    if (string.IsNullOrWhiteSpace(options.Host))
    {
        options.Host = "smtp.gmail.com";
    }
    if (options.Port == 0)
    {
        options.Port = 587;
    }
});

builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();

builder.Services.Configure<IdentityOptions>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.AllowedForNewUsers = true;
});

// Cấu hình Authentication với JWT
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    var jwtSection = builder.Configuration.GetSection("Jwt");
    var jwtKey = jwtSection["Key"] ?? throw new InvalidOperationException("Jwt:Key is not configured.");
    var jwtIssuer = jwtSection["Issuer"] ?? throw new InvalidOperationException("Jwt:Issuer is not configured.");
    var jwtAudience = jwtSection["Audience"] ?? throw new InvalidOperationException("Jwt:Audience is not configured.");

    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});
// Cấu hình Authorization
builder.Services.AddAuthorization();
// Add controllers and endpoints explorer so Swagger and MVC services are registered
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddEndpointsApiExplorer();
// Thêm CORS để Flutter app có thể gọi API (từ localhost hoặc domain khác)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Thêm Swagger
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ThiTracNghiem API",
        Version = "v1",
        Description = "API cho ứng dụng thi trắc nghiệm Flutter"
    });
    // Thêm JWT Bearer token support trong Swagger UI
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Description = "Nhập token JWT (không có 'Bearer ')",
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }

      });
});
var app = builder.Build();

// Sử dụng CORS
app.UseCors("AllowAll");
// Sử dụng Authentication và Authorization
app.UseAuthentication();
app.UseAuthorization();
// Sử dụng Swagger
  app.UseSwagger();
  app.UseSwaggerUI(c =>
  {
      c.SwaggerEndpoint("/swagger/v1/swagger.json", "ThiTracNghiem API v1");
      c.RoutePrefix = string.Empty;  // Truy cập Swagger tại root URL (e.g., https://localhost:5001/)
  });

app.UseHttpsRedirection();

app.MapControllers();

app.Run();

