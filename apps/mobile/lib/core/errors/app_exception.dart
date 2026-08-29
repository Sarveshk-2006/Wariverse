/// Typed exception codes for WariVerse AI error handling.
enum AppErrorCode {
  timeout,
  noInternet,
  serverUnavailable,
  http4xx,
  http5xx,
  invalidJson,
  missingField,
  emptyResponse,
  unauthorized,
  unknown,
}

/// Centralized typed exception for all application errors.
class AppException implements Exception {
  final String message;
  final AppErrorCode code;
  final int? httpStatusCode;

  const AppException(
    this.message, {
    this.code = AppErrorCode.unknown,
    this.httpStatusCode,
  });

  /// Factory constructors for common error cases.
  factory AppException.timeout() => const AppException(
        'Request timed out. Check your connection and try again.',
        code: AppErrorCode.timeout,
      );

  factory AppException.noInternet() => const AppException(
        'No internet connection. Using offline data.',
        code: AppErrorCode.noInternet,
      );

  factory AppException.serverUnavailable() => const AppException(
        'Server is currently unavailable. Using cached data.',
        code: AppErrorCode.serverUnavailable,
      );

  factory AppException.http(int statusCode, String body) {
    if (statusCode >= 500) {
      return AppException(
        'Server error ($statusCode): $body',
        code: AppErrorCode.http5xx,
        httpStatusCode: statusCode,
      );
    }
    if (statusCode == 401) {
      return AppException(
        'Session expired. Please log in again.',
        code: AppErrorCode.unauthorized,
        httpStatusCode: statusCode,
      );
    }
    return AppException(
      'Request failed ($statusCode): $body',
      code: AppErrorCode.http4xx,
      httpStatusCode: statusCode,
    );
  }

  factory AppException.invalidJson(String detail) => AppException(
        'Invalid response from server: $detail',
        code: AppErrorCode.invalidJson,
      );

  bool get isNetworkError =>
      code == AppErrorCode.timeout ||
      code == AppErrorCode.noInternet ||
      code == AppErrorCode.serverUnavailable;

  bool get isMockFallbackEligible => isNetworkError;

  @override
  String toString() => 'AppException[$code]: $message';
}
