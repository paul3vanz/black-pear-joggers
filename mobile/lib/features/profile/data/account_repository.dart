import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';

/// The word the member must type, and the value the server checks (D72).
const deleteConfirmWord = 'DELETE';

/// Account-level calls that aren't tied to one club. Failures are thrown as
/// `ApiException` (via [guardApi]).
class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  /// `DELETE /app/account`: removes this login's app data on the server (profile
  /// card, chat messages, sign-ups, devices, the link to the club membership).
  /// Resolves on 204 (also on a replay). Throws `ApiException` otherwise:
  /// 409 `last_admin`, a network error, or `session_expired`.
  ///
  /// Not optimistic: callers must wait for this before touching local data.
  Future<void> deleteAccount() => guardApi(
    () => _dio.delete<Object?>(
      '/app/account',
      // dio JSON-encodes a Map body, like `axios.delete(url, { data })`.
      data: const {'confirm': deleteConfirmWord},
    ),
  );
}

/// Hand-written (not `@riverpod`) so there is nothing to regenerate.
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);
