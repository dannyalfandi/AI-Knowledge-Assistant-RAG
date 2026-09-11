import 'package:flutter/foundation.dart';

/// Single source of truth for where the backend lives.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
///
/// Defaults are platform-aware because the Android emulator cannot reach the
/// host machine's `localhost` — it must use the `10.0.2.2` alias instead.
class ApiConfig {
  const ApiConfig._();

  static const String _envOverride = String.fromEnvironment('API_BASE_URL');

  /// Path prefix every backend route shares (`/api/auth/login`, ...).
  static const String apiPrefix = '/api';

  static String get baseUrl {
    if (_envOverride.isNotEmpty) return _envOverride;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    // iOS simulator, macOS/Windows/Linux desktop
    return 'http://localhost:3000';
  }
}
