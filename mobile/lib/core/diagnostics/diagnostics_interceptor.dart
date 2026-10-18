import 'dart:io';

import 'package:dio/dio.dart';

import 'diagnostics.dart';
import 'redaction.dart';

/// Records every failed API request in the diagnostics log, and the first success
/// after a failure ("recovered"). dio interceptor ~ axios interceptor.
///
/// It logs the method, the path WITHOUT its query string, the status and a short
/// failure label, and nothing else: no request or response bodies, no headers.
///
/// Register it BEFORE the auth interceptor so it sees the raw error (timeout vs
/// bad certificate vs 5xx) before that one maps it to an `ApiException`. Failures
/// the auth interceptor creates itself (session expired, token read failures)
/// reach [recordAuthFailure] directly, because rejecting in `onRequest` skips
/// every error interceptor.
class DiagnosticsInterceptor extends Interceptor {
  DiagnosticsInterceptor(this.diagnostics);

  final Diagnostics diagnostics;

  /// True between a failure and the next success, so only the first success
  /// after trouble is logged.
  bool _failing = false;

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    markSuccess(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    recordFailure(err);
    handler.next(err);
  }

  void markSuccess(RequestOptions options) {
    diagnostics.facts['Last successful request'] = DateTime.now()
        .toUtc()
        .toIso8601String();
    diagnostics.health.reportApiSuccess();
    if (_failing) {
      _failing = false;
      diagnostics.record(
        DiagArea.api,
        'recovered: request succeeded again',
        path: requestPath(options),
      );
    }
  }

  void recordFailure(DioException err) {
    final options = err.requestOptions;
    final status = err.response?.statusCode;
    final kind = classify(err);
    // The app cancelled it: not a failure.
    if (kind.label == 'cancelled') return;
    _failing = true;
    var label = kind.label;
    if (status == 401) {
      label = options.extra['authRetried'] == true
          ? 'unauthorized after token renewal'
          : 'unauthorized (renewing token and retrying)';
    }
    diagnostics.record(
      DiagArea.api,
      '${options.method} failed: $label',
      level: kind.level,
      status: status,
      path: requestPath(options),
    );
    final healthClass = kind.healthClass;
    if (healthClass == null) return;
    if (healthClass.startsWith('local:')) {
      diagnostics.health.reportLocalError();
    } else {
      diagnostics.health.reportApiFailure(healthClass);
    }
  }

  /// The auth interceptor could not get a token (`session_expired`, or a
  /// credentials-store failure such as a keystore read error).
  void recordAuthFailure(
    RequestOptions options, {
    required bool sessionExpired,
    Object? error,
  }) {
    _failing = true;
    diagnostics.record(
      DiagArea.auth,
      sessionExpired
          ? 'session_expired'
          : 'token unavailable: ${error == null ? 'unknown' : describeError(error)}',
      level: sessionExpired ? DiagLevel.warn : DiagLevel.error,
      status: sessionExpired ? 401 : null,
      path: requestPath(options),
    );
  }
}

/// What kind of failure a [DioException] is.
class FailureKind {
  const FailureKind(this.label, this.level, [this.healthClass]);

  /// Short label for the log, e.g. `timeout`, `server error`.
  final String label;
  final DiagLevel level;

  /// Class for the "everything fails" detector: `5xx` or `local:<Type>`. Null
  /// for offline, 401 and ordinary 4xx answers, which never count.
  final String? healthClass;
}

FailureKind classify(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const FailureKind('timeout', DiagLevel.warn);
    case DioExceptionType.connectionError:
      return const FailureKind('network', DiagLevel.warn);
    case DioExceptionType.badCertificate:
      return const FailureKind('bad certificate', DiagLevel.error);
    case DioExceptionType.cancel:
      return const FailureKind('cancelled', DiagLevel.info);
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode ?? 0;
      if (status >= 500) {
        return const FailureKind('server error', DiagLevel.error, '5xx');
      }
      return FailureKind(
        status == 401 ? 'unauthorized' : 'client error',
        DiagLevel.warn,
      );
    case DioExceptionType.unknown:
      final inner = e.error;
      if (inner is HandshakeException || inner is TlsException) {
        return const FailureKind('bad certificate', DiagLevel.error);
      }
      if (inner is SocketException || inner is HttpException || inner == null) {
        return const FailureKind('network', DiagLevel.warn);
      }
      // Something thrown inside the app's own code (a TypeError while decoding,
      // for instance): a local problem, not the network's.
      final type = inner.runtimeType;
      return FailureKind(
        'local error: ${describeError(inner)}',
        DiagLevel.error,
        'local:$type',
      );
  }
}

/// The request path without host, query string or fragment.
String requestPath(RequestOptions o) {
  final raw = o.path;
  final path = raw.startsWith('http') ? Uri.tryParse(raw)?.path ?? '' : raw;
  return safePath(path);
}
