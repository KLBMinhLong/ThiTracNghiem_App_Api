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

  String? _lastFilterUserId;

  Future<void> fetchKetQuaThiList({int page = 1, String? onlyUserId}) async {
    _isLoading = true;
    _error = null;
    _lastFilterUserId = onlyUserId;
    notifyListeners();

    try {
      _ketQuaThiList = await _service.fetchKetQuaThis(page: page);
      if (onlyUserId != null) {
        final filtered = _ketQuaThiList!.items
            .where((item) {
              final ownerId = item.taiKhoan?.id ?? item.taiKhoanId;
              return ownerId == null || ownerId == onlyUserId;
            })
            .toList(growable: false);
        _ketQuaThiList = _ketQuaThiList!.copyWith(
          items: filtered,
          total: filtered.length,
        );
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refetchWithLastFilter() async {
    await fetchKetQuaThiList(
      page: _ketQuaThiList?.page ?? 1,
      onlyUserId: _lastFilterUserId,
    );
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

  Future<bool> deleteKetQuaThi(int id) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    var success = false;
    try {
      await _service.deleteKetQuaThi(id);
      if (_ketQuaThiList != null) {
        final filtered = _ketQuaThiList!.items
            .where((e) => e.id != id)
            .toList(growable: false);
        _ketQuaThiList = _ketQuaThiList!.copyWith(
          items: filtered,
          total: _ketQuaThiList!.total > 0 ? _ketQuaThiList!.total - 1 : 0,
        );
      }
      if (_selectedKetQuaThi?.id == id) {
        _selectedKetQuaThi = null;
      }
      success = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}
