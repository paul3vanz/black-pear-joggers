import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import 'member_dtos.dart';

part 'members_repository.g.dart';

/// Committee tools: search club members and grant or remove the `leader` badge
/// (D24). Online-only, nothing is cached. Throws `ApiException` (403 `forbidden`
/// for anyone without the rights).
class MembersRepository {
  MembersRepository(this._dio);

  final Dio _dio;

  /// Members whose name matches [q], ordered by name (50 per page by default).
  Future<List<MemberItem>> search(
    int clubId,
    String q, {
    int limit = 50,
  }) async {
    final body = jsonObject(
      await guardApi(
        () => _dio.get<Object?>(
          '/app/clubs/$clubId/members',
          queryParameters: {'q': q, 'limit': limit},
        ),
      ),
    );
    return [
      for (final item in (body['items'] as List<Object?>? ?? const []))
        if (item is Map) MemberItem.fromJson(Map<String, Object?>.from(item)),
    ];
  }

  /// Replaces [memberId]'s role set (e.g. `['leader']`) and returns the member.
  Future<MemberItem> setRoles(
    int clubId,
    String memberId,
    List<String> roles,
  ) async => MemberItem.fromJson(
    jsonObject(
      await guardApi(
        () => _dio.patch<Object?>(
          '/app/clubs/$clubId/members/$memberId/roles',
          data: {'roles': roles},
        ),
      ),
    ),
  );
}

@Riverpod(keepAlive: true)
MembersRepository membersRepository(Ref ref) =>
    MembersRepository(ref.watch(apiClientProvider));
