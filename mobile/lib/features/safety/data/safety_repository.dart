import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';

/// What a report is about. The values are the API's `kind`.
enum ReportKind {
  message('message'),
  leaderMessage('leader_message'),
  comment('comment'),
  profile('profile');

  const ReportKind(this.api);

  final String api;
}

/// Why it is being reported. The values are the API's `reason`.
enum ReportReason {
  spam('spam', 'Spam'),
  abusive('abusive', 'Abusive or bullying'),
  inappropriate('inappropriate', 'Inappropriate or offensive'),
  other('other', 'Something else');

  const ReportReason(this.api, this.label);

  final String api;
  final String label;
}

/// Report and block (Apple guideline 1.2).
///
/// Blocking is personal and done on the phone: the blocked members' messages and
/// profile cards are hidden from the screens that show them. The list is kept in
/// the small key/value table (id -> name, as JSON) so it works offline and is
/// per account like the rest of the database. The server holds the same list so
/// it survives a reinstall; [refresh] pulls it. Blocking, unblocking and
/// reporting need a connection and change nothing locally until the server says
/// yes.
class SafetyRepository {
  SafetyRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  static String blockedKey(int clubId) => 'blockedMembers:$clubId';

  /// Blocked members as id -> display name, live.
  Stream<Map<String, String>> watchBlocked(int clubId) =>
      (_db.select(_db.syncCursors)
            ..where((c) => c.key.equals(blockedKey(clubId))))
          .watchSingleOrNull()
          .map((row) => _decode(row?.serverTime));

  static Map<String, String> _decode(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final data = jsonDecode(json);
      if (data is! Map) return const {};
      return {for (final e in data.entries) '${e.key}': '${e.value}'};
    } on FormatException {
      return const {};
    }
  }

  Future<Map<String, String>> _stored(int clubId) async => _decode(
    (await (_db.select(
          _db.syncCursors,
        )..where((c) => c.key.equals(blockedKey(clubId)))).getSingleOrNull())
        ?.serverTime,
  );

  Future<void> _save(int clubId, Map<String, String> blocked) => _db
      .into(_db.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          key: blockedKey(clubId),
          serverTime: jsonEncode(blocked),
        ),
      );

  /// Replaces the local list with the server's. Errors (offline) propagate; the
  /// caller ignores them and keeps the saved list.
  Future<void> refresh(int clubId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('/app/clubs/$clubId/blocks'),
    );
    final items = (jsonObject(response)['items'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    await _save(clubId, {
      for (final i in items)
        i['memberId']! as String: '${i['name'] ?? 'Member'}',
    });
  }

  Future<void> block(int clubId, String memberId, String name) async {
    final response = await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/blocks',
        data: {'memberId': memberId},
      ),
    );
    final shown = jsonObject(response)['name'] as String? ?? name;
    await _save(clubId, {...await _stored(clubId), memberId: shown});
  }

  Future<void> unblock(int clubId, String memberId) async {
    await guardApi(
      () => _dio.delete<Object?>('/app/clubs/$clubId/blocks/$memberId'),
    );
    final blocked = {...await _stored(clubId)}..remove(memberId);
    await _save(clubId, blocked);
  }

  /// Tells the committee. [targetId] is the message or comment (null for a card).
  Future<void> report(
    int clubId, {
    required ReportKind kind,
    required String reportedMemberId,
    required ReportReason reason,
    String? targetId,
    String? details,
  }) async {
    final text = details?.trim() ?? '';
    await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/reports',
        data: {
          'kind': kind.api,
          'targetId': ?targetId,
          'reportedMemberId': reportedMemberId,
          'reason': reason.api,
          if (text.isNotEmpty) 'details': text,
        },
      ),
    );
  }
}

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
  ),
);
