class ChuDe {
  final int id;
  final String tenChuDe;
  final String? moTa;

  const ChuDe({required this.id, required this.tenChuDe, this.moTa});

  factory ChuDe.fromJson(Map<String, dynamic> json) {
    return ChuDe(
      id: json['id'] as int,
      tenChuDe: json['tenChuDe'] as String? ?? '',
      moTa: json['moTa'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'tenChuDe': tenChuDe, 'moTa': moTa};
  }
}
