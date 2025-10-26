import 'package:flutter/foundation.dart';

import '../models/de_thi.dart';
import '../models/paginated_response.dart';
import '../services/de_thi_service.dart';

class DeThiProvider extends ChangeNotifier {
  final DeThiService _service;

  DeThiProvider(this._service);

  List<DeThi> _openDeThis = const [];
  PaginatedResponse<DeThi>? _adminDeThis;
  bool _loadingOpen = false;
  bool _loadingAdmin = false;
  String? _error;

  List<DeThi> get openDeThis => _openDeThis;
  PaginatedResponse<DeThi>? get adminDeThis => _adminDeThis;
  bool get loadingOpen => _loadingOpen;
  bool get loadingAdmin => _loadingAdmin;
  String? get error => _error;

  Future<void> fetchOpenDeThis() async {
    _loadingOpen = true;
    _error = null;
    notifyListeners();
    try {
      _openDeThis = await _service.fetchOpenDeThis();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loadingOpen = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminDeThis({int page = 1, int pageSize = 20}) async {
    _loadingAdmin = true;
    _error = null;
    notifyListeners();
    try {
      _adminDeThis = await _service.fetchDeThis(page: page, pageSize: pageSize);
    } catch (error) {
      _error = error.toString();
    } finally {
      _loadingAdmin = false;
      notifyListeners();
    }
  }

  Future<DeThi?> createDeThi({
    required String tenDeThi,
    required int chuDeId,
    required int soCauHoi,
    required int thoiGianThi,
    String trangThai = 'Mo',
    bool allowMultipleAttempts = false,
  }) async {
    try {
      final result = await _service.createDeThi(
        tenDeThi: tenDeThi,
        chuDeId: chuDeId,
        soCauHoi: soCauHoi,
        thoiGianThi: thoiGianThi,
        trangThai: trangThai,
        allowMultipleAttempts: allowMultipleAttempts,
      );
      if (result.isOpen) {
        _openDeThis = List<DeThi>.from(_openDeThis)..add(result);
      }
      notifyListeners();
      return result;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateDeThi({
    required int id,
    required String tenDeThi,
    required int chuDeId,
    required int soCauHoi,
    required int thoiGianThi,
    required String trangThai,
    bool allowMultipleAttempts = false,
  }) async {
    try {
      await _service.updateDeThi(
        id: id,
        tenDeThi: tenDeThi,
        chuDeId: chuDeId,
        soCauHoi: soCauHoi,
        thoiGianThi: thoiGianThi,
        trangThai: trangThai,
        allowMultipleAttempts: allowMultipleAttempts,
      );
      _openDeThis = _openDeThis
          .map(
            (deThi) => deThi.id == id
                ? DeThi(
                    id: deThi.id,
                    tenDeThi: tenDeThi,
                    chuDeId: chuDeId,
                    chuDe: deThi.chuDe,
                    soCauHoi: soCauHoi,
                    thoiGianThi: thoiGianThi,
                    trangThai: trangThai,
                    ngayTao: deThi.ngayTao,
                    allowMultipleAttempts: allowMultipleAttempts,
                  )
                : deThi,
          )
          .toList(growable: false);
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDeThi(int id) async {
    try {
      await _service.deleteDeThi(id);
      _openDeThis = _openDeThis
          .where((deThi) => deThi.id != id)
          .toList(growable: false);
      if (_adminDeThis != null) {
        final updatedItems = _adminDeThis!.items
            .where((deThi) => deThi.id != id)
            .toList();
        _adminDeThis = _adminDeThis!.copyWith(
          items: updatedItems,
          total: _adminDeThis!.total > 0 ? _adminDeThis!.total - 1 : 0,
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }
}
