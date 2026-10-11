import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late RunsRepository repo;
  // Wednesday 7 Oct 2026, local noon.
  final now = DateTime(2026, 10, 7, 12);

  FakeResponse empty(String time) =>
      FakeResponse(200, {'items': <Object?>[], 'serverTime': time});

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  void setup(Map<String, Object> routes) {
    adapter = FakeAdapter(routes);
    repo = RunsRepository(
      db,
      fakeDio(adapter),
      clock: () => now,
      newId: () => 'client-uuid',
    );
  }

  Map<String, Object> listRoutes({
    required List<Map<String, Object?>> sessions,
    String serverTime = '2026-10-07T12:00:00.000Z',
  }) => {
    'GET /app/clubs/1/sessions': FakeResponse(200, {
      'items': sessions,
      'serverTime': serverTime,
    }),
    'GET /app/clubs/1/venues': FakeResponse(200, {
      'items': [venueJson('v1')],
      'serverTime': serverTime,
    }),
    'GET /app/clubs/1/series': FakeResponse(200, {
      'items': [seriesJson('s1')],
      'serverTime': serverTime,
    }),
  };

  test('refresh: default window first, then the cursor', () async {
    setup(
      listRoutes(
        sessions: [sessionJson('a', localDate: '2026-10-12')],
        serverTime: 'T1',
      ),
    );
    await repo.refresh(1);
    final first = adapter.requests.firstWhere(
      (r) => r.path.endsWith('/sessions'),
    );
    expect(first.queryParameters, isEmpty);
    expect(await db.select(db.sessions).get(), hasLength(1));
    expect(await db.select(db.venues).get(), hasLength(1));
    expect(await db.select(db.sessionSeries).get(), hasLength(1));

    adapter.requests.clear();
    await repo.refresh(1);
    for (final r in adapter.requests) {
      expect(r.queryParameters['since'], 'T1', reason: r.path);
    }
    final cursors = await db.select(db.syncCursors).get();
    expect(
      cursors.map((c) => c.key),
      containsAll(['sessions:1', 'venues:1', 'series:1']),
    );
  });

  test('tombstones delete local rows', () async {
    setup(
      listRoutes(
        sessions: [
          sessionJson('a', localDate: '2026-10-12'),
          sessionJson('b', localDate: '2026-10-13'),
        ],
      ),
    );
    await repo.refresh(1);
    adapter.routes['GET /app/clubs/1/sessions'] = FakeResponse(200, {
      'items': [
        sessionJson(
          'a',
          localDate: '2026-10-12',
          deletedAt: '2026-10-07T13:00:00Z',
        ),
      ],
      'serverTime': 'T2',
    });
    adapter.routes['GET /app/clubs/1/venues'] = FakeResponse(200, {
      'items': [venueJson('v1', deletedAt: '2026-10-07T13:00:00Z')],
      'serverTime': 'T2',
    });
    adapter.routes['GET /app/clubs/1/series'] = FakeResponse(200, {
      'items': [seriesJson('s1', deletedAt: '2026-10-07T13:00:00Z')],
      'serverTime': 'T2',
    });
    await repo.refresh(1);
    final left = await db.select(db.sessions).get();
    expect(left.map((s) => s.id), ['b']);
    expect(await db.select(db.venues).get(), isEmpty);
    expect(await db.select(db.sessionSeries).get(), isEmpty);
  });

  test('prunes sessions older than 14 days after a refresh', () async {
    setup(
      listRoutes(
        sessions: [
          sessionJson('old', localDate: '2026-09-20'), // 17 days ago
          sessionJson('recent', localDate: '2026-09-30'), // 7 days ago
          sessionJson('future', localDate: '2026-10-12'),
        ],
      ),
    );
    await repo.refresh(1);
    final ids = (await db.select(db.sessions).get()).map((s) => s.id);
    expect(ids, unorderedEquals(['recent', 'future']));
  });

  test(
    'watchUpcomingSessions: today onward, ordered by date and time',
    () async {
      setup(
        listRoutes(
          sessions: [
            sessionJson('late', localDate: '2026-10-12', start: '19:00'),
            sessionJson('early', localDate: '2026-10-12', start: '08:00'),
            sessionJson('today', localDate: '2026-10-07'),
            sessionJson('past', localDate: '2026-10-05'),
            sessionJson('next', localDate: '2026-10-13'),
          ],
        ),
      );
      await repo.refresh(1);
      final upcoming = await repo.watchUpcomingSessions(1).first;
      expect(upcoming.map((s) => s.id), ['today', 'early', 'late', 'next']);
    },
  );

  test('original block is stored for the changed label', () async {
    setup(
      listRoutes(
        sessions: [
          sessionJson(
            'a',
            localDate: '2026-10-12',
            start: '18:30',
            original: {
              'localStartTime': '19:00',
              'venueId': 'v1',
              'title': 'Monday club run',
            },
          ),
        ],
      ),
    );
    await repo.refresh(1);
    final s = await db.select(db.sessions).getSingle();
    expect(s.originalJson, contains('19:00'));
    expect(s.isDetached, isTrue);
  });

  test('cancel and restore update the local row', () async {
    setup({
      ...listRoutes(sessions: [sessionJson('a', localDate: '2026-10-12')]),
      'POST /app/clubs/1/sessions/a/cancel': FakeResponse(
        200,
        sessionJson(
          'a',
          localDate: '2026-10-12',
          status: 'cancelled',
          cancelReason: 'Bank holiday',
        ),
      ),
      'POST /app/clubs/1/sessions/a/restore': FakeResponse(
        200,
        sessionJson('a', localDate: '2026-10-12'),
      ),
    });
    await repo.refresh(1);

    final cancelled = await repo.cancelSession(1, 'a', 'Bank holiday');
    expect(cancelled.status, 'cancelled');
    expect(adapter.requests.last.data, {'reason': 'Bank holiday'});
    expect((await repo.watchSession('a').first)!.cancelReason, 'Bank holiday');

    final restored = await repo.restoreSession(1, 'a');
    expect(restored.status, 'scheduled');
    expect((await repo.watchSession('a').first)!.cancelReason, isNull);
  });

  test('createAdHocSession sends a client uuid and upserts', () async {
    setup({
      'POST /app/clubs/1/sessions': FakeResponse(
        201,
        sessionJson('client-uuid', localDate: '2026-10-20', seriesId: null),
      ),
    });
    final s = await repo.createAdHocSession(
      1,
      title: 'Social run',
      localDate: '2026-10-20',
      startTime: '19:00',
      durationMin: 60,
      groupMode: 'open',
    );
    expect(s.id, 'client-uuid');
    expect((adapter.requests.single.data as Map)['id'], 'client-uuid');
    expect(await db.select(db.sessions).get(), hasLength(1));
  });

  test('series write upserts and re-pulls sessions', () async {
    setup({
      'POST /app/clubs/1/series': FakeResponse(201, seriesJson('client-uuid')),
      'GET /app/clubs/1/sessions': FakeResponse(200, {
        'items': [sessionJson('gen', localDate: '2026-10-12')],
        'serverTime': 'T1',
      }),
    });
    await repo.createSeries(
      1,
      title: 'Monday club run',
      weekday: 1,
      startTime: '19:00',
      durationMin: 90,
      intervalWeeks: 1,
      validFrom: '2026-01-01',
      groupMode: 'paced',
    );
    expect(await db.select(db.sessionSeries).get(), hasLength(1));
    expect(await db.select(db.sessions).get(), hasLength(1));
  });

  test('a 403 surfaces as an ApiException', () async {
    setup({
      'POST /app/clubs/1/sessions/a/cancel': const FakeResponse(403, {
        'error': 'forbidden',
      }),
    });
    await expectLater(
      repo.cancelSession(1, 'a', 'x'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
    );
  });

  test('empty lists are fine', () async {
    setup({
      'GET /app/clubs/1/sessions': empty('T1'),
      'GET /app/clubs/1/venues': empty('T1'),
      'GET /app/clubs/1/series': empty('T1'),
    });
    await repo.refresh(1);
    expect(await db.select(db.sessions).get(), isEmpty);
  });
}
