import 'package:flutter/foundation.dart';

import '../models/chu_de.dart';
import '../models/paginated_response.dart';
import '../services/chu_de_service.dart';

class ChuDeProvider extends ChangeNotifier {
  final ChuDeService _service;

  ChuDeProvider(this._service);

  List<ChuDe> _chuDes = const [];
  PaginatedResponse<ChuDe>? _paged;
  bool _loading = false;
  String? _error;

  List<ChuDe> get chuDes => _chuDes;
  PaginatedResponse<ChuDe>? get paged => _paged;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetchChuDes({int page = 1, int pageSize = 50}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _service.fetchChuDes(
        page: page,
        pageSize: pageSize,
      );
      _chuDes = response.items;
      _paged = response;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ChuDe?> createChuDe({required String tenChuDe, String? moTa}) async {
    try {
      final chuDe = await _service.createChuDe(tenChuDe: tenChuDe, moTa: moTa);
      _chuDes = List<ChuDe>.from(_chuDes)..add(chuDe);
      notifyListeners();
      return chuDe;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateChuDe({
    required int id,
    required String tenChuDe,
    String? moTa,
  }) async {
    try {
      await _service.updateChuDe(id: id, tenChuDe: tenChuDe, moTa: moTa);
      _chuDes = _chuDes
          .map(
            (chuDe) => chuDe.id == id
                ? ChuDe(id: id, tenChuDe: tenChuDe, moTa: moTa)
                : chuDe,
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

  Future<bool> deleteChuDe(int id) async {
    try {
      await _service.deleteChuDe(id);
      _chuDes = _chuDes
          .where((chuDe) => chuDe.id != id)
          .toList(growable: false);
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }
}
