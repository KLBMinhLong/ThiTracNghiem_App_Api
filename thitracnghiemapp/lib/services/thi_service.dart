import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/quiz_session.dart';

class ThiService {
  final ApiClient _client;

  const ThiService(this._client);

  Future<QuizSession> startThi(int deThiId) async {
    final response = await _client.post('/api/Thi/start/$deThiId');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Không thể khởi tạo bài thi');
    }
    return QuizSession.fromJson(response);
  }

  Future<void> updateDapAn({
    required int ketQuaThiId,
    required int cauHoiId,
    required String dapAnChon,
  }) async {
    await _client.put(
      '/api/Thi/update/$ketQuaThiId/$cauHoiId',
      body: {'dapAnChon': dapAnChon},
    );
  }

  Future<SubmitThiResult> submitThi(int ketQuaThiId) async {
    final response = await _client.post('/api/Thi/submit/$ketQuaThiId');
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Nộp bài thi thất bại');
    }
    return SubmitThiResult.fromJson(response);
  }
}
