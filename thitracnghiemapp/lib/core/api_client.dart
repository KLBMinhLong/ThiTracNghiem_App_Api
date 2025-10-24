import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  final http.Client _httpClient;
  final String baseUrl;
  String? _token;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  void updateToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _send(method: 'GET', path: path, query: query, headers: headers);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      query: query,
      headers: headers,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      body: body,
      query: query,
      headers: headers,
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      body: body,
      query: query,
      headers: headers,
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    final filteredQuery = query == null
        ? null
        : Map.fromEntries(
            query.entries
                .where((entry) => entry.value != null)
                .map((entry) => MapEntry(entry.key, entry.value!.toString())),
          );

    final uri = Uri.parse(
      baseUrl,
    ).resolve(path).replace(queryParameters: filteredQuery);

    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer ${_token!}',
      if (headers != null) ...headers,
    };

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: requestHeaders,
            body: _encodeBody(body),
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: requestHeaders,
            body: _encodeBody(body),
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(
            uri,
            headers: requestHeaders,
            body: _encodeBody(body),
          );
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }
    } catch (error) {
      throw ApiException(message: 'Không thể kết nối máy chủ: $error');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.',
        data: _tryParseError(response),
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message:
          _extractMessage(response) ??
          'Yêu cầu thất bại với mã ${response.statusCode}',
      data: _tryParseError(response),
    );
  }

  static String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String) {
      return body;
    }
    return jsonEncode(body);
  }

  static dynamic _tryParseError(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return response.body;
    }
  }

  static String? _extractMessage(http.Response response) {
    final data = _tryParseError(response);
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        return data['message'] as String;
      }
      if (data['title'] is String) {
        return data['title'] as String;
      }
      if (data['error'] is String) {
        return data['error'] as String;
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }
}
