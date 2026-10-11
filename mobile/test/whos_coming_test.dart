import 'dart:convert';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _plan = '/app/clubs/1/sessions/a/plan';
const _att = '/app/clubs/1/sessions/a/attendance';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final g1 = groupJson(
    'g1',
    label: 'Steady',
    leaders: [leaderJson('lead', name: 'Lee Leader')],
    goingCount: 3,
    maybeCount: 1,
  );

  Future<FakeAdapter> pump(
    WidgetTester tester, {
    List<String> roles = const [],
    String memberId = 'me',
    Map<String, Object> routes = const {},
    DistUnit paceUnit = DistUnit.mi,
    Map<String, Object?>? summary,
    String? coordinator,
    String groupMode = 'paced',
    Future<void> Function()? seed,
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      memberId: memberId,
      routes: routes,
    );
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: [g1],
        summary: summary ?? summaryJson(groupCount: 1),
        groupMode: groupMode,
        coordinatorMemberId: coordinator,
      );
      await seedUnits(db, pace: paceUnit);
      await seed?.call();
    });
    await pumpGroupsApp(
      tester,
      db,
      adapter,
      const SessionDetailScreen(sessionId: 'a'),
    );
    return adapter;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  // 9:00-10:00/mi paces: 330 s/km is 8:51/mi, 400 s/km is 10:44/mi.
  final memberPlan = planJson(
    'a',
    groups: [
      groupPlanJson('g1', paces: [planPaceJson(330), planPaceJson(400)]),
    ],
  );

  group("who's coming", () {
    testWidgets('a plain member sees the spread and no names', (tester) async {
      await pump(tester, routes: {'GET $_plan': FakeResponse(200, memberPlan)});
      expect(find.text("Who's coming"), findsOneWidget);
      expect(
        find.text('3 going, 1 maybe · usually 8:51-10:44/mi'),
        findsOneWidget,
      );
      expect(find.textContaining("Who's in this group"), findsNothing);
      expect(find.text('Group coverage'), findsNothing);
      expect(find.text('Coming, no group yet'), findsNothing);
      await finish(tester);
    });

    testWidgets('routes: the spread sits on each route card', (tester) async {
      await pump(
        tester,
        groupMode: 'routes',
        routes: {'GET $_plan': FakeResponse(200, memberPlan)},
      );
      expect(find.text('usually 8:51-10:44/mi'), findsOneWidget);
      expect(find.textContaining('3 going, 1 maybe ·'), findsNothing);
      await finish(tester);
    });
    testWidgets('shows the spread in km for a km viewer', (tester) async {
      await pump(
        tester,
        paceUnit: DistUnit.km,
        routes: {'GET $_plan': FakeResponse(200, memberPlan)},
      );
      expect(
        find.text('3 going, 1 maybe · usually 5:30-6:40/km'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('a leader sees names for their own group', (tester) async {
      final plan = planJson(
        'a',
        groups: [
          groupPlanJson(
            'g1',
            paces: [planPaceJson(354)],
            attendees: [
              attendeeJson('m1', 'Sam Runner'),
              attendeeJson('m2', 'Pat Maybe', status: 'maybe', paceUnit: null),
            ],
          ),
        ],
      );
      await pump(
        tester,
        memberId: 'lead',
        routes: {'GET $_plan': FakeResponse(200, plan)},
      );
      expect(find.text("Who's in this group (2)"), findsOneWidget);
      expect(find.text('Sam Runner'), findsNothing); // collapsed

      await tester.tap(find.text("Who's in this group (2)"));
      await settle(tester);
      expect(find.text('Sam Runner'), findsOneWidget);
      expect(find.text('Pat Maybe'), findsOneWidget);
      expect(find.text('9:30/mi'), findsWidgets);
      expect(find.text('no pace set'), findsOneWidget);
      expect(find.text('Group coverage'), findsNothing); // not a manager
      await finish(tester);
    });

    testWidgets('names show in the viewer units', (tester) async {
      final plan = planJson(
        'a',
        groups: [
          groupPlanJson(
            'g1',
            paces: [planPaceJson(354)],
            attendees: [attendeeJson('m1', 'Sam Runner')],
          ),
        ],
      );
      await pump(
        tester,
        memberId: 'lead',
        paceUnit: DistUnit.km,
        routes: {'GET $_plan': FakeResponse(200, plan)},
      );
      await tester.tap(find.text("Who's in this group (1)"));
      await settle(tester);
      expect(find.text('5:54/km (9:30/mi)'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('committee sees names, the no-group bucket and coverage', (
      tester,
    ) async {
      final plan = planJson(
        'a',
        groups: [
          groupPlanJson(
            'g1',
            paces: [planPaceJson(354)],
            attendees: [attendeeJson('m1', 'Sam Runner')],
          ),
        ],
        unassignedGoing: 3,
        unassignedPaces: [planPaceJson(404), planPaceJson(404)],
        unassignedMembers: [
          attendeeJson('u1', 'Una Slow', paceFromS: 650),
          attendeeJson('u2', 'Ulla Slow', paceFromS: 650),
          attendeeJson('u3', 'Nopace Nell', paceUnit: null, paceFromS: null),
        ],
      );
      await pump(
        tester,
        roles: ['committee'],
        routes: {'GET $_plan': FakeResponse(200, plan)},
      );
      expect(find.text('Coming, no group yet'), findsOneWidget);
      expect(find.text('Who is waiting for a group (3)'), findsOneWidget);
      expect(find.text('Group coverage'), findsOneWidget);
      expect(find.text('People coming with no matching group'), findsOneWidget);
      expect(find.textContaining('Based on the 4 people'), findsOneWidget);
      expect(
        find.textContaining('2 runners around 10:30-11:00/mi, no group yet'),
        findsOneWidget,
      );
      expect(find.text('1 going with no pace set'), findsOneWidget);
      expect(find.text('Add a group'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('null attendees render no names even for a leader of nothing', (
      tester,
    ) async {
      final plan = planJson(
        'a',
        groups: [
          groupPlanJson('g1', paces: [planPaceJson(354)]),
        ],
        unassignedGoing: 2,
        unassignedPaces: [planPaceJson(404)],
      );
      await pump(tester, routes: {'GET $_plan': FakeResponse(200, plan)});
      expect(find.text('Coming, no group yet'), findsOneWidget);
      expect(find.textContaining('Who is waiting'), findsNothing);
      expect(find.textContaining("Who's in this group"), findsNothing);
      await finish(tester);
    });

    testWidgets('offline shows the cached plan with when it was saved', (
      tester,
    ) async {
      await pump(
        tester,
        seed: () => db
            .into(db.sessionPlans)
            .insert(
              SessionPlansCompanion.insert(
                sessionId: 'a',
                clubId: 1,
                json: jsonEncode(memberPlan),
                fetchedAt: testNow.subtract(const Duration(hours: 2)),
              ),
            ),
      ); // no plan route: offline
      expect(
        find.textContaining("You're offline. This is the last plan"),
        findsOneWidget,
      );
      expect(find.textContaining('updated 2 hours ago'), findsOneWidget);
      expect(find.textContaining('usually 8:51-10:44/mi'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a server error shows a small retry row, not a blocker', (
      tester,
    ) async {
      await pump(
        tester,
        routes: {
          'GET $_plan': const FakeResponse(500, {'error': 'x', 'message': 'x'}),
        },
      );
      expect(find.text("Couldn't load who's coming."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Steady'), findsWidgets); // the screen still works
      await finish(tester);
    });
  });

  group('attendance backfill', () {
    testWidgets('stores the server row when the device has none', (
      tester,
    ) async {
      final adapter = await pump(
        tester,
        summary: summaryJson(groupCount: 1, myStatus: 'going'),
        routes: {
          'GET $_att': FakeResponse(
            200,
            attendanceJson('a', paceUnit: 'mi', paceFromS: 540, paceToS: 570),
          ),
          'PUT $_att': FakeResponse(200, attendanceJson('a', status: 'maybe')),
        },
      );
      expect(sent(adapter, 'GET', _att), hasLength(1));
      final row = await tester.runAsync(
        () => db.select(db.myAttendance).getSingleOrNull(),
      );
      expect(row!.paceFromS, 540);
      expect(row.paceToS, 570);
      expect(row.pending, isFalse);

      // A later status change keeps the server-held pace.
      await tester.tap(find.text('Maybe'));
      await settle(tester);
      final body = Map<String, Object?>.from(
        sent(adapter, 'PUT', _att).single.data as Map,
      );
      expect(body['paceFromS'], 540);
      expect(body['paceToS'], 570);
      await finish(tester);
    });

    testWidgets('does not fetch when there is no response or a local row', (
      tester,
    ) async {
      final adapter = await pump(tester);
      expect(sent(adapter, 'GET', _att), isEmpty);
      await finish(tester);
    });

    testWidgets('does not fetch when a local row exists', (tester) async {
      final adapter = await pump(
        tester,
        summary: summaryJson(groupCount: 1, myStatus: 'going'),
        seed: () => db
            .into(db.myAttendance)
            .insert(
              MyAttendanceCompanion.insert(
                sessionId: 'a',
                clubId: 1,
                status: 'going',
                updatedAt: testNow,
              ),
            ),
      );
      expect(sent(adapter, 'GET', _att), isEmpty);
      await finish(tester);
    });
  });
}
