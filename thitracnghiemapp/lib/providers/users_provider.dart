import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/paginated_response.dart';
import '../models/user.dart';
import '../services/users_service.dart';

class UsersProvider extends ChangeNotifier {
  final UsersService _service;

  UsersProvider(this._service);

  PaginatedResponse<User>? _users;
  bool _isLoading = false;
  String? _error;
  User? _selectedUser;

  PaginatedResponse<User>? get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get selectedUser => _selectedUser;

  Future<void> fetchUsers({String? keyword, int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _service.fetchUsers(keyword: keyword, page: page);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUser = await _service.fetchUser(id);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRoles(String id, List<String> roles) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _service.updateRoles(id, roles);
      _selectedUser = updated;
      final current = _users;
      if (current != null) {
        _users = current.copyWith(
          items: current.items
              .map((user) => user.id == id ? updated : user)
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

  Future<void> updateStatus(String id, {required bool trangThaiKhoa}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _service.updateStatus(
        id,
        trangThaiKhoa: trangThaiKhoa,
      );
      _selectedUser = updated;
      final current = _users;
      if (current != null) {
        _users = current.copyWith(
          items: current.items
              .map((user) => user.id == id ? updated : user)
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

  void clearSelection() {
    _selectedUser = null;
    notifyListeners();
  }

  Future<User?> createUser({
    required String userName,
    String? email,
    String? fullName,
    required String password,
    List<String>? roles,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _service.createUser(
        userName: userName,
        email: email,
        fullName: fullName,
        password: password,
        roles: roles,
      );
      // Optimistically prepend to current page if loaded
      final current = _users;
      if (current != null) {
        final updatedItems = [created, ...current.items];
        _users = current.copyWith(
          items: updatedItems,
          total: current.total + 1,
        );
      }
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String id) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteUser(id);
      final current = _users;
      if (current != null) {
        final updatedItems = current.items.where((u) => u.id != id).toList();
        _users = current.copyWith(
          items: updatedItems,
          total: current.total > 0 ? current.total - 1 : 0,
        );
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Có lỗi xảy ra: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
