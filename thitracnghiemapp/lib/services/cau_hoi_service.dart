import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/cau_hoi.dart';
import '../models/paginated_response.dart';

class CauHoiService {
  final ApiClient _client;

  const CauHoiService(this._client);

  Future<PaginatedResponse<CauHoi>> fetchCauHois({
    int page = 1,
    int pageSize = 20,
    int? topicId,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (topicId != null) 'topicId': topicId,
    };

    final response = await _client.get('/api/CauHoi', query: query);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không lấy được danh sách câu hỏi');
    }

    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => CauHoi.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    final total = response['total'] as int? ?? items.length;
    final currentPage = response['page'] as int? ?? page;
    final currentPageSize = response['pageSize'] as int? ?? pageSize;

    return PaginatedResponse<CauHoi>(
      total: total,
      items: items,
      page: currentPage,
      pageSize: currentPageSize,
    );
  }

  Future<CauHoi> fetchById(int id) async {
    final response = await _client.get('/api/CauHoi/$id');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không tìm thấy câu hỏi');
    }
    return CauHoi.fromJson(response);
  }

  Future<CauHoi> createCauHoi({
    required String noiDung,
    String? hinhAnh,
    String? amThanh,
    required String dapAnA,
    required String dapAnB,
    String? dapAnC,
    String? dapAnD,
    required String dapAnDung,
    required int chuDeId,
  }) async {
    final payload = {
      'noiDung': noiDung,
      'hinhAnh': hinhAnh,
      'amThanh': amThanh,
      'dapAnA': dapAnA,
      'dapAnB': dapAnB,
      'dapAnC': dapAnC,
      'dapAnD': dapAnD,
      'dapAnDung': dapAnDung,
      'chuDeId': chuDeId,
    };
    final response = await _client.post('/api/CauHoi', body: payload);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không thể tạo câu hỏi');
    }
    return CauHoi.fromJson(response);
  }

  Future<void> updateCauHoi({
    required int id,
    required String noiDung,
    String? hinhAnh,
    String? amThanh,
    required String dapAnA,
    required String dapAnB,
    String? dapAnC,
    String? dapAnD,
    required String dapAnDung,
    required int chuDeId,
  }) async {
    final payload = {
      'id': id,
      'noiDung': noiDung,
      'hinhAnh': hinhAnh,
      'amThanh': amThanh,
      'dapAnA': dapAnA,
      'dapAnB': dapAnB,
      'dapAnC': dapAnC,
      'dapAnD': dapAnD,
      'dapAnDung': dapAnDung,
      'chuDeId': chuDeId,
    };
    await _client.put('/api/CauHoi/$id', body: payload);
  }

  Future<void> deleteCauHoi(int id) async {
    await _client.delete('/api/CauHoi/$id');
  }

  Future<String?> importFromExcel(File file, {required int topicId}) async {
    final token = _client.token;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Cần đăng nhập trước khi import câu hỏi',
      );
    }

    final uri = Uri.parse(_client.baseUrl).resolve('/api/CauHoi/import');
    final extension = file.path.split('.').last.toLowerCase();
    final mediaType = extension == 'xls'
        ? MediaType('application', 'vnd.ms-excel')
        : MediaType(
            'application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['topicId'] = topicId.toString()
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mediaType,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return 'Đã nhập câu hỏi từ Excel.';
      }

      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final message = data['message'] as String?;
          return (message == null || message.isEmpty)
              ? 'Đã nhập câu hỏi từ Excel.'
              : message;
        }
        if (data is String && data.isNotEmpty) {
          return data;
        }
        return 'Đã nhập câu hỏi từ Excel.';
      } catch (_) {
        return response.body.isEmpty
            ? 'Đã nhập câu hỏi từ Excel.'
            : response.body;
      }
    }

    String message = 'Import câu hỏi thất bại (mã ${response.statusCode})';
    try {
      final data = jsonDecode(response.body) as Object?;
      if (data is Map<String, dynamic>) {
        message =
            data['message'] as String? ??
            data['title'] as String? ??
            data['error'] as String? ??
            message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }
}
