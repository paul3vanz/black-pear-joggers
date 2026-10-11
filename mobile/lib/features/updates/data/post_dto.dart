import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// One item of `GET /app/clubs/{clubId}/posts`.
class PostDto {
  const PostDto({
    required this.id,
    required this.title,
    required this.bodyMd,
    required this.priority,
    required this.audience,
    required this.publishedAt,
    required this.pinnedUntil,
    required this.authorMemberId,
    required this.authorName,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String title;
  final String bodyMd;
  final String priority;
  final String audience;
  final DateTime publishedAt;
  final DateTime? pinnedUntil;
  final String authorMemberId;
  final String authorName;
  final DateTime updatedAt;

  /// Non-null for a tombstone: the post was deleted and must be removed locally.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory PostDto.fromJson(Map<String, Object?> json) {
    final author = (json['author'] as Map<String, Object?>?) ?? const {};
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);
    final publishedAt = date(json['publishedAt']);
    return PostDto(
      id: json['id']! as String,
      title: json['title'] as String? ?? '',
      bodyMd: json['bodyMd'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      audience: json['audience'] as String? ?? 'all',
      publishedAt: publishedAt ?? date(json['updatedAt']) ?? DateTime.now(),
      pinnedUntil: date(json['pinnedUntil']),
      authorMemberId: author['memberId'] as String? ?? '',
      authorName: author['displayName'] as String? ?? '',
      updatedAt: date(json['updatedAt']) ?? publishedAt ?? DateTime.now(),
      deletedAt: date(json['deletedAt']),
    );
  }

  PostsCompanion toCompanion(int clubId) => PostsCompanion.insert(
    id: id,
    clubId: clubId,
    title: title,
    bodyMd: bodyMd,
    priority: Value(priority),
    audience: Value(audience),
    publishedAt: publishedAt,
    pinnedUntil: Value(pinnedUntil),
    authorMemberId: authorMemberId,
    authorName: authorName,
    updatedAt: updatedAt,
  );
}

/// Pinned posts first (those whose `pinnedUntil` is still in the future), then
/// newest first. Stable: it doesn't mutate [posts].
List<Post> sortPosts(List<Post> posts, DateTime now) {
  bool pinned(Post p) => p.pinnedUntil != null && p.pinnedUntil!.isAfter(now);
  return [...posts]..sort((a, b) {
    final pa = pinned(a);
    final pb = pinned(b);
    if (pa != pb) return pa ? -1 : 1;
    return b.publishedAt.compareTo(a.publishedAt);
  });
}

/// True while [post] is pinned at [now].
bool isPinned(Post post, DateTime now) =>
    post.pinnedUntil != null && post.pinnedUntil!.isAfter(now);
