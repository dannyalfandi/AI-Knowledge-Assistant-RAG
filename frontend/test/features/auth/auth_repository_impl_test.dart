import 'package:dio/dio.dart';
import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/core/storage/token_storage.dart';
import 'package:enterprise_knowledge_assistant/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:enterprise_knowledge_assistant/features/auth/data/models/user_model.dart';
import 'package:enterprise_knowledge_assistant/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _admin = UserModel(
  id: 'u1',
  email: 'admin@corp.com',
  name: 'Admin',
  role: 'ADMIN',
);

class _FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  _FakeAuthRemoteDataSource() : super(Dio());

  LoginResult? loginResult;
  Object? loginError;

  UserModel? meResult;
  Object? meError;

  int fetchCurrentUserCalls = 0;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final error = loginError;
    if (error != null) throw error;
    return loginResult!;
  }

  @override
  Future<UserModel> fetchCurrentUser() async {
    fetchCurrentUserCalls++;
    final error = meError;
    if (error != null) throw error;
    return meResult!;
  }
}

void main() {
  late _FakeAuthRemoteDataSource remote;
  late TokenStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    remote = _FakeAuthRemoteDataSource();
    storage = TokenStorage(const FlutterSecureStorage());
    repository = AuthRepositoryImpl(remote: remote, storage: storage);
  });

  group('login', () {
    test('persists the session and returns the user', () async {
      remote.loginResult = const LoginResult(token: 'jwt-token', user: _admin);

      final user = await repository.login(
        email: 'admin@corp.com',
        password: 'secret',
      );

      expect(user.id, 'u1');
      expect(await storage.readToken(), 'jwt-token');
      expect(
        UserModel.tryDecode(await storage.readUserJson())?.email,
        'admin@corp.com',
      );
    });

    test('propagates UnauthorizedException and leaves storage empty', () async {
      remote.loginError = const UnauthorizedException('Invalid email or password');

      await expectLater(
        repository.login(email: 'admin@corp.com', password: 'wrong'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(await storage.readToken(), isNull);
    });
  });

  group('currentUser', () {
    test('returns null and skips the network when no token is stored', () async {
      expect(await repository.currentUser(), isNull);
      expect(remote.fetchCurrentUserCalls, 0);
    });

    test('validates the token and merges cached name/email', () async {
      await storage.saveSession(token: 'jwt-token', userJson: _admin.encode());
      // `/api/auth/me` only echoes id + role.
      remote.meResult = const UserModel(
        id: 'u1',
        email: '',
        name: '',
        role: 'ADMIN',
      );

      final user = await repository.currentUser();

      expect(user?.name, 'Admin');
      expect(user?.email, 'admin@corp.com');
      expect(user?.role, 'ADMIN');
    });

    test('clears the session when the backend rejects the token', () async {
      await storage.saveSession(token: 'stale-token', userJson: _admin.encode());
      remote.meError = const UnauthorizedException('Invalid or expired token');

      expect(await repository.currentUser(), isNull);
      expect(await storage.readToken(), isNull);
    });

    test('keeps the session and uses the cache on a network error', () async {
      await storage.saveSession(token: 'jwt-token', userJson: _admin.encode());
      remote.meError = const NetworkException();

      final user = await repository.currentUser();

      expect(user?.id, 'u1');
      expect(await storage.readToken(), 'jwt-token');
    });
  });
}
