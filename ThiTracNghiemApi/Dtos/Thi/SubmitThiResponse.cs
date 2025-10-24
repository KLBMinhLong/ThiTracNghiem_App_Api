using System.Collections.Generic;

namespace ThiTracNghiemApi.Dtos.Thi
{
    public class SubmitThiResponse
    {
        public double Diem { get; set; }
        public int SoCauDung { get; set; }
        public int TongSoCau { get; set; }
        public IEnumerable<ChiTietKetQuaThiDto> ChiTiet { get; set; } = new List<ChiTietKetQuaThiDto>();
    }

    public class ChiTietKetQuaThiDto
    {
        public int CauHoiId { get; set; }
        public string NoiDung { get; set; } = string.Empty;
        public string? HinhAnh { get; set; }
        public string? AmThanh { get; set; }
        public string DapAnA { get; set; } = string.Empty;
        public string DapAnB { get; set; } = string.Empty;
        public string? DapAnC { get; set; }
        public string? DapAnD { get; set; }
        public string? DapAnChon { get; set; }
        public string DapAnDung { get; set; } = string.Empty;
        public bool? DungHaySai { get; set; }
    }
}
