using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ThiTracNghiemApi.Dtos.Users
{
    public class UpdateUserRolesRequest
    {
        [Required]
        public IEnumerable<string> Roles { get; set; } = new List<string>();
    }
}
