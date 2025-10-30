import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/paginated_response.dart';
import '../models/user.dart';

class UsersService {
  final ApiClient _client;

  const UsersService(this._client);

  Future<PaginatedResponse<User>> fetchUsers({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/Users',
      query: {
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được danh sách người dùng');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return PaginatedResponse<User>(
      total: response['total'] as int? ?? items.length,
      items: items,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<User> fetchUser(String id) async {
    final response = await _client.get('/api/Users/$id');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không tìm thấy người dùng');
    }
    return User.fromJson(response);
  }

  Future<User> updateRoles(String id, List<String> roles) async {
    final response = await _client.put(
      '/api/Users/$id/roles',
      body: {'roles': roles},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Cập nhật quyền thất bại');
    }
    return User.fromJson(response);
  }

  Future<User> updateStatus(String id, {required bool trangThaiKhoa}) async {
    final response = await _client.put(
      '/api/Users/$id/status',
      body: {'trangThaiKhoa': trangThaiKhoa},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Cập nhật trạng thái thất bại');
    }
    return User.fromJson(response);
  }

  Future<User> createUser({
    required String userName,
    String? email,
    String? fullName,
    required String password,
    List<String>? roles,
  }) async {
    final response = await _client.post(
      '/api/Users',
      body: {
        'userName': userName,
        'email': email,
        'fullName': fullName,
        'password': password,
        if (roles != null) 'roles': roles,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Tạo người dùng thất bại');
    }
    return User.fromJson(response);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete('/api/Users/$id');
  }
}
