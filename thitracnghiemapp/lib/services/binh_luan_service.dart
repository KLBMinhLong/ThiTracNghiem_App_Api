import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/binh_luan.dart';
import '../models/paginated_response.dart';

class BinhLuanService {
  final ApiClient _client;

  const BinhLuanService(this._client);

  Future<PaginatedResponse<BinhLuan>> fetchByDeThi({
    required int deThiId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/BinhLuan/dethi/$deThiId',
      query: {'page': page, 'pageSize': pageSize},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được bình luận');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => BinhLuan.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return PaginatedResponse<BinhLuan>(
      total: response['total'] as int? ?? items.length,
      items: items,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<BinhLuan> createBinhLuan({
    required int deThiId,
    required String noiDung,
  }) async {
    final response = await _client.post(
      '/api/BinhLuan',
      body: {'deThiId': deThiId, 'noiDung': noiDung},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không thể tạo bình luận');
    }
    return BinhLuan.fromJson(response);
  }

  Future<void> updateBinhLuan({
    required int id,
    required String noiDung,
  }) async {
    await _client.put('/api/BinhLuan/$id', body: {'noiDung': noiDung});
  }

  Future<void> deleteBinhLuan(int id) async {
    await _client.delete('/api/BinhLuan/$id');
  }
}
