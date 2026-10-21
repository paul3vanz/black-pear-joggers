import '../../../core/db/app_database.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// The thread id of a run's leaders thread (D125): where a group id would go,
/// `leaders:<sessionId>`. The messages and thread tables key on it like a
/// group id, so the same cache and screens serve both.
const leadersThreadPrefix = 'leaders:';

bool isLeadersThread(String threadId) =>
    threadId.startsWith(leadersThreadPrefix);

String leadersThreadId(String sessionId) => '$leadersThreadPrefix$sessionId';

String leadersSessionId(String threadId) =>
    threadId.substring(leadersThreadPrefix.length);

/// The thread id of the comments on a club update (D126): `post:<postId>`.
const postThreadPrefix = 'post:';

bool isPostThread(String threadId) => threadId.startsWith(postThreadPrefix);

String postThreadId(String postId) => '$postThreadPrefix$postId';

String postIdOfThread(String threadId) =>
    threadId.substring(postThreadPrefix.length);

/// A committee "can anyone lead 8:25-10:05/mi?" message. The local message
/// table has no columns for it, so an ask is stored in `body` as
/// `␞ask␞<fast>␞<slow>␞<note>` (seconds per km, empty for any pace) and
/// decoded for display. The mark is U+241E, which nobody types. Move these into
/// columns at the next schema bump.
class AskBody {
  const AskBody({this.fastSPerKm, this.slowSPerKm, this.note = ''});

  final int? fastSPerKm;
  final int? slowSPerKm;
  final String note;

  /// An ask for a pace range (both ends), not "any pace".
  bool get hasPace => fastSPerKm != null && slowSPerKm != null;
}

const _askMark = '␞';

String encodeAskBody(AskBody ask) =>
    '${_askMark}ask$_askMark${ask.fastSPerKm ?? ''}$_askMark'
    '${ask.slowSPerKm ?? ''}$_askMark${ask.note}';

/// The ask a stored [body] holds, or null for an ordinary message.
AskBody? decodeAskBody(String body) {
  if (!body.startsWith('${_askMark}ask$_askMark')) return null;
  final parts = body.split(_askMark);
  if (parts.length < 5) return null;
  return AskBody(
    fastSPerKm: int.tryParse(parts[2]),
    slowSPerKm: int.tryParse(parts[3]),
    note: parts.sublist(4).join(_askMark),
  );
}

/// A message as the API sends it (docs/api-contract.md, Phase 6).
class MessageDto {
  const MessageDto({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.createdAt,
    this.deletedAt,
    this.ask,
  });

  final String id;
  final String groupId;
  final String memberId;
  final String authorName;
  final String authorRole;
  final String body;
  final DateTime createdAt;

  /// Set on a tombstone (the body is then empty).
  final DateTime? deletedAt;

  /// Set on a leaders-thread ask (`kind: ask`): the pace and the committee's note.
  final AskBody? ask;

  /// What the message table stores: the text, or an encoded [ask].
  String get storedBody => ask == null ? body : encodeAskBody(ask!);

  bool get isDeleted => deletedAt != null;

  factory MessageDto.fromJson(Map<String, Object?> json) => MessageDto(
    id: json['id']! as String,
    groupId: json['groupId'] as String? ?? '',
    memberId: json['memberId'] as String? ?? '',
    authorName: json['authorName'] as String? ?? 'Member',
    authorRole: json['authorRole'] as String? ?? 'member',
    body: json['body'] as String? ?? '',
    createdAt: _date(json['createdAt']) ?? DateTime.now(),
    deletedAt: _date(json['deletedAt']),
    ask: json['kind'] == 'ask' && json['deletedAt'] == null
        ? AskBody(
            fastSPerKm: (json['askFastSPerKm'] as num?)?.toInt(),
            slowSPerKm: (json['askSlowSPerKm'] as num?)?.toInt(),
            note: json['body'] as String? ?? '',
          )
        : null,
  );
}

/// One entry of `GET …/threads`.
class ThreadDto {
  const ThreadDto({
    required this.groupId,
    required this.sessionId,
    required this.label,
    required this.localDate,
    required this.lastMessageAt,
    required this.lastBody,
    required this.lastAuthor,
    required this.unreadCount,
    required this.muted,
    required this.closed,
  });

  final String groupId;
  final String sessionId;
  final String? label;
  final String? localDate;
  final DateTime? lastMessageAt;
  final String? lastBody;
  final String? lastAuthor;
  final int unreadCount;
  final bool muted;
  final bool closed;

  factory ThreadDto.fromJson(Map<String, Object?> json) {
    final last = json['lastMessage'];
    final lastMap = last is Map ? Map<String, Object?>.from(last) : null;
    final label = json['label'];
    return ThreadDto(
      groupId: json['groupId']! as String,
      sessionId: json['sessionId'] as String? ?? '',
      label: label is String && label.isNotEmpty ? label : null,
      localDate: json['localDate'] as String?,
      lastMessageAt: _date(lastMap?['createdAt']),
      lastBody: lastMap?['body'] as String?,
      lastAuthor: lastMap?['authorName'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      muted: json['muted'] as bool? ?? false,
      closed: json['closed'] as bool? ?? false,
    );
  }
}

/// How a message is shown in a thread.
extension GroupMessageState on GroupMessage {
  bool get isDeleted => deletedAt != null;
  bool get isPending => sendState == 'pending';
  bool get isFailed => sendState == 'failed';

  /// The ask this holds (a leaders-thread request), if it is one.
  AskBody? get ask => isDeleted ? null : decodeAskBody(body);
}
