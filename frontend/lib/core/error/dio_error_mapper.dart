import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Converts a low-level [DioException] into a domain [AppException]. Every data
/// source funnels its `dio` failures through here so the rest of the app only
/// ever deals with [AppException].
AppException mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NetworkException();

    case DioExceptionType.cancel:
      return const UnknownException('Permintaan dibatalkan.');

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final message = _messageFromBody(error.response?.data);

      if (statusCode == 401) {
        return UnauthorizedException(
          message ?? 'Sesi tidak valid. Silakan masuk kembali.',
        );
      }

      if (statusCode == 403) {
        return ForbiddenException(
          message ?? 'Anda tidak memiliki akses untuk tindakan ini.',
        );
      }

      return ApiException(
        message ?? 'Permintaan gagal${statusCode == null ? '' : ' ($statusCode)'}.',
        statusCode: statusCode,
      );

    case DioExceptionType.unknown:
      return const UnknownException();
  }
}

/// The backend error shape is always `{ "message": "..." }`.
String? _messageFromBody(Object? data) {
  if (data is Map && data['message'] is String) {
    final message = (data['message'] as String).trim();
    return message.isEmpty ? null : message;
  }
  return null;
}
