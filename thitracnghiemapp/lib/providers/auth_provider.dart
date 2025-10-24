import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  late final AuthService _authService;

  AuthSession? _session;
  User? _currentUser;
  bool _initialized = false;
  bool _loading = false;
  String? _error;

  AuthProvider({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage {
    _authService = AuthService(_apiClient);
  }

  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  bool get isAuthenticated =>
      _session != null && !_session!.isExpired && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  User? get currentUser => _currentUser;
  String? get error => _error;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _setLoading(true);
    final session = await _tokenStorage.read();
    if (session != null && !session.isExpired) {
      _session = session;
      _apiClient.updateToken(session.token);
      try {
        _currentUser = session.user;
        final freshProfile = await _authService.fetchProfile();
        _currentUser = freshProfile;
        await _updateCachedUser(freshProfile);
      } on ApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await _clearSession();
        } else {
          _error = error.message;
        }
      } catch (error) {
        _error = error.toString();
      }
    } else {
      await _tokenStorage.clear();
      _session = null;
      _apiClient.updateToken(null);
    }
    _initialized = true;
    _setLoading(false);
  }

  Future<bool> login({
    required String userName,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.login(
        userName: userName,
        password: password,
      );
      await _persistSession(response);
      _currentUser = response.user;
      _setLoading(false);
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      await _clearSession();
      _setLoading(false);
      return false;
    } catch (error) {
      _error = error.toString();
      await _clearSession();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String userName,
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.register(
        userName: userName,
        email: email,
        password: password,
        fullName: fullName,
      );
      await _persistSession(response);
      _currentUser = response.user;
      _setLoading(false);
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      await _clearSession();
      _setLoading(false);
      return false;
    } catch (error) {
      _error = error.toString();
      await _clearSession();
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) {
      return;
    }
    try {
      final profile = await _authService.fetchProfile();
      _currentUser = profile;
      await _updateCachedUser(profile);
      notifyListeners();
    } on ApiException catch (error) {
      _error = error.message;
      await _clearSession();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? soDienThoai,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? avatarUrl,
  }) async {
    if (!isAuthenticated) {
      throw const ApiException(message: 'Bạn chưa đăng nhập');
    }
    final user = await _authService.updateProfile(
      fullName: fullName,
      email: email,
      soDienThoai: soDienThoai,
      ngaySinh: ngaySinh,
      gioiTinh: gioiTinh,
      avatarUrl: avatarUrl,
    );
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) {
      _error = 'Bạn chưa đăng nhập';
      notifyListeners();
      return false;
    }
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _persistSession(AuthResponse response) async {
    final session = AuthSession(
      token: response.token,
      expiresAt: response.expiresAt,
      user: response.user,
    );
    _session = session;
    _apiClient.updateToken(session.token);
    await _tokenStorage.save(session);
  }

  Future<void> _clearSession() async {
    _session = null;
    _currentUser = null;
    _error = null;
    _apiClient.updateToken(null);
    await _tokenStorage.clear();
  }

  Future<void> _updateCachedUser(User user) async {
    final session = _session;
    if (session == null) {
      return;
    }
    final updatedSession = session.copyWith(user: user);
    _session = updatedSession;
    await _tokenStorage.save(updatedSession);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
