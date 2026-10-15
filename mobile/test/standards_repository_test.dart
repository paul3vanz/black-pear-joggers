import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/standards/data/standards_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase9.dart';

const _path = '/app/clubs/1/standards';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late StandardsRepository repo;
  var now = DateTime.utc(2026, 10, 15, 10);

  setUp(() {
    now = DateTime.utc(2026, 10, 15, 10);
    db = memoryDb();
    adapter = FakeAdapter({});
    repo = StandardsRepository(db, fakeDio(adapter), clock: () => now);
  });
  tearDown(() => db.close());

  test('nothing cached until the first refresh', () async {
    expect(await repo.watch(1).first, isNull);
  });

  test(
    'a 200 is cached with its ETag and read back through the stream',
    () async {
      adapter.routes['GET $_path'] = FakeResponse(200, standardsJson(), {
        'etag': '"v1"',
      });
      await repo.refresh(1);

      final cached = (await repo.watch(1).first)!;
      expect(cached.fetchedAt.toUtc(), now);
      expect(cached.data.events, hasLength(3));
      expect(cached.data.mine?.category, 'V50');
      final row = await db.select(db.standardsCache).getSingle();
      expect(row.etag, '"v1"');
      // The first request had nothing to revalidate.
      expect(
        adapter.requests.single.headers.containsKey('If-None-Match'),
        isFalse,
      );
    },
  );

  test('a 304 keeps the cached body and only moves fetchedAt', () async {
    adapter.routes['GET $_path'] = FakeResponse(200, standardsJson(), {
      'etag': '"v1"',
    });
    await repo.refresh(1);

    now = DateTime.utc(2026, 10, 18, 10);
    adapter.routes['GET $_path'] = const FakeResponse(304);
    await repo.refresh(1);

    expect(adapter.requests.last.headers['If-None-Match'], '"v1"');
    final cached = (await repo.watch(1).first)!;
    expect(cached.fetchedAt.toUtc(), now);
    expect(cached.data.items, isNotEmpty);
    expect((await db.select(db.standardsCache).getSingle()).etag, '"v1"');
  });

  test('a changed table replaces the body and the ETag', () async {
    adapter.routes['GET $_path'] = FakeResponse(200, standardsJson(), {
      'etag': '"v1"',
    });
    await repo.refresh(1);
    adapter.routes['GET $_path'] = FakeResponse(
      200,
      standardsJson(mine: null),
      {'etag': '"v2"'},
    );
    await repo.refresh(1);

    expect(adapter.requests.last.headers['If-None-Match'], '"v1"');
    expect((await repo.watch(1).first)!.data.mine, isNull);
    expect((await db.select(db.standardsCache).getSingle()).etag, '"v2"');
  });

  test('offline keeps the cached copy and throws a network error', () async {
    adapter.routes['GET $_path'] = FakeResponse(200, standardsJson(), {
      'etag': '"v1"',
    });
    await repo.refresh(1);
    final before = (await repo.watch(1).first)!.fetchedAt;

    adapter.routes.remove(
      'GET $_path',
    ); // the fake adapter now fails to connect
    now = DateTime.utc(2026, 10, 16, 10);
    await expectLater(
      repo.refresh(1),
      throwsA(
        isA<ApiException>().having((e) => e.isNetworkError, 'offline', true),
      ),
    );
    final after = (await repo.watch(1).first)!;
    expect(after.fetchedAt, before);
    expect(after.data.items, isNotEmpty);
  });

  test('a server error is an ApiException and leaves the cache', () async {
    adapter.routes['GET $_path'] = const FakeResponse(500, {
      'error': 'server_error',
    });
    await expectLater(
      repo.refresh(1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)),
    );
    expect(await repo.watch(1).first, isNull);
  });

  test(
    'a response without an ETag is cached and refetched in full next time',
    () async {
      adapter.routes['GET $_path'] = FakeResponse(200, standardsJson());
      await repo.refresh(1);
      await repo.refresh(1);
      expect(
        adapter.requests.last.headers.containsKey('If-None-Match'),
        isFalse,
      );
      expect((await db.select(db.standardsCache).getSingle()).etag, isNull);
    },
  );
}
