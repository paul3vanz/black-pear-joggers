import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/updates/data/posts_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase2.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late PostsRepository repo;
  final now = DateTime.utc(2026, 10, 7, 12);

  setUp(() {
    db = memoryDb();
    adapter = FakeAdapter({});
    repo = PostsRepository(db, fakeDio(adapter), clock: () => now);
  });
  tearDown(() => db.close());

  test('refresh upserts and passes the serverTime cursor next time', () async {
    adapter.routes['GET /app/clubs/1/posts'] = FakeResponse(200, {
      'items': [postJson('a', title: 'First')],
      'serverTime': '2026-10-07T12:00:00.000Z',
    });
    await repo.refresh(1);
    expect(adapter.requests.last.queryParameters, isEmpty);

    // `since` is >=, so the same post can come back: it must upsert.
    adapter.routes['GET /app/clubs/1/posts'] = FakeResponse(200, {
      'items': [postJson('a', title: 'First (edited)')],
      'serverTime': '2026-10-07T12:05:00.000Z',
    });
    await repo.refresh(1);
    expect(adapter.requests.last.queryParameters, {
      'since': '2026-10-07T12:00:00.000Z',
    });

    final posts = await repo.watchPosts(1).first;
    expect(posts.map((p) => p.title), ['First (edited)']);
    expect(posts.single.authorName, 'Sam Chair');
  });

  test('tombstones delete the local row', () async {
    adapter.routes['GET /app/clubs/1/posts'] = FakeResponse(200, {
      'items': [postJson('a'), postJson('b')],
      'serverTime': '2026-10-07T12:00:00.000Z',
    });
    await repo.refresh(1);
    adapter.routes['GET /app/clubs/1/posts'] = FakeResponse(200, {
      'items': [postJson('a', deletedAt: '2026-10-07T12:01:00.000Z')],
      'serverTime': '2026-10-07T12:02:00.000Z',
    });
    await repo.refresh(1);
    final posts = await repo.watchPosts(1).first;
    expect(posts.map((p) => p.id), ['b']);
  });

  test('pinned first, then newest first; expired pins do not count', () async {
    adapter.routes['GET /app/clubs/1/posts'] = FakeResponse(200, {
      'items': [
        postJson('old', publishedAt: '2026-10-01T10:00:00.000Z'),
        postJson('new', publishedAt: '2026-10-06T10:00:00.000Z'),
        postJson(
          'pinned',
          publishedAt: '2026-09-01T10:00:00.000Z',
          pinnedUntil: '2026-11-01T00:00:00.000Z',
        ),
        postJson(
          'expired-pin',
          publishedAt: '2026-10-03T10:00:00.000Z',
          pinnedUntil: '2026-10-04T00:00:00.000Z',
        ),
      ],
      'serverTime': '2026-10-07T12:00:00.000Z',
    });
    await repo.refresh(1);
    final posts = await repo.watchPosts(1).first;
    expect(posts.map((p) => p.id), ['pinned', 'new', 'expired-pin', 'old']);
  });

  test('create posts with a client UUID and caches the result', () async {
    adapter.routes['POST /app/clubs/1/posts'] = FakeResponse(
      201,
      postJson('client-id', title: 'Hello'),
    );
    final post = await repo.create(
      1,
      title: 'Hello',
      bodyMd: 'Body',
      priority: 'normal',
      audience: 'all',
      notify: true,
      id: 'client-id',
    );
    expect(post.title, 'Hello');
    final sent = adapter.requests.last.data as Map<String, Object?>;
    expect(sent['id'], 'client-id');
    expect(sent['notify'], true);
    expect((await repo.watchPosts(1).first).single.id, 'client-id');
  });

  test('create offline throws a network ApiException', () async {
    // No route registered: the fake adapter simulates a connection error.
    await expectLater(
      repo.create(
        1,
        title: 'T',
        bodyMd: 'B',
        priority: 'normal',
        audience: 'all',
        notify: false,
      ),
      throwsA(
        isA<ApiException>().having((e) => e.isNetworkError, 'offline', true),
      ),
    );
    expect(await repo.watchPosts(1).first, isEmpty);
  });
}
