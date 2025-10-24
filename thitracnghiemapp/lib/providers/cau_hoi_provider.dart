import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/cau_hoi.dart';
import '../services/cau_hoi_service.dart';

class CauHoiProvider extends ChangeNotifier {
  final CauHoiService _service;

  CauHoiProvider(this._service);

  List<CauHoi> _cauHois = const [];
  bool _loading = false;
  String? _error;

  List<CauHoi> get cauHois => _cauHois;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetchCauHois() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cauHois = await _service.fetchCauHois();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
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
      _cauHois = List<CauHoi>.from(_cauHois)..add(cauHoi);
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

  Future<bool> importCauHois(File file) async {
    try {
      await _service.importFromExcel(file);
      await fetchCauHois();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }
}
