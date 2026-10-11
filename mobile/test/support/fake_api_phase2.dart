/// Phase 2 fixtures matching docs/api-contract.md.
Map<String, Object?> postJson(
  String id, {
  String title = 'Title',
  String publishedAt = '2026-10-05T10:00:00.000Z',
  String? pinnedUntil,
  String priority = 'normal',
  String? deletedAt,
}) => {
  'id': id,
  'title': title,
  'bodyMd': 'Body of **$title**',
  'priority': priority,
  'audience': 'all',
  'publishedAt': publishedAt,
  'pinnedUntil': pinnedUntil,
  'author': {'memberId': 'member-9', 'displayName': 'Sam Chair'},
  'updatedAt': publishedAt,
  'deletedAt': deletedAt,
};

Map<String, Object?> inboxJson(
  String id, {
  String createdAt = '2026-10-05T10:00:00.000Z',
  String? readAt,
  String route = '/updates/p1',
}) => {
  'id': id,
  'category': 'club_updates',
  'title': 'Notification $id',
  'body': 'Body $id',
  'data': {'route': route},
  'createdAt': createdAt,
  'readAt': readAt,
};
