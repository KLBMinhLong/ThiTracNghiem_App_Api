import 'chi_tiet_ket_qua_thi.dart';
import 'de_thi.dart';
import 'user.dart';

class KetQuaThiSummary {
  final int id;
  final double? diem;
  final int? soCauDung;
  final String trangThai;
  final DateTime ngayThi;
  final DateTime? ngayNopBai;
  final DeThi? deThi;
  final User? taiKhoan;
  final String? taiKhoanId;

  const KetQuaThiSummary({
    required this.id,
    this.diem,
    this.soCauDung,
    required this.trangThai,
    required this.ngayThi,
    this.ngayNopBai,
    this.deThi,
    this.taiKhoan,
    this.taiKhoanId,
  });

  bool get isCompleted =>
      trangThai.toLowerCase() == 'hoanthanh' ||
      trangThai.toLowerCase() == 'hoan thanh';

  factory KetQuaThiSummary.fromJson(Map<String, dynamic> json) {
    return KetQuaThiSummary(
      id: json['id'] as int,
      diem: (json['diem'] as num?)?.toDouble(),
      soCauDung: json['soCauDung'] as int?,
      trangThai: json['trangThai'] as String? ?? '',
      ngayThi: _parseDate(json['ngayThi']),
      ngayNopBai: _tryParseNullableDate(json['ngayNopBai']),
      deThi: json['deThi'] is Map<String, dynamic>
          ? DeThi.fromJson(json['deThi'] as Map<String, dynamic>)
          : null,
      taiKhoan: json['taiKhoan'] is Map<String, dynamic>
          ? User.fromJson(json['taiKhoan'] as Map<String, dynamic>)
          : null,
      taiKhoanId: json['taiKhoanId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diem': diem,
      'soCauDung': soCauDung,
      'trangThai': trangThai,
      'ngayThi': ngayThi.toIso8601String(),
      'ngayNopBai': ngayNopBai?.toIso8601String(),
      if (deThi != null) 'deThi': deThi!.toJson(),
      if (taiKhoan != null) 'taiKhoan': taiKhoan!.toJson(),
      if (taiKhoanId != null) 'taiKhoanId': taiKhoanId,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime? _tryParseNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class KetQuaThiDetail extends KetQuaThiSummary {
  final int tongSoCau;
  final List<ChiTietKetQuaThi> chiTiet;

  const KetQuaThiDetail({
    required super.id,
    super.diem,
    super.soCauDung,
    required super.trangThai,
    required super.ngayThi,
    super.ngayNopBai,
    super.deThi,
    super.taiKhoan,
    super.taiKhoanId,
    required this.tongSoCau,
    required this.chiTiet,
  });

  factory KetQuaThiDetail.fromJson(Map<String, dynamic> json) {
    final summary = KetQuaThiSummary.fromJson(json);
    final chiTietList = (json['chiTiet'] as List<dynamic>? ?? const [])
        .map((item) => ChiTietKetQuaThi.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final tongSoCau = json['tongSoCau'] as int? ?? chiTietList.length;
    return KetQuaThiDetail(
      id: summary.id,
      diem: summary.diem,
      soCauDung: summary.soCauDung,
      trangThai: summary.trangThai,
      ngayThi: summary.ngayThi,
      ngayNopBai: summary.ngayNopBai,
      deThi: summary.deThi,
      taiKhoan: summary.taiKhoan,
      taiKhoanId: summary.taiKhoanId,
      tongSoCau: tongSoCau,
      chiTiet: chiTietList,
    );
  }
}
