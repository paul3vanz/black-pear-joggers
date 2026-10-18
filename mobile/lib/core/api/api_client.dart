import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/accounts_controller.dart';
import '../auth/auth_service.dart';
import '../config/env.dart';
import '../diagnostics/diagnostics.dart';
import '../diagnostics/diagnostics_interceptor.dart';
import 'api_exception.dart';

part 'api_client.g.dart';

/// dio interceptor ≈ an axios interceptor. For the account [sub] it:
///  1. attaches `Authorization: Bearer <token>` (renewing the token first if needed);
///  2. on a 401, forces a renewal and replays the request ONCE;
///  3. turns every failure into a [DioException] whose `error` is an [ApiException].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.auth,
    required this.sub,
    this.diagnostics,
  });

  final Dio dio;
  final AuthService auth;
  final String? sub;

  /// Told about failures this interceptor creates itself (rejecting in
  /// `onRequest` skips the other error interceptors). Null in tests.
  final DiagnosticsInterceptor? diagnostics;

  static const _retriedKey = 'authRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final sub = this.sub;
    if (sub == null) return handler.next(options);
    try {
      final token = await auth.getValidAccessToken(sub);
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } on SessionExpiredException catch (e) {
      diagnostics?.recordAuthFailure(options, sessionExpired: true);
      handler.reject(_wrap(options, ApiException.sessionExpired(e)));
    } on Object catch (e) {
      // e.g. a network error while renewing the token.
      diagnostics?.recordAuthFailure(options, sessionExpired: false, error: e);
      handler.reject(_wrap(options, ApiException.from(e)));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final sub = this.sub;
    final options = err.requestOptions;
    final alreadyMapped = err.error is ApiException;

    if (!alreadyMapped &&
        err.response?.statusCode == 401 &&
        sub != null &&
        options.extra[_retriedKey] != true) {
      try {
        final token = await auth.getValidAccessToken(sub, forceRenew: true);
        options.extra[_retriedKey] = true;
        options.headers['Authorization'] = 'Bearer $token';
        return handler.resolve(await dio.fetch<Object?>(options));
      } on SessionExpiredException catch (e) {
        diagnostics?.recordAuthFailure(options, sessionExpired: true);
        return handler.reject(_wrap(options, ApiException.sessionExpired(e)));
      } on DioException catch (e) {
        return handler.reject(_wrap(options, ApiException.from(e), e.response));
      } on Object catch (e) {
        return handler.reject(_wrap(options, ApiException.from(e)));
      }
    }

    handler.next(
      alreadyMapped
          ? err
          : _wrap(options, ApiException.fromDio(err), err.response),
    );
  }

  DioException _wrap(
    RequestOptions options,
    ApiException error, [
    Response<Object?>? response,
  ]) => DioException(
    requestOptions: options,
    response: response,
    error: error,
    message: error.message,
    type: error.isNetworkError
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

/// A dio instance whose requests are authenticated as account [sub] (not
/// necessarily the active one). Used by [apiClient] and for per-account calls such
/// as push-token registration.
Dio buildApiClient({
  required AuthService auth,
  required String? sub,
  Diagnostics? diagnostics,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
  // The diagnostics interceptor goes first so it sees raw errors (timeout vs bad
  // certificate vs 5xx) before the auth interceptor maps them (D100).
  final diag = diagnostics == null ? null : DiagnosticsInterceptor(diagnostics);
  if (diag != null) dio.interceptors.add(diag);
  dio.interceptors.add(
    AuthInterceptor(dio: dio, auth: auth, sub: sub, diagnostics: diag),
  );
  return dio;
}

/// The dio instance for the active account. It watches [activeSub], so switching
/// account builds a fresh client bound to the new account's tokens.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final sub = ref.watch(activeSubProvider);
  final dio = buildApiClient(
    auth: ref.watch(authServiceProvider),
    sub: sub,
    diagnostics: ref.watch(diagnosticsProvider),
  );
  ref.onDispose(dio.close);
  return dio;
}
