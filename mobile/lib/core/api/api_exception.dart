import 'package:dio/dio.dart';

import '../auth/auth_service.dart';

/// What the rest of the app sees when an API call fails. Mirrors the server's error
/// shape: `{ "error": "<code>", "message": "<human text>" }` (see docs/api-contract.md).
///
/// TS equivalent: `class ApiError extends Error { status; code; }`.
class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    this.code,
    required this.message,
    this.isNetworkError = false,
    this.fieldErrors = const {},
    this.body = const {},
  });

  /// HTTP status, or null when the request never got a response.
  final int? statusCode;

  /// Machine-readable `error` from the body, e.g. `not_found`, `too_many_attempts`.
  final String? code;
  final String message;

  /// True for connection failures and timeouts (show "you're offline", don't treat
  /// as a rejected request).
  final bool isNetworkError;

  /// A 422's `errors` map reduced to the first message per field, e.g.
  /// `{label: 'The label field is required.'}`. Empty for other errors.
  final Map<String, String> fieldErrors;

  /// The raw JSON error body, for extra fields such as a 409's `groupId`.
  /// Empty when the response had no JSON object.
  final Map<String, Object?> body;

  bool get isSessionExpired => code == 'session_expired';

  /// Converts anything thrown by a dio call into an [ApiException].
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is AuthRenewalException) {
      return ApiException(
        message: error.isNetworkError
            ? 'Could not reach the server. Check your connection.'
            : 'Could not refresh your sign-in. Please try again.',
        isNetworkError: error.isNetworkError,
      );
    }
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner;
      return ApiException.fromDio(error);
    }
    return ApiException(message: error.toString());
  }

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Could not reach the server. Check your connection.',
          isNetworkError: true,
        );
      default:
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? code;
    String? message;
    final fieldErrors = <String, String>{};
    if (data is Map) {
      code = data['error'] is String ? data['error'] as String : null;
      message = data['message'] is String ? data['message'] as String : null;
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final v = entry.value;
          final first = v is List && v.isNotEmpty ? v.first : v;
          if (first is String) fieldErrors['${entry.key}'] = first;
        }
      }
    }
    return ApiException(
      statusCode: status,
      code: code,
      message:
          message ?? 'Request failed${status == null ? '' : ' ($status)'}.',
      // An unknown low-level failure (e.g. socket closed) is also treated as offline.
      isNetworkError: status == null && e.type == DioExceptionType.unknown,
      fieldErrors: fieldErrors,
      body: data is Map ? Map<String, Object?>.from(data) : const {},
    );
  }

  factory ApiException.sessionExpired(SessionExpiredException _) =>
      const ApiException(
        statusCode: 401,
        code: 'session_expired',
        message: 'Your session has expired. Please sign in again.',
      );

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
