import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/cau_hoi.dart';

class CauHoiService {
  final ApiClient _client;

  const CauHoiService(this._client);

  Future<List<CauHoi>> fetchCauHois() async {
    final response = await _client.get('/api/CauHoi');
    if (response is! List) {
      throw const ApiException(message: 'Không lấy được danh sách câu hỏi');
    }
    return response
        .map((item) => CauHoi.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
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

  Future<void> importFromExcel(File file) async {
    final token = _client.token;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Cần đăng nhập trước khi import câu hỏi',
      );
    }

    final uri = Uri.parse(_client.baseUrl).resolve('/api/CauHoi/import');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(
            'application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ),
      );

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Import câu hỏi thất bại (mã ${response.statusCode})',
      );
    }
  }
}
