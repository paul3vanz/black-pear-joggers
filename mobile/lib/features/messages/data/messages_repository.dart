import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import 'message_dtos.dart';

part 'messages_repository.g.dart';

/// The longest message the server accepts.
const maxMessageLength = 1000;

/// How a send (or retry) ended.
enum SendOutcome {
  /// The server has it.
  sent,

  /// Still to be sent (offline, a server hiccup or rate limited). The row stays
  /// `pending` and is retried on the next refresh, open or reconnect.
  queued,

  /// The server refused it for good (not in the group, thread closed, invalid).
  /// The row is `failed` and shows Retry / Delete.
  failed,
}

class SendResult {
  const SendResult(this.outcome, [this.error]);

  final SendOutcome outcome;
  final ApiException? error;
}

/// Group chat (D39-D44): cache-first like the other repositories. The UI watches
/// [watchThread]; [refresh] pulls `?since=` deltas (tombstones included). Sending
/// uses an outbox like attendance (D23/D43): the message is stored `pending`
/// with a client UUID, POSTed, and re-POSTed (idempotent) until the server
/// accepts or refuses it. Deleting, muting and refreshing need a connection.
class MessagesRepository {
  MessagesRepository(
    this._db,
    this._dio, {
    DateTime Function()? clock,
    String Function()? newId,
    this.rateLimitDelay = const Duration(seconds: 20),
  }) : _now = clock ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;
  final String Function() _newId;

  /// How long a message the server answered 429 for waits before the next try.
  final Duration rateLimitDelay;

  /// Message id -> earliest time to try it again (only after a 429).
  final _notBefore = <String, DateTime>{};

  static String cursorKey(int clubId, String groupId) =>
      'messages:$clubId:$groupId';

  /// Key (in the small key/value table) remembering the dismissed info line.
  static const infoDismissedKey = 'chatInfoDismissed';

  String _base(int clubId, String groupId) =>
      '/app/clubs/$clubId/groups/$groupId';

  // --- Reads -----------------------------------------------------------

  /// The thread, oldest first.
  Stream<List<GroupMessage>> watchThread(String groupId) =>
      (_db.select(_db.groupMessages)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([
              (m) => OrderingTerm.asc(m.createdAt),
              (m) => OrderingTerm.asc(m.id),
            ]))
          .watch();

  Stream<ThreadState?> watchThreadState(String groupId) => (_db.select(
    _db.threadStates,
  )..where((t) => t.groupId.equals(groupId))).watchSingleOrNull();

  /// Threads from `GET …/threads` that have a message, newest first.
  Stream<List<ThreadState>> watchThreads(int clubId) =>
      (_db.select(_db.threadStates)
            ..where(
              (t) =>
                  t.clubId.equals(clubId) &
                  t.sessionId.isNotNull() &
                  t.lastMessageAt.isNotNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch();

  Future<GroupMessage?> _message(String id) => (_db.select(
    _db.groupMessages,
  )..where((m) => m.id.equals(id))).getSingleOrNull();

  // --- Sync ------------------------------------------------------------

  Future<String?> _cursor(String key) async => (await (_db.select(
    _db.syncCursors,
  )..where((c) => c.key.equals(key))).getSingleOrNull())?.serverTime;

  Future<void> _saveCursor(String key, String? serverTime) async {
    if (serverTime == null) return;
    await _db
        .into(_db.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(key: key, serverTime: serverTime),
        );
  }

  /// Sends any unsent messages of the thread, then pulls new ones (`?since=`
  /// after the first call) and stores `closed` / `muted`. A 403/404 means the
  /// caller is no longer in the group (or it is gone): the local copy is
  /// dropped and the `ApiException` is rethrown for the screen to react to.
  Future<void> refresh(int clubId, String groupId) async {
    try {
      await _flush(groupId: groupId);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow; // other failures: retry next time
    }
    final key = cursorKey(clubId, groupId);
    final since = await _cursor(key);
    final Map<String, Object?> body;
    try {
      final response = await guardApi(
        () => _dio.get<Object?>(
          '${_base(clubId, groupId)}/messages',
          queryParameters: {'since': ?since},
        ),
      );
      body = jsonObject(response);
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) {
        await forgetThread(groupId);
      }
      rethrow;
    }
    final dtos = [
      for (final item in (body['items'] as List<Object?>? ?? const []))
        MessageDto.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
    await _db.transaction(() async {
      for (final dto in dtos) {
        if (dto.isDeleted) {
          // A tombstone for a message we never had is not worth showing, so
          // this only updates a row that exists.
          await (_db.update(
            _db.groupMessages,
          )..where((m) => m.id.equals(dto.id))).write(
            GroupMessagesCompanion(
              body: const Value(''),
              deletedAt: Value(dto.deletedAt),
              sendState: const Value('sent'),
            ),
          );
        } else {
          await _storeServerMessage(clubId, groupId, dto);
        }
      }
      await _saveCursor(key, body['serverTime'] as String?);
      await _db
          .into(_db.threadStates)
          .insertOnConflictUpdate(
            ThreadStatesCompanion.insert(
              groupId: groupId,
              clubId: clubId,
              closed: Value.absentIfNull(body['closed'] as bool?),
              muted: Value.absentIfNull(body['muted'] as bool?),
            ),
          );
    });
  }

  Future<void> _storeServerMessage(
    int clubId,
    String groupId,
    MessageDto dto,
  ) => _db
      .into(_db.groupMessages)
      .insertOnConflictUpdate(
        GroupMessagesCompanion.insert(
          id: dto.id,
          clubId: clubId,
          groupId: groupId,
          memberId: dto.memberId,
          authorName: dto.authorName,
          authorRole: Value(dto.authorRole),
          body: dto.body,
          createdAt: dto.createdAt,
          deletedAt: Value(dto.deletedAt),
          sendState: const Value('sent'),
        ),
      );

  /// Replaces the threads list from `GET …/threads` (unread counts, mute, last
  /// message). Threads the server no longer lists (the caller left the group,
  /// or the group is gone) are dropped with their local messages.
  Future<void> refreshThreads(int clubId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('/app/clubs/$clubId/threads'),
    );
    final dtos = [
      for (final item
          in (jsonObject(response)['items'] as List<Object?>? ?? const []))
        ThreadDto.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
    final listed = {for (final d in dtos) d.groupId};
    await _db.transaction(() async {
      for (final dto in dtos) {
        await _db
            .into(_db.threadStates)
            .insertOnConflictUpdate(
              ThreadStatesCompanion.insert(
                groupId: dto.groupId,
                clubId: clubId,
                sessionId: Value(dto.sessionId),
                label: Value(dto.label),
                localDate: Value(dto.localDate),
                lastMessageAt: Value(dto.lastMessageAt),
                lastBody: Value(dto.lastBody),
                lastAuthor: Value(dto.lastAuthor),
                unreadCount: Value(dto.unreadCount),
                muted: Value(dto.muted),
                closed: Value(dto.closed),
              ),
            );
      }
      // Only rows that an earlier listing created can have disappeared from it.
      final gone = [
        for (final row
            in await (_db.select(_db.threadStates)..where(
                  (t) => t.clubId.equals(clubId) & t.sessionId.isNotNull(),
                ))
                .get())
          if (!listed.contains(row.groupId)) row.groupId,
      ];
      for (final id in gone) {
        await forgetThread(id);
      }
    });
  }

  /// [refreshThreads] for callers where threads only decorate the screen (unread
  /// dots, the Inbox list): any failure but an expired session is ignored.
  Future<void> refreshThreadsQuietly(int clubId) async {
    try {
      await refreshThreads(clubId);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow;
    }
  }

  /// Drops everything stored locally for a thread (access lost).
  Future<void> forgetThread(String groupId) async {
    await (_db.delete(
      _db.groupMessages,
    )..where((m) => m.groupId.equals(groupId))).go();
    await (_db.delete(
      _db.threadStates,
    )..where((t) => t.groupId.equals(groupId))).go();
    await (_db.delete(
      _db.syncCursors,
    )..where((c) => c.key.like('messages:%:$groupId'))).go();
  }

  // --- Sending ---------------------------------------------------------

  /// Adds [body] to the thread at once (as `pending`) and POSTs it. [body] is
  /// trimmed and must be 1-1000 characters. See [SendOutcome].
  Future<SendResult> send(int clubId, String groupId, String body) async {
    final text = body.trim();
    if (text.isEmpty || text.length > maxMessageLength) {
      throw ArgumentError.value(body, 'body', 'must be 1-$maxMessageLength');
    }
    final me = await (_db.select(
      _db.memberships,
    )..where((m) => m.clubId.equals(clubId))).getSingleOrNull();
    if (me == null) {
      throw StateError('send: no membership cached for club $clubId');
    }
    final id = _newId();
    await _db
        .into(_db.groupMessages)
        .insert(
          GroupMessagesCompanion.insert(
            id: id,
            clubId: clubId,
            groupId: groupId,
            memberId: me.memberId,
            authorName: me.firstName ?? 'Me',
            body: text,
            createdAt: _now(),
            sendState: const Value('pending'),
          ),
        );
    return _post((await _message(id))!);
  }

  /// Re-sends a message that failed (the user tapped Retry).
  Future<SendResult> retry(String messageId) async {
    final row = await _message(messageId);
    if (row == null || row.sendState == 'sent') {
      return const SendResult(SendOutcome.sent);
    }
    await (_db.update(_db.groupMessages)..where((m) => m.id.equals(messageId)))
        .write(const GroupMessagesCompanion(sendState: Value('pending')));
    _notBefore.remove(messageId);
    return _post(row);
  }

  /// Removes a message that never reached the server.
  Future<void> discard(String messageId) async {
    _notBefore.remove(messageId);
    await (_db.delete(_db.groupMessages)
          ..where((m) => m.id.equals(messageId) & m.sendState.equals('failed')))
        .go();
  }

  /// Re-sends every unsent message for [clubId] (app resumed, back online).
  /// Stops at the first that can't be sent; rethrows an expired session.
  Future<void> retryPending(int clubId) => _flush(clubId: clubId);

  Future<void> _flush({int? clubId, String? groupId}) async {
    final rows =
        await (_db.select(_db.groupMessages)
              ..where(
                (m) =>
                    m.sendState.equals('pending') &
                    (groupId == null
                        ? const Constant(true)
                        : m.groupId.equals(groupId)) &
                    (clubId == null
                        ? const Constant(true)
                        : m.clubId.equals(clubId)),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
            .get();
    final now = _now();
    for (final row in rows) {
      final wait = _notBefore[row.id];
      if (wait != null && wait.isAfter(now)) return; // rate limited: keep order
      final result = await _post(row);
      if (result.outcome == SendOutcome.queued) return; // offline: stop
    }
  }

  Future<SendResult> _post(GroupMessage row) async {
    try {
      final response = await guardApi(
        () => _dio.post<Object?>(
          '${_base(row.clubId, row.groupId)}/messages',
          data: {'id': row.id, 'body': row.body},
        ),
      );
      final dto = MessageDto.fromJson(jsonObject(response));
      _notBefore.remove(row.id);
      // Not when the row was removed meanwhile (never resurrect it).
      if (await _message(row.id) != null) {
        await _storeServerMessage(row.clubId, row.groupId, dto);
      }
      return const SendResult(SendOutcome.sent);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow; // stays pending
      final status = e.statusCode;
      if (status == 429) {
        _notBefore[row.id] = _now().add(rateLimitDelay);
        return SendResult(SendOutcome.queued, e);
      }
      final transient =
          e.isNetworkError || status == null || status >= 500 || status == 408;
      if (transient) return SendResult(SendOutcome.queued, e);
      await (_db.update(_db.groupMessages)..where((m) => m.id.equals(row.id)))
          .write(const GroupMessagesCompanion(sendState: Value('failed')));
      return SendResult(SendOutcome.failed, e);
    }
  }

  // --- Moderation, read state, mute (online) -----------------------------

  /// Deletes a message: shown as a tombstone straight away and put back if
  /// the server refuses (or can't be reached), rethrowing the error.
  Future<void> delete(String messageId) async {
    final row = await _message(messageId);
    if (row == null || row.isDeleted) return;
    await (_db.update(
      _db.groupMessages,
    )..where((m) => m.id.equals(messageId))).write(
      GroupMessagesCompanion(body: const Value(''), deletedAt: Value(_now())),
    );
    try {
      await guardApi(
        () => _dio.delete<Object?>(
          '${_base(row.clubId, row.groupId)}/messages/$messageId',
        ),
      );
    } on ApiException {
      await (_db.update(
        _db.groupMessages,
      )..where((m) => m.id.equals(messageId))).write(
        GroupMessagesCompanion(
          body: Value(row.body),
          deletedAt: Value(row.deletedAt),
        ),
      );
      rethrow;
    }
  }

  /// Zeroes the unread count locally, then tells the server. Returns false when
  /// offline (the caller tries again later); other API errors propagate.
  Future<bool> markRead(int clubId, String groupId) async {
    await (_db.update(_db.threadStates)
          ..where((t) => t.groupId.equals(groupId)))
        .write(const ThreadStatesCompanion(unreadCount: Value(0)));
    try {
      await guardApi(
        () => _dio.post<Object?>('${_base(clubId, groupId)}/messages/read'),
      );
      return true;
    } on ApiException catch (e) {
      if (e.isNetworkError) return false;
      rethrow;
    }
  }

  /// Mutes or unmutes the thread's notifications (needs a connection).
  Future<void> setMuted(int clubId, String groupId, bool muted) async {
    final response = await guardApi(
      () => _dio.put<Object?>(
        '${_base(clubId, groupId)}/thread',
        data: {'muted': muted},
      ),
    );
    final body = jsonObject(response);
    await _db
        .into(_db.threadStates)
        .insertOnConflictUpdate(
          ThreadStatesCompanion.insert(
            groupId: groupId,
            clubId: clubId,
            muted: Value(body['muted'] as bool? ?? muted),
            unreadCount: Value.absentIfNull(
              (body['unreadCount'] as num?)?.toInt(),
            ),
          ),
        );
  }

  // --- Info line ----------------------------------------------------------

  Future<bool> isInfoDismissed() async =>
      await _cursor(infoDismissedKey) != null;

  Future<void> dismissInfo() => _saveCursor(infoDismissedKey, '1');
}

@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) => MessagesRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
