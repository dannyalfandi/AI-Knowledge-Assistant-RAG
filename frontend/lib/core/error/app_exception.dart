/// Domain-facing error type. The data layer converts `DioException` and other
/// low-level failures into one of these so the UI never has to know about `dio`.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Human-readable, safe to show in the UI as-is.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A request reached the server and it answered with an error payload
/// (`{ "message": "..." }`). [message] is the backend's own text.
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});

  final int? statusCode;
}

/// Credentials/token rejected (HTTP 401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

/// Could not reach the server at all (no connection, timeout, DNS, ...).
class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Tidak dapat terhubung ke server. Periksa koneksi Anda lalu coba lagi.',
  ]);
}

/// Anything we did not anticipate.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Terjadi kesalahan tak terduga.']);
}
