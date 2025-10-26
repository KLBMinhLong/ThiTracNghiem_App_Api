import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/de_thi.dart';
import '../models/paginated_response.dart';

class DeThiService {
  final ApiClient _client;

  const DeThiService(this._client);

  Future<PaginatedResponse<DeThi>> fetchDeThis({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/DeThi',
      query: {'page': page, 'pageSize': pageSize},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được danh sách đề thi');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => DeThi.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return PaginatedResponse<DeThi>(
      total: response['total'] as int? ?? items.length,
      items: items,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<DeThi>> fetchOpenDeThis() async {
    final response = await _client.get('/api/DeThi/open');
    if (response is! List) {
      throw const ApiException(
        message: 'Không tìm thấy danh sách đề thi đang mở',
      );
    }
    return response
        .map((item) => DeThi.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<DeThi> fetchById(int id) async {
    final response = await _client.get('/api/DeThi/$id');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không tìm thấy thông tin đề thi');
    }
    return DeThi.fromJson(response);
  }

  Future<DeThi> createDeThi({
    required String tenDeThi,
    required int chuDeId,
    required int soCauHoi,
    required int thoiGianThi,
    String trangThai = 'Mo',
    bool allowMultipleAttempts = false,
  }) async {
    final payload = {
      'tenDeThi': tenDeThi,
      'chuDeId': chuDeId,
      'soCauHoi': soCauHoi,
      'thoiGianThi': thoiGianThi,
      'trangThai': trangThai,
      'allowMultipleAttempts': allowMultipleAttempts,
    };
    final response = await _client.post('/api/DeThi', body: payload);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Tạo đề thi thất bại');
    }
    return DeThi.fromJson(response);
  }

  Future<void> updateDeThi({
    required int id,
    required String tenDeThi,
    required int chuDeId,
    required int soCauHoi,
    required int thoiGianThi,
    required String trangThai,
    bool allowMultipleAttempts = false,
  }) async {
    final payload = {
      'id': id,
      'tenDeThi': tenDeThi,
      'chuDeId': chuDeId,
      'soCauHoi': soCauHoi,
      'thoiGianThi': thoiGianThi,
      'trangThai': trangThai,
      'allowMultipleAttempts': allowMultipleAttempts,
    };
    await _client.put('/api/DeThi/$id', body: payload);
  }

  Future<void> deleteDeThi(int id) async {
    await _client.delete('/api/DeThi/$id');
  }
}
