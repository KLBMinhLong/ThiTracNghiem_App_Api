import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/ket_qua_thi.dart';
import '../models/paginated_response.dart';

class KetQuaThiService {
  final ApiClient _client;

  const KetQuaThiService(this._client);

  Future<PaginatedResponse<KetQuaThiSummary>> fetchKetQuaThis({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _client.get(
      '/api/KetQuaThi',
      query: {'page': page, 'pageSize': pageSize},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được danh sách kết quả');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => KetQuaThiSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return PaginatedResponse<KetQuaThiSummary>(
      total: response['total'] as int? ?? items.length,
      items: items,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<KetQuaThiDetail> fetchKetQuaThi(int id) async {
    final response = await _client.get('/api/KetQuaThi/$id');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không tìm thấy kết quả thi');
    }
    return KetQuaThiDetail.fromJson(response);
  }

  Future<void> deleteKetQuaThi(int id) async {
    await _client.delete('/api/KetQuaThi/$id');
  }
}
