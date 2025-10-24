using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using ThiTracNghiemApi;

namespace ThiTracNghiemApi.Extensions
{
    public static class ClaimsPrincipalExtensions
    {
        public static async Task<ApplicationUser?> ResolveUserAsync(this ClaimsPrincipal principal, ApplicationDbContext context)
        {
            if (principal == null)
            {
                return null;
            }

            var identifiers = new List<string>();

            void TryAdd(string? value)
            {
                if (!string.IsNullOrWhiteSpace(value) && !identifiers.Contains(value, StringComparer.OrdinalIgnoreCase))
                {
                    identifiers.Add(value);
                }
            }

            TryAdd(principal.FindFirstValue(ClaimTypes.NameIdentifier));
            TryAdd(principal.FindFirstValue(JwtRegisteredClaimNames.Sub));
            TryAdd(principal.FindFirstValue("username"));
            TryAdd(principal.FindFirstValue(ClaimTypes.Email));

            foreach (var candidate in identifiers)
            {
                var user = await context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.Id == candidate);
                if (user != null)
                {
                    return user;
                }
            }

            foreach (var candidate in identifiers)
            {
                if (string.IsNullOrWhiteSpace(candidate))
                {
                    continue;
                }

                var normalized = candidate.ToUpperInvariant();
                var user = await context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.NormalizedUserName == normalized);
                if (user != null)
                {
                    return user;
                }
            }

            foreach (var candidate in identifiers)
            {
                if (string.IsNullOrWhiteSpace(candidate))
                {
                    continue;
                }

                var normalized = candidate.ToUpperInvariant();
                var user = await context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.NormalizedEmail == normalized);
                if (user != null)
                {
                    return user;
                }
            }

            return null;
        }

        public static async Task<string?> ResolveUserIdAsync(this ClaimsPrincipal principal, ApplicationDbContext context)
        {
            var user = await ResolveUserAsync(principal, context);
            return user?.Id;
        }
    }
}
