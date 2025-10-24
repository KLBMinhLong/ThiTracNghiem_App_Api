import 'cau_hoi.dart';

class ChiTietKetQuaThi {
  final int cauHoiId;
  final String noiDung;
  final String? hinhAnh;
  final String? amThanh;
  final String dapAnA;
  final String dapAnB;
  final String? dapAnC;
  final String? dapAnD;
  final String? dapAnChon;
  final String dapAnDung;
  final bool? dungHaySai;

  const ChiTietKetQuaThi({
    required this.cauHoiId,
    required this.noiDung,
    this.hinhAnh,
    this.amThanh,
    required this.dapAnA,
    required this.dapAnB,
    this.dapAnC,
    this.dapAnD,
    this.dapAnChon,
    required this.dapAnDung,
    this.dungHaySai,
  });

  factory ChiTietKetQuaThi.fromJson(Map<String, dynamic> json) {
    return ChiTietKetQuaThi(
      cauHoiId: json['cauHoiId'] as int? ?? json['cauHoi']?['id'] as int? ?? 0,
      noiDung:
          json['noiDung'] as String? ??
          json['cauHoi']?['noiDung'] as String? ??
          '',
      hinhAnh:
          json['hinhAnh'] as String? ?? json['cauHoi']?['hinhAnh'] as String?,
      amThanh:
          json['amThanh'] as String? ?? json['cauHoi']?['amThanh'] as String?,
      dapAnA:
          json['dapAnA'] as String? ??
          json['cauHoi']?['dapAnA'] as String? ??
          '',
      dapAnB:
          json['dapAnB'] as String? ??
          json['cauHoi']?['dapAnB'] as String? ??
          '',
      dapAnC: json['dapAnC'] as String? ?? json['cauHoi']?['dapAnC'] as String?,
      dapAnD: json['dapAnD'] as String? ?? json['cauHoi']?['dapAnD'] as String?,
      dapAnChon: json['dapAnChon'] as String?,
      dapAnDung:
          json['dapAnDung'] as String? ??
          json['cauHoi']?['dapAnDung'] as String? ??
          '',
      dungHaySai: json['dungHaySai'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cauHoiId': cauHoiId,
      'noiDung': noiDung,
      'hinhAnh': hinhAnh,
      'amThanh': amThanh,
      'dapAnA': dapAnA,
      'dapAnB': dapAnB,
      'dapAnC': dapAnC,
      'dapAnD': dapAnD,
      'dapAnChon': dapAnChon,
      'dapAnDung': dapAnDung,
      'dungHaySai': dungHaySai,
    };
  }

  CauHoi toCauHoi({String? dapAnChonOverride}) {
    return CauHoi(
      id: cauHoiId,
      noiDung: noiDung,
      hinhAnh: hinhAnh,
      amThanh: amThanh,
      dapAnA: dapAnA,
      dapAnB: dapAnB,
      dapAnC: dapAnC,
      dapAnD: dapAnD,
      dapAnDung: dapAnDung,
      chuDeId: 0,
    );
  }
}
