import 'chu_de.dart';

class CauHoi {
  final int id;
  final String noiDung;
  final String? hinhAnh;
  final String? amThanh;
  final String dapAnA;
  final String dapAnB;
  final String? dapAnC;
  final String? dapAnD;
  final String dapAnDung;
  final int chuDeId;
  final ChuDe? chuDe;

  const CauHoi({
    required this.id,
    required this.noiDung,
    this.hinhAnh,
    this.amThanh,
    required this.dapAnA,
    required this.dapAnB,
    this.dapAnC,
    this.dapAnD,
    required this.dapAnDung,
    required this.chuDeId,
    this.chuDe,
  });

  factory CauHoi.fromJson(Map<String, dynamic> json) {
    return CauHoi(
      id: json['id'] as int,
      noiDung: json['noiDung'] as String? ?? '',
      hinhAnh: json['hinhAnh'] as String?,
      amThanh: json['amThanh'] as String?,
      dapAnA: json['dapAnA'] as String? ?? '',
      dapAnB: json['dapAnB'] as String? ?? '',
      dapAnC: json['dapAnC'] as String?,
      dapAnD: json['dapAnD'] as String?,
      dapAnDung: json['dapAnDung'] as String? ?? '',
      chuDeId: json['chuDeId'] as int? ?? 0,
      chuDe: json['chuDe'] is Map<String, dynamic>
          ? ChuDe.fromJson(json['chuDe'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noiDung': noiDung,
      'hinhAnh': hinhAnh,
      'amThanh': amThanh,
      'dapAnA': dapAnA,
      'dapAnB': dapAnB,
      'dapAnC': dapAnC,
      'dapAnD': dapAnD,
      'dapAnDung': dapAnDung,
      'chuDeId': chuDeId,
      if (chuDe != null) 'chuDe': chuDe!.toJson(),
    };
  }
}
