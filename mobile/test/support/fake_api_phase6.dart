import 'package:bpj/core/db/app_database.dart';
import 'package:drift/drift.dart';

/// Phase 6 fixtures matching docs/api-contract.md (group messaging).
Map<String, Object?> messageJson(
  String id, {
  String groupId = 'g1',
  String memberId = 'other',
  String authorName = 'Sam B.',
  String authorRole = 'member',
  String body = 'Hello',
  String createdAt = '2026-10-12T17:30:00.000Z',
  String? deletedAt,
  // A leaders-thread ask (D125): kind 'ask' with its pace in seconds per km.
  String kind = 'message',
  int? askFast,
  int? askSlow,
}) => {
  'id': id,
  'groupId': groupId,
  'memberId': memberId,
  'authorName': authorName,
  'authorRole': authorRole,
  'kind': kind,
  'body': deletedAt == null ? body : '',
  'askFastSPerKm': askFast,
  'askSlowSPerKm': askSlow,
  'createdAt': createdAt,
  'deletedAt': deletedAt,
};

/// The `GET …/messages` body.
Map<String, Object?> messagesBody(
  List<Map<String, Object?>> items, {
  String serverTime = '2026-10-12T18:00:00.000Z',
  bool closed = false,
  bool muted = false,
}) => {
  'items': items,
  'serverTime': serverTime,
  'closed': closed,
  'muted': muted,
};

Map<String, Object?> threadJson(
  String groupId, {
  String sessionId = 's1',
  String label = '9:00-9:30/mi',
  String localDate = '2026-10-12',
  String lastBody = 'See you there',
  String lastAuthor = 'Sam B.',
  String lastAt = '2026-10-12T17:30:00.000Z',
  int unreadCount = 0,
  bool muted = false,
  bool closed = false,
}) => {
  'groupId': groupId,
  'sessionId': sessionId,
  'label': label,
  'sessionTitle': 'Monday club run',
  'localDate': localDate,
  'localStartTime': '19:00',
  'lastMessage': {
    'authorName': lastAuthor,
    'body': lastBody,
    'createdAt': lastAt,
  },
  'unreadCount': unreadCount,
  'muted': muted,
  'closed': closed,
};

Map<String, Object?> threadsBody(List<Map<String, Object?>> items) => {
  'items': items,
  'serverTime': '2026-10-12T18:00:00.000Z',
};

/// Stores the caller's membership of club 1 so `send` can name the author.
Future<void> seedMembership(
  AppDatabase db, {
  String memberId = 'me',
  String firstName = 'Jo',
}) => db
    .into(db.memberships)
    .insert(
      MembershipsCompanion.insert(
        memberId: memberId,
        clubId: 1,
        clubName: 'Black Pear Joggers',
        clubSlug: 'bpj',
        status: 'active',
        firstName: Value(firstName),
        updatedAt: DateTime.utc(2026, 10, 7),
      ),
    );

/// A message row as the repository stores it (for seeding).
Future<void> seedMessage(
  AppDatabase db,
  String id, {
  String groupId = 'g1',
  String memberId = 'other',
  String authorName = 'Sam B.',
  String authorRole = 'member',
  String body = 'Hello',
  DateTime? createdAt,
  DateTime? deletedAt,
  String sendState = 'sent',
}) => db
    .into(db.groupMessages)
    .insert(
      GroupMessagesCompanion.insert(
        id: id,
        clubId: 1,
        groupId: groupId,
        memberId: memberId,
        authorName: authorName,
        authorRole: Value(authorRole),
        body: body,
        createdAt: createdAt ?? DateTime.utc(2026, 10, 12, 17, 30),
        deletedAt: Value(deletedAt),
        sendState: Value(sendState),
      ),
    );

/// Stores a thread-state row (for seeding).
Future<void> seedThread(
  AppDatabase db,
  String groupId, {
  String? sessionId = 's1',
  String? label = '9:00-9:30/mi',
  String? localDate = '2026-10-12',
  DateTime? lastMessageAt,
  String? lastBody = 'See you there',
  String? lastAuthor = 'Sam B.',
  int unreadCount = 0,
  bool muted = false,
  bool closed = false,
}) => db
    .into(db.threadStates)
    .insertOnConflictUpdate(
      ThreadStatesCompanion.insert(
        groupId: groupId,
        clubId: 1,
        sessionId: Value(sessionId),
        label: Value(label),
        localDate: Value(localDate),
        lastMessageAt: Value(
          lastMessageAt ?? DateTime.utc(2026, 10, 12, 17, 30),
        ),
        lastBody: Value(lastBody),
        lastAuthor: Value(lastAuthor),
        unreadCount: Value(unreadCount),
        muted: Value(muted),
        closed: Value(closed),
      ),
    );
