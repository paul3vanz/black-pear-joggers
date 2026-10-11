import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Runs a dio call and converts any failure into an [ApiException], so callers only
/// need one `on ApiException catch`. (Same as an axios wrapper that always throws
/// your own `ApiError`.)
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw ApiException.from(e);
  }
}

/// A JSON object response body as a typed map.
Map<String, Object?> jsonObject(Response<Object?> response) =>
    response.data! as Map<String, Object?>;
