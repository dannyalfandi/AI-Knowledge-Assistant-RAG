import 'package:flutter/foundation.dart';

/// Single source of truth for where the backend lives.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
///
/// A dedicated sentinel value requests a *relative* base URL instead of an
/// absolute one — used for the Nginx-served build, where the app and the
/// `/api/*` reverse proxy share the same origin:
///   flutter build web --release --dart-define=API_BASE_URL=same-origin
/// (Plain `String.fromEnvironment` can't tell "not passed" apart from
/// "passed as empty string", so an empty override can't mean this — it has
/// to be a distinct, non-empty token.)
///
/// Defaults (no override) are platform-aware because the Android emulator
/// cannot reach the host machine's `localhost` — it must use the `10.0.2.2`
/// alias instead.
class ApiConfig {
  const ApiConfig._();

  static const String _envOverride = String.fromEnvironment('API_BASE_URL');
  static const String _sameOriginToken = 'same-origin';

  /// Path prefix every backend route shares (`/api/auth/login`, ...).
  static const String apiPrefix = '/api';

  static String get baseUrl {
    if (_envOverride == _sameOriginToken) return '';
    if (_envOverride.isNotEmpty) return _envOverride;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    // iOS simulator, macOS/Windows/Linux desktop
    return 'http://localhost:3000';
  }
}
