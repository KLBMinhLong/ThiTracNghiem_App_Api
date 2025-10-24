import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/chu_de.dart';
import '../models/paginated_response.dart';

class ChuDeService {
  final ApiClient _client;

  const ChuDeService(this._client);

  Future<PaginatedResponse<ChuDe>> fetchChuDes({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _client.get(
      '/api/ChuDe',
      query: {'page': page, 'pageSize': pageSize},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được danh sách chủ đề');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => ChuDe.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return PaginatedResponse<ChuDe>(
      total: response['total'] as int? ?? items.length,
      items: items,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<ChuDe>> fetchAll() async {
    final result = await fetchChuDes(pageSize: 1000);
    return result.items;
  }

  Future<ChuDe> fetchById(int id) async {
    final response = await _client.get('/api/ChuDe/$id');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không tìm thấy chủ đề');
    }
    return ChuDe.fromJson(response);
  }

  Future<ChuDe> createChuDe({required String tenChuDe, String? moTa}) async {
    final response = await _client.post(
      '/api/ChuDe',
      body: {'tenChuDe': tenChuDe, 'moTa': moTa ?? ''},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không thể tạo chủ đề');
    }
    return ChuDe.fromJson(response);
  }

  Future<void> updateChuDe({
    required int id,
    required String tenChuDe,
    String? moTa,
  }) async {
    await _client.put(
      '/api/ChuDe/$id',
      body: {'id': id, 'tenChuDe': tenChuDe, 'moTa': moTa ?? ''},
    );
  }

  Future<void> deleteChuDe(int id) async {
    await _client.delete('/api/ChuDe/$id');
  }
}
