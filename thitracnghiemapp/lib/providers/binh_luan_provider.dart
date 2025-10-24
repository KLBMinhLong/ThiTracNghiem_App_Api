import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/binh_luan.dart';
import '../models/paginated_response.dart';
import '../services/binh_luan_service.dart';

class BinhLuanProvider extends ChangeNotifier {
  final BinhLuanService _service;

  BinhLuanProvider(this._service);

  PaginatedResponse<BinhLuan>? _comments;
  bool _isLoading = false;
  String? _error;

  PaginatedResponse<BinhLuan>? get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComments({required int deThiId, int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _comments = await _service.fetchByDeThi(deThiId: deThiId, page: page);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createComment({
    required int deThiId,
    required String noiDung,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _service.createBinhLuan(
        deThiId: deThiId,
        noiDung: noiDung,
      );
      final current = _comments;
      if (current != null) {
        final updatedItems = [created, ...current.items];
        _comments = current.copyWith(
          items: updatedItems,
          total: current.total + 1,
        );
      } else {
        _comments = PaginatedResponse<BinhLuan>(
          total: 1,
          items: [created],
          page: 1,
          pageSize: 20,
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

  Future<void> updateComment({required int id, required String noiDung}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _service.updateBinhLuan(id: id, noiDung: noiDung);
      final current = _comments;
      if (current != null) {
        _comments = current.copyWith(
          items: current.items
              .map(
                (comment) => comment.id == id
                    ? comment.copyWith(noiDung: noiDung)
                    : comment,
              )
              .toList(growable: false),
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

  Future<void> deleteComment(int id) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteBinhLuan(id);
      final current = _comments;
      if (current != null) {
        final updatedItems = current.items
            .where((comment) => comment.id != id)
            .toList(growable: false);
        _comments = current.copyWith(
          items: updatedItems,
          total: current.total > 0 ? current.total - 1 : 0,
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

  void clearComments() {
    _comments = null;
    _error = null;
    notifyListeners();
  }
}
