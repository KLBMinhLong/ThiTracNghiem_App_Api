import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../models/two_fa.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  late final AuthService _authService;

  AuthSession? _session;
  User? _currentUser;
  bool _initialized = false;
  bool _loading = false;
  String? _error;
  bool _sendingResetEmail = false;
  bool _resettingPassword = false;

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
  bool get isSendingResetEmail => _sendingResetEmail;
  bool get isResettingPassword => _resettingPassword;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _setLoading(true);

    // Ensure splash screen shows for at least 2 seconds
    final startTime = DateTime.now();

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

    // Calculate remaining time to show splash screen
    final elapsed = DateTime.now().difference(startTime);
    final minimumDuration = const Duration(seconds: 2);
    if (elapsed < minimumDuration) {
      await Future.delayed(minimumDuration - elapsed);
    }

    _initialized = true;
    _setLoading(false);
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      // Check if 2FA is required by inspecting raw response
      final raw = await _authService.loginRaw(
        identifier: identifier,
        password: password,
      );
      final requires2Fa = raw['requiresTwoFactor'] == true;
      if (requires2Fa) {
        // Store a temporary marker in memory so UI can navigate to 2FA screen
        _pending2FaUserId = raw['userId'] as String?;
        _setLoading(false);
        notifyListeners();
        return false; // caller will handle navigation to 2FA
      }
      final response = AuthResponse.fromJson(raw);
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

  String? _pending2FaUserId;
  String? get pendingTwoFaUserId => _pending2FaUserId;

  Future<bool> completeLoginWith2Fa({required String code}) async {
    final userId = _pending2FaUserId;
    if (userId == null) {
      _error = 'Không xác định được tài khoản cần xác thực 2 bước';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.loginWith2Fa(
        userId: userId,
        code: code,
      );
      await _persistSession(response);
      _currentUser = response.user;
      _pending2FaUserId = null;
      _setLoading(false);
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _setLoading(false);
      return false;
    } catch (error) {
      _error = error.toString();
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

  Future<bool> loginWithGoogle({required String idToken}) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.loginWithGoogle(idToken: idToken);
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

  // 2FA settings helpers
  Future<bool> getTwoFaStatus() async {
    try {
      return await _authService.getTwoFaStatus();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<TwoFaSetupResponse> setupTwoFa() async {
    try {
      return await _authService.setupTwoFa();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> enableTwoFa({required String code}) async {
    try {
      await _authService.enableTwoFa(code: code);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disableTwoFa() async {
    try {
      await _authService.disableTwoFa();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    if (_sendingResetEmail) {
      return 'Đang gửi email hướng dẫn, vui lòng chờ.';
    }
    _sendingResetEmail = true;
    notifyListeners();
    try {
      await _authService.forgotPassword(email: email);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    } finally {
      _sendingResetEmail = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    if (_resettingPassword) {
      return 'Đang đặt lại mật khẩu, vui lòng chờ.';
    }
    _resettingPassword = true;
    notifyListeners();
    try {
      await _authService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    } finally {
      _resettingPassword = false;
      notifyListeners();
    }
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
