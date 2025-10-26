import 'chu_de.dart';

class DeThi {
  final int id;
  final String tenDeThi;
  final int chuDeId;
  final ChuDe? chuDe;
  final int soCauHoi;
  final int thoiGianThi;
  final String trangThai;
  final DateTime ngayTao;
  final bool allowMultipleAttempts;

  const DeThi({
    required this.id,
    required this.tenDeThi,
    required this.chuDeId,
    this.chuDe,
    required this.soCauHoi,
    required this.thoiGianThi,
    required this.trangThai,
    required this.ngayTao,
    required this.allowMultipleAttempts,
  });

  bool get isOpen => trangThai.toLowerCase() == 'mo';

  factory DeThi.fromJson(Map<String, dynamic> json) {
    return DeThi(
      id: _readInt(json['id']),
      tenDeThi: json['tenDeThi'] as String? ?? '',
      chuDeId: _readChuDeId(json),
      chuDe: json['chuDe'] is Map<String, dynamic>
          ? ChuDe.fromJson(json['chuDe'] as Map<String, dynamic>)
          : null,
      soCauHoi: json['soCauHoi'] as int? ?? 0,
      thoiGianThi: json['thoiGianThi'] as int? ?? 0,
      trangThai: json['trangThai'] as String? ?? '',
      ngayTao: _parseDate(json['ngayTao']),
      allowMultipleAttempts: json['allowMultipleAttempts'] as bool? ?? false,
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

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static int _readChuDeId(Map<String, dynamic> json) {
    final raw = json['chuDeId'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    final nested = json['chuDe'];
    if (nested is Map<String, dynamic>) {
      final nestedId = nested['id'];
      if (nestedId is int) {
        return nestedId;
      }
      if (nestedId is num) {
        return nestedId.toInt();
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenDeThi': tenDeThi,
      'chuDeId': chuDeId,
      'soCauHoi': soCauHoi,
      'thoiGianThi': thoiGianThi,
      'trangThai': trangThai,
      'ngayTao': ngayTao.toIso8601String(),
      'allowMultipleAttempts': allowMultipleAttempts,
      if (chuDe != null) 'chuDe': chuDe!.toJson(),
    };
  }
}
