import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get baseUrl {
    final value = dotenv.env['BASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('BASE_URL is not configured in the .env file');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
