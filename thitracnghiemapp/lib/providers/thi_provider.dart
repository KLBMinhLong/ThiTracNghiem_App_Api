import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/quiz_session.dart';
import '../services/thi_service.dart';

class ThiProvider extends ChangeNotifier {
  final ThiService _service;

  ThiProvider(this._service);

  QuizSession? _currentSession;
  SubmitThiResult? _submitResult;
  bool _isLoading = false;
  String? _error;

  QuizSession? get currentSession => _currentSession;
  SubmitThiResult? get submitResult => _submitResult;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> startThi(int deThiId) async {
    _isLoading = true;
    _error = null;
    _submitResult = null;
    notifyListeners();

    try {
      _currentSession = await _service.startThi(deThiId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDapAn({
    required int cauHoiId,
    required String dapAnChon,
  }) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    try {
      await _service.updateDapAn(
        ketQuaThiId: session.ketQuaThiId,
        cauHoiId: cauHoiId,
        dapAnChon: dapAnChon,
      );
      _currentSession = session.copyWithUpdatedAnswer(
        cauHoiId: cauHoiId,
        dapAnChon: dapAnChon,
      );
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
      notifyListeners();
    }
  }

  Future<void> submitThi() async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _submitResult = await _service.submitThi(session.ketQuaThiId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentSession = null;
    _submitResult = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
