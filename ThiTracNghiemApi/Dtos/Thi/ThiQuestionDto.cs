namespace ThiTracNghiemApi.Dtos.Thi
{
    public class ThiQuestionDto
    {
        public int Id { get; set; }
        public string NoiDung { get; set; } = string.Empty;
        public string? HinhAnh { get; set; }
        public string? AmThanh { get; set; }
        public string DapAnA { get; set; } = string.Empty;
        public string DapAnB { get; set; } = string.Empty;
        public string? DapAnC { get; set; }
        public string? DapAnD { get; set; }
    }
}
