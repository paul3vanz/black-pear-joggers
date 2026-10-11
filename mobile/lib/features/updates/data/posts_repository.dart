import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import 'post_dto.dart';

part 'posts_repository.g.dart';

/// Cache-first club updates. The UI watches [watchPosts]; [refresh] pulls changes
/// since the last `serverTime` cursor and upserts them (the API's `since` is `>=`,
/// so a row can come back twice). Failures are thrown as `ApiException`.
class PostsRepository {
  PostsRepository(
    this._db,
    this._dio, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _now = clock ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;
  final String Function() _newId;

  static String cursorKey(int clubId) => 'posts:$clubId';

  /// Pinned first, then newest first.
  Stream<List<Post>> watchPosts(int clubId) =>
      (_db.select(_db.posts)
            ..where((p) => p.clubId.equals(clubId))
            ..orderBy([(p) => OrderingTerm.desc(p.publishedAt)]))
          .watch()
          .map((rows) => sortPosts(rows, _now()));

  Stream<Post?> watchPost(String id) => (_db.select(
    _db.posts,
  )..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<void> refresh(int clubId) async {
    final cursor = await (_db.select(
      _db.syncCursors,
    )..where((c) => c.key.equals(cursorKey(clubId)))).getSingleOrNull();
    final response = await guardApi(
      () => _dio.get<Object?>(
        '/app/clubs/$clubId/posts',
        queryParameters: {if (cursor != null) 'since': cursor.serverTime},
      ),
    );
    final body = jsonObject(response);
    final items = [
      for (final item in (body['items'] as List<Object?>? ?? const []))
        PostDto.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
    final serverTime = body['serverTime'] as String?;
    await _db.transaction(() async {
      for (final dto in items) {
        if (dto.isDeleted) {
          await (_db.delete(_db.posts)..where((p) => p.id.equals(dto.id))).go();
        } else {
          await _db
              .into(_db.posts)
              .insertOnConflictUpdate(dto.toCompanion(clubId));
        }
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

  /// Publishes a post (committee/admin only; the server answers 403 otherwise).
  /// Online-only for now: a network failure throws an `ApiException` with
  /// `isNetworkError` set. The client UUID makes a retry idempotent.
  Future<Post> create(
    int clubId, {
    required String title,
    required String bodyMd,
    required String priority,
    required String audience,
    DateTime? pinnedUntil,
    required bool notify,
    String? id,
  }) async {
    final response = await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/posts',
        data: {
          'id': id ?? _newId(),
          'title': title,
          'bodyMd': bodyMd,
          'priority': priority,
          'audience': audience,
          if (pinnedUntil != null)
            'pinnedUntil': pinnedUntil.toUtc().toIso8601String(),
          'notify': notify,
        },
      ),
    );
    final dto = PostDto.fromJson(jsonObject(response));
    await _db.into(_db.posts).insertOnConflictUpdate(dto.toCompanion(clubId));
    return (_db.select(
      _db.posts,
    )..where((p) => p.id.equals(dto.id))).getSingle();
  }
}

@Riverpod(keepAlive: true)
PostsRepository postsRepository(Ref ref) => PostsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
