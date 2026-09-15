import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the stored JWT to every outgoing request and reacts to 401s.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.onUnauthorized,
  });

  final TokenStorage tokenStorage;
  final void Function() onUnauthorized;

  static bool _isLoginRequest(RequestOptions options) =>
      options.path.contains('/auth/login');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isExpiredSession = err.response?.statusCode == 401 &&
        !_isLoginRequest(err.requestOptions);

    if (isExpiredSession) {
      // Let the auth layer tear down the session; the router then redirects to
      // the login screen. The error still propagates to the caller.
      onUnauthorized();
    }

    handler.next(err);
  }
}
