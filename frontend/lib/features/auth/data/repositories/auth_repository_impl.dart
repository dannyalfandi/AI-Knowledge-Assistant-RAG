import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.storage,
  });

  final AuthRemoteDataSource remote;
  final TokenStorage storage;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final result = await remote.login(email: email, password: password);
    await storage.saveSession(
      token: result.token,
      userJson: result.user.encode(),
    );
    return result.user;
  }

  @override
  Future<void> logout() => storage.clear();

  @override
  Future<User?> currentUser() async {
    final token = await storage.readToken();
    if (token == null || token.isEmpty) return null;

    final cached = UserModel.tryDecode(await storage.readUserJson());

    try {
      final me = await remote.fetchCurrentUser();

      // `/api/auth/me` only returns id + role; keep the richer name/email from
      // the cached login payload.
      final user = UserModel(
        id: me.id,
        role: me.role,
        email: cached?.email ?? '',
        name: cached?.name ?? '',
      );
      await storage.saveSession(token: token, userJson: user.encode());
      return user;
    } on UnauthorizedException {
      // The backend rejected the token — the session is genuinely over.
      await storage.clear();
      return null;
    } on AppException {
      // Backend unreachable / transient failure: keep the session and fall back
      // to the cached user rather than forcing a re-login on a flaky network.
      return cached;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});
