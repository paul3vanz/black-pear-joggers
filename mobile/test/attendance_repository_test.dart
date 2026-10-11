import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/data/attendance_repository.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/data/summary_dtos.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late AttendanceRepository repo;

  const putKey = 'PUT /app/clubs/1/sessions/a/attendance';
  const getKey = 'GET /app/clubs/1/sessions/a/attendance';

  setUp(() async {
    db = memoryDb();
    await seedSession(
      db,
      'a',
      groups: [groupJson('g1'), groupJson('g2')],
      summary: summaryJson(groupCount: 2, goingCount: 3, maybeCount: 1),
    );
  });
  tearDown(() => db.close());

  void setup(Map<String, Object> routes) {
    adapter = FakeAdapter(routes);
    repo = AttendanceRepository(
      db,
      fakeDio(adapter),
      clock: () => DateTime.utc(2026, 10, 7, 12),
    );
  }

  Future<SessionSummary> summary() async =>
      decodeSummary((await db.select(db.sessions).getSingle()).summaryJson)!;

  Future<List<Group>> groups() async =>
      decodeGroups((await db.select(db.sessions).getSingle()).groupsJson);

  Future<MyAttendanceRow?> mine() =>
      db.select(db.myAttendance).getSingleOrNull();

  test('success: optimistic write, then the server row replaces it', () async {
    setup({
      putKey: FakeResponse(
        200,
        attendanceJson(
          'a',
          groupId: 'g1',
          paceUnit: 'mi',
          paceFromS: 540,
          paceToS: 570,
        ),
      ),
    });
    final result = await repo.setAttendance(
      'a',
      'going',
      groupId: 'g1',
      paceOverride: PaceRange(
        const Pace(540, DistUnit.mi),
        const Pace(570, DistUnit.mi),
      ),
    );
    expect(result.outcome, AttendanceOutcome.saved);
    final row = (await mine())!;
    expect(row.pending, isFalse);
    expect(row.groupId, 'g1');
    expect(row.pace, isA<PaceRange>());
    final body = adapter.requests.single.data as Map;
    expect(body, {
      'status': 'going',
      'groupId': 'g1',
      'paceUnit': 'mi',
      'paceFromS': 540,
      'paceToS': 570,
    });
    final s = await summary();
    expect(s.myStatus, 'going');
    expect(s.myGroupId, 'g1');
    expect(s.goingCount, 4);
    expect((await groups()).firstWhere((g) => g.id == 'g1').goingCount, 1);
  });

  test('the summary changes before the PUT answers', () async {
    // Offline: the PUT never gets an answer, the optimistic state remains.
    setup({});
    final result = await repo.setAttendance('a', 'maybe');
    expect(result.outcome, AttendanceOutcome.queued);
    expect(result.isOffline, isTrue);
    expect((await mine())!.pending, isTrue);
    final s = await summary();
    expect(s.myStatus, 'maybe');
    expect(s.maybeCount, 2);
    expect(s.goingCount, 3);
  });

  test(
    'changing response moves the counts between statuses and groups',
    () async {
      setup({putKey: FakeResponse(200, attendanceJson('a', groupId: 'g1'))});
      await repo.setAttendance('a', 'going', groupId: 'g1');
      setup({
        putKey: FakeResponse(
          200,
          attendanceJson('a', status: 'maybe', groupId: 'g2'),
        ),
      });
      await repo.setAttendance('a', 'maybe', groupId: 'g2');
      var s = await summary();
      expect(s.goingCount, 3);
      expect(s.maybeCount, 2);
      expect(s.myGroupId, 'g2');
      final gs = await groups();
      expect(gs.firstWhere((g) => g.id == 'g1').goingCount, 0);
      expect(gs.firstWhere((g) => g.id == 'g2').maybeCount, 1);

      setup({
        putKey: FakeResponse(200, attendanceJson('a', status: 'not_going')),
      });
      await repo.setAttendance('a', 'not_going', groupId: 'g2');
      s = await summary();
      expect(s.maybeCount, 1);
      expect(s.myStatus, 'not_going');
      expect(s.myGroupId, isNull);
      // not_going sends no group or pace.
      expect(adapter.requests.single.data, {'status': 'not_going'});
    },
  );

  test('retryPending re-sends and clears the pending flag', () async {
    setup({});
    await repo.setAttendance('a', 'going', groupId: 'g1');
    expect((await mine())!.pending, isTrue);

    setup({putKey: FakeResponse(200, attendanceJson('a', groupId: 'g1'))});
    await repo.retryPending(1);
    expect(adapter.requests, hasLength(1));
    expect((await mine())!.pending, isFalse);
    // Counts were adjusted once, not twice.
    expect((await summary()).goingCount, 4);

    await repo.retryPending(1);
    expect(adapter.requests, hasLength(1), reason: 'nothing pending any more');
  });

  test('a server error keeps the row pending', () async {
    setup({
      putKey: const FakeResponse(503, {'error': 'unavailable'}),
    });
    final result = await repo.setAttendance('a', 'going');
    expect(result.outcome, AttendanceOutcome.queued);
    expect((await mine())!.pending, isTrue);
  });

  for (final code in ['session_cancelled', 'session_past']) {
    test('409 $code drops the pending row and reverts', () async {
      setup({
        putKey: FakeResponse(409, {'error': code, 'message': 'Nope'}),
        getKey: const FakeResponse(200, null),
      });
      final result = await repo.setAttendance('a', 'going', groupId: 'g1');
      expect(result.outcome, AttendanceOutcome.rejected);
      expect(result.error?.code, code);
      expect(await mine(), isNull);
      final s = await summary();
      expect(s.myStatus, isNull);
      expect(s.goingCount, 3);
      expect((await groups()).first.goingCount, 0);
    });
  }

  test('a refused change reverts to what the server has', () async {
    // The server already has "maybe"; a refused "going" goes back to it.
    setup({}); // offline: pending maybe
    await repo.setAttendance('a', 'maybe');
    setup({
      putKey: const FakeResponse(409, {'error': 'session_past'}),
      getKey: FakeResponse(200, attendanceJson('a', status: 'maybe')),
    });
    final result = await repo.setAttendance('a', 'going');
    expect(result.outcome, AttendanceOutcome.rejected);
    final row = (await mine())!;
    expect(row.status, 'maybe');
    expect(row.pending, isFalse);
    expect((await summary()).myStatus, 'maybe');
  });

  test('a 422 is rejected, not retried forever', () async {
    setup({
      putKey: const FakeResponse(422, {'error': 'validation_failed'}),
      getKey: const FakeResponse(200, null),
    });
    final result = await repo.setAttendance('a', 'going', groupId: 'gone');
    expect(result.outcome, AttendanceOutcome.rejected);
    expect(await mine(), isNull);
  });

  test('an expired session is rethrown and the row stays pending', () async {
    setup({
      putKey: const FakeResponse(401, {'error': 'session_expired'}),
    });
    await expectLater(
      repo.setAttendance('a', 'going'),
      throwsA(isA<ApiException>()),
    );
    expect((await mine())!.pending, isTrue);
  });

  test('watchMyAttendance emits the row', () async {
    setup({});
    expect(await repo.watchMyAttendance('a').first, isNull);
    await repo.setAttendance('a', 'going');
    expect((await repo.watchMyAttendance('a').first)?.status, 'going');
  });

  test('a sessions refresh keeps a pending response on screen', () async {
    setup({});
    await repo.setAttendance('a', 'going');
    final runs = RunsRepository(
      db,
      fakeDio(
        FakeAdapter({
          'GET /app/clubs/1/sessions': FakeResponse(200, {
            'items': [
              sessionWithGroups(
                'a',
                localDate: '2026-10-12',
                summary: summaryJson(goingCount: 3),
              ),
            ],
            'serverTime': 'T',
          }),
          'GET /app/clubs/1/venues': FakeResponse(200, {
            'items': <Object?>[],
            'serverTime': 'T',
          }),
          'GET /app/clubs/1/series': FakeResponse(200, {
            'items': <Object?>[],
            'serverTime': 'T',
          }),
        }),
      ),
      clock: () => DateTime(2026, 10, 7, 12),
    );
    await runs.refresh(1);
    final s = await summary();
    expect(s.myStatus, 'going');
    expect(s.goingCount, 4);
  });

  test('runs refresh retries pending responses first', () async {
    setup({});
    await repo.setAttendance('a', 'going');
    final adapter2 = FakeAdapter({
      putKey: FakeResponse(200, attendanceJson('a')),
      'GET /app/clubs/1/sessions': FakeResponse(200, {
        'items': <Object?>[],
        'serverTime': 'T',
      }),
      'GET /app/clubs/1/venues': FakeResponse(200, {
        'items': <Object?>[],
        'serverTime': 'T',
      }),
      'GET /app/clubs/1/series': FakeResponse(200, {
        'items': <Object?>[],
        'serverTime': 'T',
      }),
    });
    final dio = fakeDio(adapter2);
    final retrier = AttendanceRepository(db, dio);
    final runs = RunsRepository(
      db,
      dio,
      clock: () => DateTime(2026, 10, 7, 12),
      flushPending: retrier.retryPending,
    );
    await runs.refresh(1);
    expect(adapter2.requests.first.method, 'PUT');
    expect((await mine())!.pending, isFalse);
  });
}
