import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../../groups/data/small_kv_store.dart';

/// One member's state for an update, as the committee sees it.
enum ReceiptState {
  none,
  delivered,
  read;

  static ReceiptState parse(String? value) => ReceiptState.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ReceiptState.none,
  );
}

class ReceiptMember {
  const ReceiptMember({
    required this.memberId,
    required this.displayName,
    required this.state,
  });

  final String memberId;
  final String displayName;
  final ReceiptState state;
}

/// `GET /posts/{id}/receipts`: who an update was for and what they have done.
class PostReceipts {
  const PostReceipts({
    required this.audienceCount,
    required this.deliveredCount,
    required this.readCount,
    required this.members,
  });

  final int audienceCount;

  /// Includes the ones who have read it.
  final int deliveredCount;
  final int readCount;
  final List<ReceiptMember> members;

  factory PostReceipts.fromJson(Map<String, Object?> json) => PostReceipts(
    audienceCount: (json['audienceCount'] as num?)?.toInt() ?? 0,
    deliveredCount: (json['deliveredCount'] as num?)?.toInt() ?? 0,
    readCount: (json['readCount'] as num?)?.toInt() ?? 0,
    members: [
      for (final m in (json['members'] as List<Object?>? ?? const []))
        if (m is Map)
          ReceiptMember(
            memberId: m['memberId'] as String? ?? '',
            displayName: m['displayName'] as String? ?? '',
            state: ReceiptState.parse(m['state'] as String?),
          ),
    ],
  );
}

/// Reports this phone's own delivered / read state for club updates (D123),
/// and reads the committee's view back.
///
/// Nothing here is a setting: every cached update is reported as delivered, and
/// as read once the member has read it to the end. What has already been sent
/// is remembered per update in the small key/value store, so an offline phone
/// just sends the rest next time ([sync] runs after every posts refresh).
class PostReceiptsRepository {
  PostReceiptsRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  SmallKvStore get _kv => SmallKvStore(_db);

  /// `d` or `r`: the furthest state already accepted by the server.
  static String sentKey(int clubId, String postId) =>
      'postReceipt:$clubId:$postId';

  /// When the member finished reading (ISO), kept until it has been sent.
  static String readKey(int clubId, String postId) =>
      'postReadAt:$clubId:$postId';

  static const _batch = 100;

  /// Remembers that this update has been read to the end. The first time wins.
  Future<void> markRead(int clubId, String postId) async {
    final key = readKey(clubId, postId);
    if (await _kv.get(key) != null) return;
    await _kv.set(key, _now().toUtc().toIso8601String());
  }

  /// Sends whatever the server has not been told yet. [myMemberId] skips the
  /// member's own posts (the server ignores them anyway). Quiet on failure.
  Future<void> sync(int clubId, {String? myMemberId}) async {
    final posts = await (_db.select(
      _db.posts,
    )..where((p) => p.clubId.equals(clubId))).get();
    final items = <Map<String, Object?>>[];
    final sentLevel = <String, String>{};
    for (final p in posts) {
      if (myMemberId != null && p.authorMemberId == myMemberId) continue;
      final sent = await _kv.get(sentKey(clubId, p.id));
      final readAt = await _kv.get(readKey(clubId, p.id));
      if (readAt != null && sent != 'r') {
        items.add({'postId': p.id, 'state': 'read', 'at': readAt});
        sentLevel[p.id] = 'r';
      } else if (sent == null) {
        items.add({
          'postId': p.id,
          'state': 'delivered',
          'at': _now().toUtc().toIso8601String(),
        });
        sentLevel[p.id] = 'd';
      }
    }
    for (var i = 0; i < items.length; i += _batch) {
      final chunk = items.sublist(i, (i + _batch).clamp(0, items.length));
      try {
        await guardApi(
          () => _dio.post<Object?>(
            '/app/clubs/$clubId/posts/receipts',
            data: {'items': chunk},
          ),
        );
      } on ApiException {
        // Offline or refused: try again after the next refresh.
        return;
      }
      for (final item in chunk) {
        final id = item['postId']! as String;
        await _kv.set(sentKey(clubId, id), sentLevel[id]!);
      }
    }
  }

  /// [sync] that never throws, for fire-and-forget after a refresh.
  Future<void> syncQuietly(int clubId, {String? myMemberId}) async {
    try {
      await sync(clubId, myMemberId: myMemberId);
    } on Object {
      // Receipts are best effort; the next refresh tries again.
    }
  }

  /// The committee's view of one update. Throws [ApiException] (403 for a
  /// member who isn't committee, a network error offline).
  Future<PostReceipts> fetch(int clubId, String postId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('/app/clubs/$clubId/posts/$postId/receipts'),
    );
    return PostReceipts.fromJson(jsonObject(response));
  }
}

final postReceiptsRepositoryProvider = Provider<PostReceiptsRepository>(
  (ref) => PostReceiptsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
  ),
);
