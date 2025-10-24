import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/ket_qua_thi.dart';
import '../models/paginated_response.dart';
import '../services/ket_qua_thi_service.dart';

class KetQuaThiProvider extends ChangeNotifier {
  final KetQuaThiService _service;

  KetQuaThiProvider(this._service);

  PaginatedResponse<KetQuaThiSummary>? _ketQuaThiList;
  KetQuaThiDetail? _selectedKetQuaThi;
  bool _isLoading = false;
  String? _error;

  PaginatedResponse<KetQuaThiSummary>? get ketQuaThiList => _ketQuaThiList;
  KetQuaThiDetail? get selectedKetQuaThi => _selectedKetQuaThi;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchKetQuaThiList({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ketQuaThiList = await _service.fetchKetQuaThis(page: page);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchKetQuaThi(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedKetQuaThi = await _service.fetchKetQuaThi(id);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelected() {
    _selectedKetQuaThi = null;
    notifyListeners();
  }
}
