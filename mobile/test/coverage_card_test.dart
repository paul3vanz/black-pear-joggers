import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _plan = '/app/clubs/1/sessions/a/plan';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Map<String, Object?> led(
    String id, {
    int? from = 540,
    int? to,
    String kind = 'run',
    String? label,
  }) => groupJson(
    id,
    kind: kind,
    label: label,
    paceUnit: from == null ? null : 'mi',
    paceFromS: from,
    paceToS: to,
    paceFromSPerKm: null,
    paceToSPerKm: null,
    leaders: [leaderJson('l$id', name: 'Jo Bloggs')],
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<Map<String, Object?>> groups,
    List<String> roles = const ['committee'],
    DistUnit paceUnit = DistUnit.mi,
    Map<String, Object?>? plan,
    String groupMode = 'paced',
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      routes: {if (plan != null) 'GET $_plan': FakeResponse(200, plan)},
    );
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: groups,
        summary: summaryJson(groupCount: groups.length),
        groupMode: groupMode,
      );
      await seedUnits(db, pace: paceUnit);
    });
    await pumpGroupsApp(
      tester,
      db,
      adapter,
      const SessionDetailScreen(sessionId: 'a'),
    );
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  testWidgets('committee sees the coverage card with gaps and extremes', (
    tester,
  ) async {
    await pump(tester, groups: [led('a', from: 480), led('b', from: 630)]);
    expect(find.text('Group coverage'), findsOneWidget);
    expect(find.text('Fastest led group: 8:00/mi'), findsOneWidget);
    expect(find.text('Slowest led group: 10:30/mi'), findsOneWidget);
    expect(find.text('No led group between 8:25 and 10:05/mi'), findsOneWidget);
    expect(
      find.text('Nobody leading slower than 10:55/mi (down to 12:00/mi)'),
      findsOneWidget,
    );
    expect(find.textContaining('Every pace has a group'), findsNothing);
    await finish(tester);
  });

  testWidgets('a plain member does not see it', (tester) async {
    await pump(tester, roles: const [], groups: [led('a')]);
    expect(find.text('Group coverage'), findsNothing);
    await finish(tester);
  });

  testWidgets('a jog/walk group softens the slow end and shows as a chip', (
    tester,
  ) async {
    await pump(
      tester,
      groups: [
        led('a', from: 480),
        led('j', from: null, kind: 'jog_walk'),
      ],
    );
    expect(find.text('Jog/walk group on offer'), findsOneWidget);
    expect(find.text('Jog/walk group led by Jo Bloggs'), findsOneWidget);
    expect(find.textContaining('Nobody leading slower than'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('groups without a leader are listed as needing one', (
    tester,
  ) async {
    await pump(
      tester,
      groups: [
        led('a'),
        groupJson('x', paceFromS: 660, paceToS: null, status: 'needs_leader'),
      ],
    );
    expect(find.text('Needs a leader: 11:00/mi'), findsOneWidget);
    expect(find.text('Slowest led group: 9:00/mi'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('empty states', (tester) async {
    await pump(tester, groups: const []);
    expect(find.text('No groups yet'), findsOneWidget);
    await unmount(tester);
    await db.clearAll();

    await pump(tester, groups: [groupJson('x', status: 'needs_leader')]);
    expect(find.text('No groups with a leader yet'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('km viewers get the km window and wording', (tester) async {
    await pump(
      tester,
      paceUnit: DistUnit.km,
      groups: [
        groupJson(
          'k',
          paceUnit: 'km',
          paceFromS: 360,
          paceToS: null,
          leaders: [leaderJson('lk')],
        ),
      ],
    );
    expect(
      find.text('Nobody leading slower than 6:15/km (down to 7:30/km)'),
      findsOneWidget,
    );
    await finish(tester);
  });

  group('people coming with no matching group', () {
    Map<String, Object?> planWith(List<Map<String, Object?>> people) =>
        planJson(
          'a',
          groups: [groupPlanJson('a', attendees: const [])],
          unassignedGoing: people.length,
          unassignedMembers: people,
        );

    testWidgets('is hidden when every pace is covered', (tester) async {
      await pump(
        tester,
        groups: [led('a', from: 540)],
        plan: planWith([attendeeJson('u1', 'Una Near', paceFromS: 550)]),
      );
      expect(find.text('Group coverage'), findsOneWidget);
      expect(find.text('People coming with no matching group'), findsNothing);
      expect(find.textContaining('Every pace has a group'), findsNothing);
      await finish(tester);
    });

    testWidgets('lists uncovered paces and people with no pace', (
      tester,
    ) async {
      await pump(
        tester,
        groups: [led('a', from: 540)],
        plan: planWith([
          attendeeJson('u1', 'Una Slow', paceFromS: 700),
          attendeeJson('u2', 'Nell', paceUnit: null, paceFromS: null),
        ]),
      );
      expect(find.text('People coming with no matching group'), findsOneWidget);
      expect(
        find.textContaining('Based on the 2 people who have said'),
        findsOneWidget,
      );
      expect(find.textContaining('1 runner around'), findsOneWidget);
      expect(find.text('1 going with no pace set'), findsOneWidget);
      await finish(tester);
    });
  });
}
