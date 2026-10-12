import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/data/member_dtos.dart';
import 'package:bpj/features/groups/data/plan_dtos.dart';
import 'package:bpj/features/groups/data/session_local.dart';
import 'package:bpj/features/groups/data/summary_dtos.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';
import 'support/fake_api_phase4.dart';

void main() {
  group('Group.fromJson', () {
    test('event groups carry locationId and createdByMemberId', () {
      final g = Group.fromJson(
        groupJson(
          'e1',
          kind: 'event',
          label: 'Worcester parkrun',
          paceUnit: null,
          paceFromS: null,
          paceToS: null,
          locationId: 'loc-1',
          createdByMemberId: 'm9',
        ),
      );
      expect(g.kind, 'event');
      expect(g.locationId, 'loc-1');
      expect(g.createdByMemberId, 'm9');
      expect(g.pace, isA<NoPace>());
      // They survive the stored-JSON round trip and copyWith.
      final back = decodeGroups(encodeGroups([g.copyWith(goingCount: 2)]))
          .single;
      expect(back.locationId, 'loc-1');
      expect(back.createdByMemberId, 'm9');
      expect(back.goingCount, 2);
      // Older payloads have neither.
      final old = Group.fromJson(groupJson('g2'));
      expect(old.locationId, isNull);
      expect(old.createdByMemberId, isNull);
    });

    test('parses the full contract shape', () {
      final g = Group.fromJson(
        groupJson(
          'g1',
          label: 'Steady',
          distanceValue: 3,
          distanceUnit: 'mi',
          leaders: [leaderJson('m1', role: 'co_leader')],
          goingCount: 5,
          maybeCount: 1,
        ),
      );
      expect(g.id, 'g1');
      expect(g.kind, 'run');
      expect(g.label, 'Steady');
      expect(g.pace, isA<PaceRange>());
      expect(g.pace.display(DistUnit.mi), '9:30-10:00/mi');
      expect(g.distance?.display(DistUnit.km), '4.8 km (3 mi)');
      expect(g.leaders.single.role, 'co_leader');
      expect(g.isLedBy('m1'), isTrue);
      expect(g.isLedBy('zzz'), isFalse);
      expect(g.goingCount, 5);
      expect(g.maybeCount, 1);
      expect(g.sortSecPerKm, 354);
      expect(g.needsLeader, isFalse);
    });

    test('tolerates missing fields', () {
      final g = Group.fromJson({'id': 'g2'});
      expect(g.kind, 'run');
      expect(g.status, 'active');
      expect(g.leaders, isEmpty);
      expect(g.pace, isA<NoPace>());
      expect(g.distance, isNull);
      expect(g.sortSecPerKm, isNull);
      expect(g.goingCount, 0);
      expect(g.updatedAt, isNull);
    });

    test('round trips through toJson', () {
      final g = Group.fromJson(
        groupJson('g1', leaders: [leaderJson('m1')], paceToS: null),
      );
      final again = Group.fromJson(g.toJson());
      expect(again.pace, g.pace);
      expect(again.leaders.single.displayName, 'Jo Bloggs');
      expect(decodeGroups(encodeGroups([g, again])), hasLength(2));
    });

    test('decodeGroups copes with null and garbage', () {
      expect(decodeGroups(null), isEmpty);
      expect(decodeGroups('not json'), isEmpty);
      expect(decodeGroups('{"a":1}'), isEmpty);
      expect(decodeGroups('[1, {"id": "x"}]').single.id, 'x');
    });

    test('sortGroups: fastest first, no pace last', () {
      final sorted = sortGroups([
        Group.fromJson(
          groupJson(
            'none',
            paceUnit: null,
            paceFromS: null,
            paceToS: null,
            paceFromSPerKm: null,
            paceToSPerKm: null,
          ),
        ),
        Group.fromJson(groupJson('slow', paceFromSPerKm: 400)),
        Group.fromJson(groupJson('fast', paceFromSPerKm: 300)),
      ]);
      expect([for (final g in sorted) g.id], ['fast', 'slow', 'none']);
    });
  });

  test('SessionSummary parses, tolerates gaps and copies', () {
    final s = SessionSummary.fromJson(
      summaryJson(groupCount: 3, goingCount: 12, myStatus: 'going'),
    );
    expect(s.groupCount, 3);
    expect(s.myStatus, 'going');
    expect(s.myLeading, isFalse);
    final c = s.copyWith(clearMyStatus: true, goingCount: 11);
    expect(c.myStatus, isNull);
    expect(c.goingCount, 11);
    final empty = SessionSummary.fromJson(const {});
    expect(empty.goingCount, 0);
    expect(empty.myStatus, isNull);
    expect(decodeSummary(null), isNull);
    expect(decodeSummary('nope'), isNull);
    expect(decodeSummary(encodeSummary(s))?.groupCount, 3);
  });

  test('AttendanceDto parses the override pace', () {
    final a = AttendanceDto.fromJson(
      attendanceJson('a', groupId: 'g1', paceUnit: 'km', paceFromS: 330),
    );
    expect(a.groupId, 'g1');
    expect(a.pace, isA<SinglePace>());
    expect(AttendanceDto.fromJson(const {}).status, 'going');
  });

  group('SessionPlan', () {
    final json = {
      'sessionId': 'a',
      'groups': [
        {
          'groupId': 'g1',
          'paces': [
            {'fromSPerKm': 354, 'toSPerKm': null},
          ],
          'attendees': [
            {
              'memberId': 'm2',
              'displayName': 'Sam Lapsed',
              'status': 'going',
              'paceUnit': 'mi',
              'paceFromS': 570,
              'paceToS': null,
            },
          ],
        },
        {'groupId': 'g2', 'paces': <Object?>[]},
      ],
      'unassigned': {
        'goingCount': 4,
        'maybeCount': 1,
        'paces': [
          {'fromSPerKm': 330, 'toSPerKm': 360},
        ],
        'members': [
          {'memberId': 'm3', 'displayName': 'Pat', 'status': 'maybe'},
        ],
      },
    };

    test('parses attendees, unassigned and omitted keys', () {
      final plan = SessionPlan.fromJson(json);
      expect(plan.groups, hasLength(2));
      expect(plan.forGroup('g1')?.attendees?.single.displayName, 'Sam Lapsed');
      expect(plan.forGroup('g1')?.attendees?.single.pace, isA<SinglePace>());
      expect(plan.forGroup('g1')?.paces.single.spec, isA<SinglePace>());
      // `attendees` omitted means "not allowed to see", not "empty".
      expect(plan.forGroup('g2')?.attendees, isNull);
      expect(plan.forGroup('nope'), isNull);
      expect(plan.unassigned.goingCount, 4);
      expect(plan.unassigned.paces.single.spec, isA<PaceRange>());
      expect(plan.unassigned.members?.single.displayName, 'Pat');
    });

    test('tolerates a bare payload', () {
      final plan = SessionPlan.fromJson({'sessionId': 'a'});
      expect(plan.groups, isEmpty);
      expect(plan.unassigned.members, isNull);
      expect(plan.unassigned.goingCount, 0);
      expect(SessionPlan.decode('garbage'), isNull);
    });
  });

  test('PreferencesDto defaults and parse', () {
    expect(PreferencesDto.defaults.paceUnit, DistUnit.mi);
    expect(PreferencesDto.defaults.usualPace, isA<NoPace>());
    final p = PreferencesDto.fromJson({
      'paceUnit': 'km',
      'distanceUnit': 'mi',
      'paceFromS': 330,
      'paceToS': 360,
      'updatedAt': '2026-10-07T10:00:00Z',
    });
    expect(p.paceUnit, DistUnit.km);
    expect(p.distanceUnit, DistUnit.mi);
    expect(p.usualPace.display(DistUnit.km), '5:30-6:00/km');
    expect(p.updatedAt, isNotNull);
    expect(PreferencesDto.fromJson(const {}).distanceUnit, DistUnit.mi);
  });

  test('MemberItem parses roles', () {
    final m = MemberItem.fromJson({
      'memberId': 'm1',
      'displayName': 'Jo Bloggs',
      'status': 'active',
      'roles': ['leader'],
    });
    expect(m.isLeader, isTrue);
    expect(MemberItem.fromJson(const {}).roles, isEmpty);
  });

  group('sessions payload with groups and summary', () {
    late AppDatabase db;
    late FakeAdapter adapter;
    late RunsRepository repo;

    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    Future<void> refreshWith(List<Map<String, Object?>> sessions) async {
      adapter = FakeAdapter({
        'GET /app/clubs/1/sessions': FakeResponse(200, {
          'items': sessions,
          'serverTime': 'T1',
        }),
        'GET /app/clubs/1/venues': FakeResponse(200, {
          'items': [venueJson('v1')],
          'serverTime': 'T1',
        }),
        'GET /app/clubs/1/series': FakeResponse(200, {
          'items': [seriesJson('s1')],
          'serverTime': 'T1',
        }),
      });
      repo = RunsRepository(
        db,
        fakeDio(adapter),
        clock: () => DateTime(2026, 10, 7, 12),
      );
      await repo.refresh(1);
    }

    test('stores groups and summary as JSON', () async {
      await refreshWith([
        sessionWithGroups(
          'a',
          localDate: '2026-10-12',
          groups: [
            groupJson('g1', leaders: [leaderJson('m1')]),
          ],
          summary: summaryJson(groupCount: 1, goingCount: 2, myStatus: 'going'),
        ),
      ]);
      final row = await (db.select(db.sessions)).getSingle();
      expect(decodeGroups(row.groupsJson).single.id, 'g1');
      expect(decodeSummary(row.summaryJson)?.myStatus, 'going');
      final store = SessionLocalStore(db);
      expect((await store.watchGroups('a').first).single.id, 'g1');
      expect((await store.watchSummary('a').first)?.goingCount, 2);
    });

    test('an older payload without them still works and stays null', () async {
      await refreshWith([sessionJson('a', localDate: '2026-10-12')]);
      final row = await (db.select(db.sessions)).getSingle();
      expect(row.groupsJson, isNull);
      expect(row.summaryJson, isNull);
      final store = SessionLocalStore(db);
      expect(await store.watchGroups('a').first, isEmpty);
      expect(await store.watchSummary('a').first, isNull);
    });

    test('a later payload without groups keeps the stored ones', () async {
      await refreshWith([
        sessionWithGroups(
          'a',
          localDate: '2026-10-12',
          groups: [groupJson('g1')],
          summary: summaryJson(groupCount: 1),
        ),
      ]);
      await refreshWith([sessionJson('a', localDate: '2026-10-12')]);
      final row = await (db.select(db.sessions)).getSingle();
      expect(decodeGroups(row.groupsJson), hasLength(1));
    });
  });
}
