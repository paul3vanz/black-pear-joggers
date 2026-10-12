import '../../../core/db/app_database.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

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
}
