import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/events/data/event_dtos.dart';
import 'package:bpj/features/events/data/event_locations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase8.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late EventLocationsRepository repo;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const list = 'GET /app/clubs/1/event-locations';
  const post = 'POST /app/clubs/1/event-locations';

  void setup(Map<String, Object> routes) {
    adapter = FakeAdapter(routes);
    repo = EventLocationsRepository(
      db,
      fakeDio(adapter),
      newId: () => 'client-uuid',
    );
  }

  Future<List<String>> names() async =>
      (await repo.watch(1).first).map((l) => l.name).toList();

  group('DTO', () {
    test('parses a full row and a tombstone', () {
      final dto = EventLocationDto.fromJson(
        eventLocationJson(
          'a',
          slug: 'worcester',
          region: 'Worcestershire',
          lat: 52.19,
          lng: -2.22,
          url: 'https://www.parkrun.org.uk/worcester/',
        ),
      );
      expect(dto.kind, 'parkrun');
      expect(dto.slug, 'worcester');
      expect(dto.lat, 52.19);
      expect(dto.isDeleted, isFalse);
      final gone = EventLocationDto.fromJson(
        eventLocationJson('b', deletedAt: '2026-10-05T00:00:00.000Z'),
      );
      expect(gone.isDeleted, isTrue);
    });

    test('missing fields fall back and empty strings become null', () {
      final dto = EventLocationDto.fromJson({
        'id': 'x',
        'region': '',
        'url': '',
      });
      expect(dto.kind, 'other');
      expect(dto.name, '');
      expect(dto.region, isNull);
      expect(dto.url, isNull);
      expect(dto.source, 'manual');
    });
  });

  group('refresh', () {
    test('the first call has no since; the cursor is sent after', () async {
      setup({
        list: FakeResponse(
          200,
          eventLocationsResponse([
            eventLocationJson('b', name: 'Bromsgrove parkrun'),
            eventLocationJson('a', name: 'Abbey parkrun'),
          ], serverTime: 'T1'),
        ),
      });
      await repo.refresh(1);
      expect(adapter.requests.single.queryParameters, isEmpty);
      // Live rows come back ordered by name.
      expect(await names(), ['Abbey parkrun', 'Bromsgrove parkrun']);

      await repo.refresh(1);
      expect(adapter.requests.last.queryParameters, {'since': 'T1'});
      final cursor = await (db.select(
        db.syncCursors,
      )..where((c) => c.key.equals('eventLocations:1'))).getSingle();
      expect(cursor.serverTime, 'T1');
    });

    test('changes update rows and tombstones hide them', () async {
      var call = 0;
      setup({
        list: () {
          call++;
          return call == 1
              ? FakeResponse(
                  200,
                  eventLocationsResponse([
                    eventLocationJson('a', name: 'Abbey parkrun'),
                    eventLocationJson('b', name: 'Bromsgrove parkrun'),
                    eventLocationJson('c', name: 'Cannon Hill parkrun'),
                  ], serverTime: 'T1'),
                )
              : FakeResponse(
                  200,
                  eventLocationsResponse([
                    eventLocationJson('a', name: 'Abbey Park parkrun'),
                    eventLocationJson(
                      'b',
                      name: 'Bromsgrove parkrun',
                      deletedAt: '2026-10-06T00:00:00.000Z',
                    ),
                  ], serverTime: 'T2'),
                );
        },
      });
      await repo.refresh(1);
      await repo.refresh(1);
      expect(await names(), ['Abbey Park parkrun', 'Cannon Hill parkrun']);
      // The tombstone is kept, but filtered out of the live stream.
      expect(await db.select(db.eventLocations).get(), hasLength(3));
    });

    test('other clubs are not mixed in', () async {
      setup({
        list: FakeResponse(
          200,
          eventLocationsResponse([eventLocationJson('a')]),
        ),
      });
      await repo.refresh(1);
      expect(await repo.watch(2).first, isEmpty);
    });

    test('a network failure leaves the cache and cursor alone', () async {
      setup({
        list: FakeResponse(
          200,
          eventLocationsResponse([eventLocationJson('a')]),
        ),
      });
      await repo.refresh(1);
      setup({});
      await expectLater(repo.refresh(1), throwsA(isA<ApiException>()));
      expect(await names(), ['Worcester parkrun']);
    });

    test('800 rows refresh in one go', () async {
      setup({
        list: FakeResponse(
          200,
          eventLocationsResponse([
            for (var i = 0; i < 800; i++)
              eventLocationJson(
                'id$i',
                name: 'Event ${i.toString().padLeft(3, '0')}',
              ),
          ]),
        ),
      });
      await repo.refresh(1);
      final rows = await repo.watch(1).first;
      expect(rows, hasLength(800));
      expect(rows.first.name, 'Event 000');
    });
  });

  group('writes', () {
    test('create posts a client uuid and caches the 201 row', () async {
      setup({
        post: FakeResponse(
          201,
          eventLocationJson(
            'client-uuid',
            kind: 'race',
            name: 'Droitwich 10k',
            region: 'Worcestershire',
            source: 'manual',
          ),
        ),
      });
      final row = await repo.create(
        1,
        kind: 'race',
        name: 'Droitwich 10k',
        region: 'Worcestershire',
      );
      expect(row.id, 'client-uuid');
      final sent = adapter.requests.single.data as Map;
      expect(sent['id'], 'client-uuid');
      expect(sent['kind'], 'race');
      expect(sent['name'], 'Droitwich 10k');
      expect(sent['region'], 'Worcestershire');
      expect(sent['url'], isNull);
      expect(await names(), ['Droitwich 10k']);
    });

    test('kind defaults to other', () async {
      setup({post: FakeResponse(201, eventLocationJson('client-uuid'))});
      await repo.create(1, name: 'Fun run');
      expect((adapter.requests.single.data as Map)['kind'], 'other');
    });

    test('a 200 answer is the existing row and is used as is', () async {
      // The server already had this race under another id.
      setup({
        post: FakeResponse(
          200,
          eventLocationJson(
            'existing-id',
            kind: 'race',
            name: 'Droitwich 10k',
            source: 'manual',
          ),
        ),
      });
      final row = await repo.create(1, kind: 'race', name: 'droitwich 10K');
      expect(row.id, 'existing-id');
      expect(row.name, 'Droitwich 10k');
      expect(await repo.watch(1).first, hasLength(1));
    });

    test('a member adding a parkrun gets 403', () async {
      setup({
        post: const FakeResponse(403, {
          'code': 'forbidden',
          'message': 'Committee only',
        }),
      });
      await expectLater(
        repo.create(1, kind: 'parkrun', name: 'Somewhere parkrun'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
      expect(await repo.watch(1).first, isEmpty);
    });

    test('update patches and caches the row', () async {
      setup({
        list: FakeResponse(
          200,
          eventLocationsResponse([eventLocationJson('a', name: 'Old name')]),
        ),
        'PATCH /app/clubs/1/event-locations/a': FakeResponse(
          200,
          eventLocationJson('a', name: 'New name', region: 'Worcs'),
        ),
      });
      await repo.refresh(1);
      final row = await repo.update(
        1,
        'a',
        kind: 'parkrun',
        name: 'New name',
        region: 'Worcs',
        lat: 52.1,
        lng: -2.2,
      );
      expect(row.name, 'New name');
      final sent = adapter.requests.last.data as Map;
      expect(sent['lat'], 52.1);
      expect(sent['kind'], 'parkrun');
      expect(await names(), ['New name']);
    });

    test('update and delete as a member surface the 403', () async {
      setup({
        'PATCH /app/clubs/1/event-locations/a': const FakeResponse(403, {
          'code': 'forbidden',
          'message': 'no',
        }),
        'DELETE /app/clubs/1/event-locations/a': const FakeResponse(403, {
          'code': 'forbidden',
          'message': 'no',
        }),
      });
      await expectLater(
        repo.update(1, 'a', kind: 'race', name: 'X'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(repo.delete(1, 'a'), throwsA(isA<ApiException>()));
    });

    test('delete removes the row locally after the server agrees', () async {
      setup({
        list: FakeResponse(
          200,
          eventLocationsResponse([eventLocationJson('a')]),
        ),
        'DELETE /app/clubs/1/event-locations/a': const FakeResponse(204),
      });
      await repo.refresh(1);
      await repo.delete(1, 'a');
      expect(await repo.watch(1).first, isEmpty);
    });

    test(
      'offline create throws a network ApiException and caches nothing',
      () async {
        setup({});
        await expectLater(
          repo.create(1, kind: 'race', name: 'X'),
          throwsA(
            isA<ApiException>().having((e) => e.isNetworkError, 'net', true),
          ),
        );
        expect(await repo.watch(1).first, isEmpty);
      },
    );
  });
}
