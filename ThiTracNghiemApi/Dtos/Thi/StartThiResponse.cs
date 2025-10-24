using System;
using System.Collections.Generic;

namespace ThiTracNghiemApi.Dtos.Thi
{
    public class StartThiResponse
    {
        public int KetQuaThiId { get; set; }
        public int DeThiId { get; set; }
        public string TenDeThi { get; set; } = string.Empty;
        public int SoCauHoi { get; set; }
        public int ThoiGianThi { get; set; }
        public DateTime NgayBatDau { get; set; }
        public IEnumerable<ThiQuestionDto> CauHois { get; set; } = new List<ThiQuestionDto>();
    }
}
