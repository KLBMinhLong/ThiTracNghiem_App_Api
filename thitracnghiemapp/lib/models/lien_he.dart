import 'user.dart';

class LienHe {
  final int id;
  final String taiKhoanId;
  final User? taiKhoan;
  final String tieuDe;
  final String noiDung;
  final DateTime ngayGui;

  const LienHe({
    required this.id,
    required this.taiKhoanId,
    this.taiKhoan,
    required this.tieuDe,
    required this.noiDung,
    required this.ngayGui,
  });

  factory LienHe.fromJson(Map<String, dynamic> json) {
    return LienHe(
      id: json['id'] as int,
      taiKhoanId: json['taiKhoanId'] as String? ?? '',
      taiKhoan: json['taiKhoan'] is Map<String, dynamic>
          ? User.fromJson(json['taiKhoan'] as Map<String, dynamic>)
          : null,
      tieuDe: json['tieuDe'] as String? ?? '',
      noiDung: json['noiDung'] as String? ?? '',
      ngayGui: _parseDate(json['ngayGui']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taiKhoanId': taiKhoanId,
      'tieuDe': tieuDe,
      'noiDung': noiDung,
      'ngayGui': ngayGui.toIso8601String(),
      if (taiKhoan != null) 'taiKhoan': taiKhoan!.toJson(),
    };
  }
}
