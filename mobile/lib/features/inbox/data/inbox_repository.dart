import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';

part 'inbox_repository.g.dart';

/// One item of `GET /app/clubs/{clubId}/notifications`.
class InboxItemDto {
  const InboxItemDto({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String category;
  final String title;
  final String body;
  final Map<String, Object?> data;
  final DateTime createdAt;
  final DateTime? readAt;

  factory InboxItemDto.fromJson(Map<String, Object?> json) => InboxItemDto(
    id: json['id']! as String,
    category: json['category'] as String? ?? 'club_updates',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    data: Map<String, Object?>.from(json['data'] as Map? ?? const {}),
    createdAt: DateTime.parse(json['createdAt']! as String),
    readAt: json['readAt'] == null
        ? null
        : DateTime.parse(json['readAt']! as String),
  );
}

/// The `route` deep link of an inbox row, if it has one.
String? routeOf(InboxItem item) {
  try {
    final data = jsonDecode(item.dataJson);
    final route = data is Map ? data['route'] : null;
    return route is String && route.startsWith('/') ? route : null;
  } on FormatException {
    return null;
  }
}

/// Cache-first notification inbox. Marking read updates the local row first
/// (`readPending` = not yet confirmed by the server), then POSTs. If the POST
/// fails the local state stays and the next [refresh] retries it.
class InboxRepository {
  InboxRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  static String cursorKey(int clubId) => 'inbox:$clubId';

  /// Newest first.
  Stream<List<InboxItem>> watchInbox(int clubId) =>
      (_db.select(_db.inboxItems)
            ..where((i) => i.clubId.equals(clubId))
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .watch();

  Stream<int> watchUnreadCount(int clubId) {
    final count = _db.inboxItems.id.count();
    final query = _db.selectOnly(_db.inboxItems)
      ..addColumns([count])
      ..where(
        _db.inboxItems.clubId.equals(clubId) & _db.inboxItems.readAt.isNull(),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> refresh(int clubId) async {
    try {
      await _flushPending(clubId);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow; // other failures: retry next time
    }
    final cursor = await (_db.select(
      _db.syncCursors,
    )..where((c) => c.key.equals(cursorKey(clubId)))).getSingleOrNull();
    final response = await guardApi(
      () => _dio.get<Object?>(
        '/app/clubs/$clubId/notifications',
        queryParameters: {if (cursor != null) 'since': cursor.serverTime},
      ),
    );
    final body = jsonObject(response);
    final items = [
      for (final item in (body['items'] as List<Object?>? ?? const []))
        InboxItemDto.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
    final serverTime = body['serverTime'] as String?;
    await _db.transaction(() async {
      final pending = {
        for (final row
            in await (_db.select(_db.inboxItems)..where(
                  (i) => i.clubId.equals(clubId) & i.readPending.equals(true),
                ))
                .get())
          row.id: row,
      };
      for (final dto in items) {
        final local = pending[dto.id];
        // A local read the server hasn't confirmed wins over an unread server row.
        final keepLocal = local != null && dto.readAt == null;
        await _db
            .into(_db.inboxItems)
            .insertOnConflictUpdate(
              InboxItemsCompanion.insert(
                id: dto.id,
                clubId: clubId,
                category: dto.category,
                title: dto.title,
                body: dto.body,
                dataJson: Value(jsonEncode(dto.data)),
                createdAt: dto.createdAt,
                readAt: Value(keepLocal ? local.readAt : dto.readAt),
                readPending: Value(keepLocal),
              ),
            );
      }
      if (serverTime != null) {
        await _db
            .into(_db.syncCursors)
            .insertOnConflictUpdate(
              SyncCursorsCompanion.insert(
                key: cursorKey(clubId),
                serverTime: serverTime,
              ),
            );
      }
    });
  }

  /// Marks [ids] read locally, then tells the server. A network failure is
  /// swallowed (retried on the next refresh); other API errors propagate.
  Future<void> markRead(int clubId, List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(
      _db.inboxItems,
    )..where((i) => i.id.isIn(ids) & i.readAt.isNull())).write(
      InboxItemsCompanion(
        readAt: Value(_now()),
        readPending: const Value(true),
      ),
    );
    await _postRead(clubId, {'ids': ids}, ids: ids);
  }

  Future<void> markAllRead(int clubId) async {
    await (_db.update(
      _db.inboxItems,
    )..where((i) => i.clubId.equals(clubId) & i.readAt.isNull())).write(
      InboxItemsCompanion(
        readAt: Value(_now()),
        readPending: const Value(true),
      ),
    );
    await _postRead(clubId, {'all': true});
  }

  Future<void> _flushPending(int clubId) async {
    final ids = [
      for (final row
          in await (_db.select(_db.inboxItems)..where(
                (i) => i.clubId.equals(clubId) & i.readPending.equals(true),
              ))
              .get())
        row.id,
    ];
    if (ids.isEmpty) return;
    await _postRead(clubId, {'ids': ids}, ids: ids);
  }

  Future<void> _postRead(
    int clubId,
    Map<String, Object?> payload, {
    List<String>? ids,
  }) async {
    try {
      await guardApi(
        () => _dio.post<Object?>(
          '/app/clubs/$clubId/notifications/read',
          data: payload,
        ),
      );
    } on ApiException catch (e) {
      if (e.isNetworkError) return;
      rethrow;
    }
    await (_db.update(_db.inboxItems)..where(
          (i) =>
              i.clubId.equals(clubId) &
              i.readPending.equals(true) &
              (ids == null ? const Constant(true) : i.id.isIn(ids)),
        ))
        .write(const InboxItemsCompanion(readPending: Value(false)));
  }
}

@Riverpod(keepAlive: true)
InboxRepository inboxRepository(Ref ref) => InboxRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
