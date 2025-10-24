import 'de_thi.dart';
import 'user.dart';

class BinhLuan {
  final int id;
  final int deThiId;
  final DeThi? deThi;
  final String taiKhoanId;
  final User? taiKhoan;
  final String noiDung;
  final DateTime ngayTao;

  const BinhLuan({
    required this.id,
    required this.deThiId,
    this.deThi,
    required this.taiKhoanId,
    this.taiKhoan,
    required this.noiDung,
    required this.ngayTao,
  });

  factory BinhLuan.fromJson(Map<String, dynamic> json) {
    return BinhLuan(
      id: json['id'] as int,
      deThiId: json['deThiId'] as int? ?? 0,
      deThi: json['deThi'] is Map<String, dynamic>
          ? DeThi.fromJson(json['deThi'] as Map<String, dynamic>)
          : null,
      taiKhoanId: json['taiKhoanId'] as String? ?? '',
      taiKhoan: json['taiKhoan'] is Map<String, dynamic>
          ? User.fromJson(json['taiKhoan'] as Map<String, dynamic>)
          : null,
      noiDung: json['noiDung'] as String? ?? '',
      ngayTao: _parseDate(json['ngayTao']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deThiId': deThiId,
      'taiKhoanId': taiKhoanId,
      'noiDung': noiDung,
      'ngayTao': ngayTao.toIso8601String(),
      if (deThi != null) 'deThi': deThi!.toJson(),
      if (taiKhoan != null) 'taiKhoan': taiKhoan!.toJson(),
    };
  }

  BinhLuan copyWith({
    int? id,
    int? deThiId,
    DeThi? deThi,
    String? taiKhoanId,
    User? taiKhoan,
    String? noiDung,
    DateTime? ngayTao,
  }) {
    return BinhLuan(
      id: id ?? this.id,
      deThiId: deThiId ?? this.deThiId,
      deThi: deThi ?? this.deThi,
      taiKhoanId: taiKhoanId ?? this.taiKhoanId,
      taiKhoan: taiKhoan ?? this.taiKhoan,
      noiDung: noiDung ?? this.noiDung,
      ngayTao: ngayTao ?? this.ngayTao,
    );
  }
}
