import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthSession {
  final String token;
  final DateTime expiresAt;
  final User? user;

  const AuthSession({required this.token, required this.expiresAt, this.user});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiresAt': expiresAt.toIso8601String(),
    if (user != null) 'user': user!.toJson(),
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  AuthSession copyWith({String? token, DateTime? expiresAt, User? user}) {
    return AuthSession(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.isUtc ? parsed : parsed.toUtc();
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class TokenStorage {
  static const _key = 'auth_session';

  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final session = AuthSession.fromJson(jsonMap);
      if (session.token.isEmpty) {
        return null;
      }
      return session;
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
