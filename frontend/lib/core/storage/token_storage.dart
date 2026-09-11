import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for the auth session.
///
/// Stores two things:
///  - `access_token`: the JWT, attached to every request by the interceptor.
///  - `auth_user`: the full user JSON from `/api/auth/login`, cached so the app
///    can rehydrate the [User] on start (the `/api/auth/me` endpoint only
///    returns `{ id, role }`).
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'access_token';
  static const _userKey = 'auth_user';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});
