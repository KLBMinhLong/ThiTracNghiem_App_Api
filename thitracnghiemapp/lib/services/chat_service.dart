import '../core/api_client.dart';

class ChatService {
  final ApiClient _client;
  const ChatService(this._client);

  Future<String> sendMessage({
    required int ketQuaThiId,
    required String message,
  }) async {
    final resp = await _client.post(
      '/api/Chat/explain',
      body: {'ketQuaThiId': ketQuaThiId, 'message': message},
    );
    if (resp is Map<String, dynamic> && resp['reply'] is String) {
      return resp['reply'] as String;
    }
    throw Exception('Phản hồi không hợp lệ từ máy chủ');
  }
}
