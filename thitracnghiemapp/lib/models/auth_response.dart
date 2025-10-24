import 'user.dart';

class AuthResponse {
  final String token;
  final DateTime expiresAt;
  final User user;

  const AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      user: User.fromJson(
        json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
