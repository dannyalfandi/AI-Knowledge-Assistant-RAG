import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/dio_provider.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../models/user_model.dart';

/// Result of a successful `POST /api/auth/login`.
class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final UserModel user;
}

/// Talks to the backend auth endpoints. Every `dio` failure is re-thrown as an
/// [AppException] via [mapDioException].
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = _data(response.data);

      return LoginResult(
        token: data['accessToken'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// `GET /api/auth/me` — used to check that a stored token is still accepted.
  /// The payload only carries `{ id, role }`.
  Future<UserModel> fetchCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = _data(response.data);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const UnknownException('Respons server tidak sesuai format.');
    }
    return data;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});
