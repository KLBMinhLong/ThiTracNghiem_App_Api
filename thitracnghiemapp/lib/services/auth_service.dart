import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _client;

  const AuthService(this._client);

  Future<AuthResponse> login({
    required String userName,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/Auth/login',
      body: {'userName': userName, 'password': password},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Định dạng phản hồi đăng nhập không hợp lệ',
      );
    }
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> register({
    required String userName,
    required String email,
    required String password,
    String? fullName,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? soDienThoai,
    String? avatarUrl,
  }) async {
    final payload = {
      'userName': userName,
      'email': email,
      'password': password,
      if (fullName != null) 'fullName': fullName,
      if (ngaySinh != null) 'ngaySinh': ngaySinh.toIso8601String(),
      if (gioiTinh != null) 'gioiTinh': gioiTinh,
      if (soDienThoai != null) 'soDienThoai': soDienThoai,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };

    final response = await _client.post('/api/Auth/register', body: payload);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Định dạng phản hồi đăng ký không hợp lệ',
      );
    }
    return AuthResponse.fromJson(response);
  }

  Future<User> fetchProfile() async {
    final response = await _client.get('/api/Auth/me');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được thông tin tài khoản');
    }
    return User.fromJson(response);
  }

  Future<User> updateProfile({
    String? fullName,
    String? email,
    String? soDienThoai,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? avatarUrl,
  }) async {
    final payload = {
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (soDienThoai != null) 'soDienThoai': soDienThoai,
      if (ngaySinh != null) 'ngaySinh': ngaySinh.toIso8601String(),
      if (gioiTinh != null) 'gioiTinh': gioiTinh,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };

    final response = await _client.put('/api/Auth/me', body: payload);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Cập nhật hồ sơ thất bại');
    }
    return User.fromJson(response);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      '/api/Auth/me/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
