import '../entities/user.dart';

/// Contract the presentation layer depends on. The implementation
/// (`data/repositories/auth_repository_impl.dart`) owns the transport and the
/// local session storage; nothing here knows about `dio` or secure storage.
abstract interface class AuthRepository {
  /// Exchanges credentials for a session and persists it locally.
  ///
  /// Throws an [AppException] (`UnauthorizedException` for wrong credentials,
  /// `NetworkException` when the server is unreachable, ...).
  Future<User> login({required String email, required String password});

  /// Clears the local session. Always succeeds.
  Future<void> logout();

  /// Resolves the currently signed-in user, or `null` when there is no valid
  /// session. Validates the stored token against the backend; a token the
  /// backend rejects is discarded.
  Future<User?> currentUser();
}
