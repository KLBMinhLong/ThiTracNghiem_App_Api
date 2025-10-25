import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/lien_he.dart';
import '../models/paginated_response.dart';
import '../services/lien_he_service.dart';

class LienHeProvider extends ChangeNotifier {
  final LienHeService _service;

  LienHeProvider(this._service);

  PaginatedResponse<LienHe>? _allLienHe;
  List<LienHe>? _myLienHe;
  bool _isLoading = false;
  String? _error;

  PaginatedResponse<LienHe>? get allLienHe => _allLienHe;
  List<LienHe>? get myLienHe => _myLienHe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allLienHe = await _service.fetchLienHes(page: page);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMine() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myLienHe = await _service.fetchMyLienHes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createLienHe({
    required String tieuDe,
    required String noiDung,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _service.createLienHe(
        tieuDe: tieuDe,
        noiDung: noiDung,
      );
      final mine = _myLienHe;
      if (mine != null) {
        _myLienHe = [created, ...mine];
      } else {
        _myLienHe = [created];
      }
      final all = _allLienHe;
      if (all != null) {
        final updatedItems = [created, ...all.items];
        _allLienHe = all.copyWith(items: updatedItems, total: all.total + 1);
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

  Future<bool> deleteLienHe(int id) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    var success = false;
    try {
      await _service.deleteLienHe(id);
      final mine = _myLienHe;
      if (mine != null) {
        _myLienHe = mine.where((item) => item.id != id).toList(growable: false);
      }
      final all = _allLienHe;
      if (all != null) {
        final filtered = all.items
            .where((item) => item.id != id)
            .toList(growable: false);
        _allLienHe = all.copyWith(
          items: filtered,
          total: all.total > 0 ? all.total - 1 : 0,
        );
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

  void clear() {
    _allLienHe = null;
    _myLienHe = null;
    _error = null;
    notifyListeners();
  }
}
