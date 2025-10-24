import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/lien_he.dart';
import '../models/paginated_response.dart';

class LienHeService {
  final ApiClient _client;

  const LienHeService(this._client);

  Future<PaginatedResponse<LienHe>> fetchLienHes({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/LienHe',
      query: {'page': page, 'pageSize': pageSize},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được danh sách liên hệ');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => LienHe.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return PaginatedResponse<LienHe>(
      total: response['total'] as int? ?? items.length,
      items: items,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<LienHe>> fetchMyLienHes() async {
    final response = await _client.get('/api/LienHe/mine');
    if (response is! List) {
      throw const ApiException(
        message: 'Không lấy được danh sách liên hệ của bạn',
      );
    }
    return response
        .map((item) => LienHe.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<LienHe> createLienHe({
    required String tieuDe,
    required String noiDung,
  }) async {
    final response = await _client.post(
      '/api/LienHe',
      body: {'tieuDe': tieuDe, 'noiDung': noiDung},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không gửi được liên hệ');
    }
    return LienHe.fromJson(response);
  }

  Future<void> deleteLienHe(int id) async {
    await _client.delete('/api/LienHe/$id');
  }
}
