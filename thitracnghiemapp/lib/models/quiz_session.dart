import 'chi_tiet_ket_qua_thi.dart';

class QuizQuestion {
  final int id;
  final String noiDung;
  final String? hinhAnh;
  final String? amThanh;
  final String dapAnA;
  final String dapAnB;
  final String? dapAnC;
  final String? dapAnD;
  final String? selectedAnswer;

  const QuizQuestion({
    required this.id,
    required this.noiDung,
    this.hinhAnh,
    this.amThanh,
    required this.dapAnA,
    required this.dapAnB,
    this.dapAnC,
    this.dapAnD,
    this.selectedAnswer,
  });

  QuizQuestion copyWith({String? selectedAnswer}) {
    return QuizQuestion(
      id: id,
      noiDung: noiDung,
      hinhAnh: hinhAnh,
      amThanh: amThanh,
      dapAnA: dapAnA,
      dapAnB: dapAnB,
      dapAnC: dapAnC,
      dapAnD: dapAnD,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    );
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int,
      noiDung: json['noiDung'] as String? ?? '',
      hinhAnh: json['hinhAnh'] as String?,
      amThanh: json['amThanh'] as String?,
      dapAnA: json['dapAnA'] as String? ?? '',
      dapAnB: json['dapAnB'] as String? ?? '',
      dapAnC: json['dapAnC'] as String?,
      dapAnD: json['dapAnD'] as String?,
      selectedAnswer: json['dapAnChon'] as String?,
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
      'dapAnChon': selectedAnswer,
    };
  }
}

class QuizSession {
  final int ketQuaThiId;
  final int deThiId;
  final String tenDeThi;
  final int soCauHoi;
  final int thoiGianThi;
  final DateTime ngayBatDau;
  final List<QuizQuestion> cauHois;

  const QuizSession({
    required this.ketQuaThiId,
    required this.deThiId,
    required this.tenDeThi,
    required this.soCauHoi,
    required this.thoiGianThi,
    required this.ngayBatDau,
    required this.cauHois,
  });

  QuizSession copyWith({
    int? ketQuaThiId,
    int? deThiId,
    String? tenDeThi,
    int? soCauHoi,
    int? thoiGianThi,
    DateTime? ngayBatDau,
    List<QuizQuestion>? cauHois,
  }) {
    return QuizSession(
      ketQuaThiId: ketQuaThiId ?? this.ketQuaThiId,
      deThiId: deThiId ?? this.deThiId,
      tenDeThi: tenDeThi ?? this.tenDeThi,
      soCauHoi: soCauHoi ?? this.soCauHoi,
      thoiGianThi: thoiGianThi ?? this.thoiGianThi,
      ngayBatDau: ngayBatDau ?? this.ngayBatDau,
      cauHois: cauHois ?? this.cauHois,
    );
  }

  QuizSession copyWithUpdatedAnswer({
    required int cauHoiId,
    required String dapAnChon,
  }) {
    final updatedQuestions = cauHois
        .map(
          (question) => question.id == cauHoiId
              ? question.copyWith(selectedAnswer: dapAnChon)
              : question,
        )
        .toList(growable: false);
    return copyWith(cauHois: updatedQuestions);
  }

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      ketQuaThiId: json['ketQuaThiId'] as int,
      deThiId: json['deThiId'] as int,
      tenDeThi: json['tenDeThi'] as String? ?? '',
      soCauHoi: json['soCauHoi'] as int? ?? 0,
      thoiGianThi: json['thoiGianThi'] as int? ?? 0,
      ngayBatDau: _parseDate(json['ngayBatDau']),
      cauHois: (json['cauHois'] as List<dynamic>? ?? const [])
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class SubmitThiResult {
  final double diem;
  final int soCauDung;
  final int tongSoCau;
  final List<ChiTietKetQuaThi> chiTiet;

  const SubmitThiResult({
    required this.diem,
    required this.soCauDung,
    required this.tongSoCau,
    required this.chiTiet,
  });

  factory SubmitThiResult.fromJson(Map<String, dynamic> json) {
    final chiTiet = (json['chiTiet'] as List<dynamic>? ?? const [])
        .map((item) => ChiTietKetQuaThi.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return SubmitThiResult(
      diem: (json['diem'] as num?)?.toDouble() ?? 0,
      soCauDung: json['soCauDung'] as int? ?? 0,
      tongSoCau: json['tongSoCau'] as int? ?? chiTiet.length,
      chiTiet: chiTiet,
    );
  }
}
