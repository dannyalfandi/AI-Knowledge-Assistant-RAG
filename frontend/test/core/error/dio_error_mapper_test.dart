import 'package:dio/dio.dart';
import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/core/error/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioException(
  DioExceptionType type, {
  int? statusCode,
  Object? body,
}) {
  final options = RequestOptions(path: '/auth/login');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
  );
}

void main() {
  test('401 becomes UnauthorizedException carrying the backend message', () {
    final result = mapDioException(
      _dioException(
        DioExceptionType.badResponse,
        statusCode: 401,
        body: {'message': 'Invalid email or password'},
      ),
    );

    expect(result, isA<UnauthorizedException>());
    expect(result.message, 'Invalid email or password');
  });

  test('other 4xx/5xx becomes ApiException with the status code', () {
    final result = mapDioException(
      _dioException(
        DioExceptionType.badResponse,
        statusCode: 500,
        body: {'message': 'Internal server error'},
      ),
    );

    expect(result, isA<ApiException>());
    expect((result as ApiException).statusCode, 500);
  });

  test('connection failures become NetworkException', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(mapDioException(_dioException(type)), isA<NetworkException>());
    }
  });

  test('unclassified errors become UnknownException', () {
    expect(
      mapDioException(_dioException(DioExceptionType.unknown)),
      isA<UnknownException>(),
    );
  });
}
