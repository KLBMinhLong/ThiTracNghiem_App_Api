import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/cau_hoi.dart';
import '../services/cau_hoi_service.dart';

class CauHoiProvider extends ChangeNotifier {
  final CauHoiService _service;

  CauHoiProvider(this._service);

  static const int _defaultPageSize = 20;

  List<CauHoi> _cauHois = const [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _nextPage = 1;
  int? _selectedTopicId;
  String? _error;

  List<CauHoi> get cauHois => _cauHois;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get canLoadMore => _hasMore && !_loading && !_loadingMore;
  int? get selectedTopicId => _selectedTopicId;
  String? get error => _error;

  Future<void> refreshCauHois({int? topicId}) async {
    final effectiveTopicId = topicId ?? _selectedTopicId;
    if (_loading && effectiveTopicId == _selectedTopicId) {
      return;
    }

    _loading = true;
    _error = null;
    _selectedTopicId = effectiveTopicId;
    _nextPage = 1;
    notifyListeners();

    try {
      final response = await _service.fetchCauHois(
        page: _nextPage,
        pageSize: _defaultPageSize,
        topicId: _selectedTopicId,
      );
      _cauHois = response.items;
      _hasMore = !response.isLastPage;
      _nextPage = response.page + 1;
    } catch (error) {
      _error = error.toString();
      _cauHois = const [];
      _hasMore = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreCauHois() async {
    if (!canLoadMore) {
      return;
    }

    _loadingMore = true;
    notifyListeners();

    try {
      final response = await _service.fetchCauHois(
        page: _nextPage,
        pageSize: _defaultPageSize,
        topicId: _selectedTopicId,
      );
      _cauHois = List<CauHoi>.from(_cauHois)..addAll(response.items);
      _hasMore = !response.isLastPage;
      _nextPage = response.page + 1;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setTopicFilter(int? topicId) async {
    if (_selectedTopicId == topicId && _cauHois.isNotEmpty) {
      return;
    }
    await refreshCauHois(topicId: topicId);
  }

  Future<CauHoi?> createCauHoi({
    required String noiDung,
    String? hinhAnh,
    String? amThanh,
    required String dapAnA,
    required String dapAnB,
    String? dapAnC,
    String? dapAnD,
    required String dapAnDung,
    required int chuDeId,
  }) async {
    try {
      final cauHoi = await _service.createCauHoi(
        noiDung: noiDung,
        hinhAnh: hinhAnh,
        amThanh: amThanh,
        dapAnA: dapAnA,
        dapAnB: dapAnB,
        dapAnC: dapAnC,
        dapAnD: dapAnD,
        dapAnDung: dapAnDung,
        chuDeId: chuDeId,
      );

      if (_selectedTopicId == null || _selectedTopicId == chuDeId) {
        _cauHois = [cauHoi, ..._cauHois];
      }
      notifyListeners();
      return cauHoi;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCauHoi({
    required int id,
    required String noiDung,
    String? hinhAnh,
    String? amThanh,
    required String dapAnA,
    required String dapAnB,
    String? dapAnC,
    String? dapAnD,
    required String dapAnDung,
    required int chuDeId,
  }) async {
    try {
      await _service.updateCauHoi(
        id: id,
        noiDung: noiDung,
        hinhAnh: hinhAnh,
        amThanh: amThanh,
        dapAnA: dapAnA,
        dapAnB: dapAnB,
        dapAnC: dapAnC,
        dapAnD: dapAnD,
        dapAnDung: dapAnDung,
        chuDeId: chuDeId,
      );

      _cauHois = _cauHois
          .map(
            (cauHoi) => cauHoi.id == id
                ? CauHoi(
                    id: id,
                    noiDung: noiDung,
                    hinhAnh: hinhAnh,
                    amThanh: amThanh,
                    dapAnA: dapAnA,
                    dapAnB: dapAnB,
                    dapAnC: dapAnC,
                    dapAnD: dapAnD,
                    dapAnDung: dapAnDung,
                    chuDeId: chuDeId,
                  )
                : cauHoi,
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

  Future<bool> deleteCauHoi(int id) async {
    try {
      await _service.deleteCauHoi(id);
      _cauHois = _cauHois
          .where((cauHoi) => cauHoi.id != id)
          .toList(growable: false);
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> importCauHois(File file, {required int topicId}) async {
    try {
      final message = await _service.importFromExcel(file, topicId: topicId);
      await refreshCauHois(topicId: _selectedTopicId);
      return message;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }
}
