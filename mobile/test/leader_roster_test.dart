import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/distance.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/data/last_group_store.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/data/session_local.dart';
import 'package:bpj/features/groups/logic/roster.dart';
import 'package:bpj/features/groups/ui/leader_roster_screen.dart';
import 'package:bpj/features/groups/ui/roster_run_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late GoRouter router;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final me = leaderJson('me', name: 'Jo Bloggs');
  final other = leaderJson('l1', name: 'Sam Lead');

  Future<void> pumpRoster(
    WidgetTester tester, {
    Map<String, Object> routes = const {},
    Future<void> Function()? seed,
  }) async {
    adapter = await prepareMember(tester, db, routes: routes);
    await tester.runAsync(() async {
      await seedUnits(db);
      // Wed 7 Oct "now": 'a' next week, 'b' the week after, 'c' cancelled,
      // 'd' beyond six weeks.
      await seedSession(
        db,
        'a',
        groups: [
          groupJson('g-mine', sessionId: 'a', leaders: [me], label: 'Mine'),
        ],
        summary: summaryJson(groupCount: 1, leaderCount: 1, myLeading: true),
      );
      await seedSession(
        db,
        'b',
        localDate: '2026-10-20',
        groups: [
          groupJson(
            'g-other',
            sessionId: 'b',
            leaders: [other],
            paceFromS: 540,
            paceToS: null,
          ),
          groupJson(
            'g-none',
            sessionId: 'b',
            status: 'needs_leader',
            paceFromS: 660,
            paceToS: null,
          ),
        ],
        summary: summaryJson(groupCount: 2, leaderCount: 1),
      );
      await seedSession(db, 'c', localDate: '2026-10-14', status: 'cancelled');
      await seedSession(db, 'd', localDate: '2026-12-30');
      await seed?.call();
    });
    router = GoRouter(
      initialLocation: '/runs/lead',
      routes: [
        GoRoute(
          path: '/runs/lead',
          builder: (_, _) => const LeaderRosterScreen(),
        ),
        GoRoute(
          path: '/runs/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
          routes: [
            GoRoute(
              path: 'groups/new',
              builder: (_, state) =>
                  Scaffold(body: Text('new ${state.uri.query}')),
            ),
            GoRoute(
              path: 'groups/:gid/edit',
              builder: (_, state) =>
                  Scaffold(body: Text('edit ${state.pathParameters['gid']}')),
            ),
          ],
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
  }

  Finder card(String id) => find.byKey(ValueKey(id));

  Finder inCard(String id, Finder f) =>
      find.descendant(of: card(id), matching: f);

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  group('roster', () {
    testWidgets('groups the next six weeks by week, skipping cancelled', (
      tester,
    ) async {
      await pumpRoster(tester);
      expect(find.text('Next week'), findsOneWidget);
      expect(find.text('Week of 19 Oct'), findsOneWidget);
      expect(find.byType(RosterRunCard), findsNWidgets(2));
      expect(card('c'), findsNothing);
      expect(card('d'), findsNothing);
      await finish(tester);
    });

    testWidgets('shows groups with leaders and a needs-a-leader badge', (
      tester,
    ) async {
      await pumpRoster(tester);
      expect(inCard('b', find.text('Sam Lead')), findsOneWidget);
      expect(inCard('b', find.text('Led by')), findsOneWidget);
      expect(inCard('b', find.text('Needs a leader')), findsOneWidget);
      expect(inCard('b', find.text('9:00/mi')), findsOneWidget);
      expect(inCard('b', find.text('Offer to lead')), findsOneWidget);
      expect(inCard('b', find.text('Join as co-leader')), findsOneWidget);
      expect(inCard('b', find.text('Lead this group')), findsOneWidget);
      await finish(tester);
    });

    testWidgets('my own group has Edit and Step down, no Offer', (
      tester,
    ) async {
      await pumpRoster(tester);
      expect(inCard('a', find.text('Offer to lead')), findsNothing);
      expect(inCard('a', find.text('Edit')), findsOneWidget);
      expect(inCard('a', find.text('Step down')), findsOneWidget);

      await tester.tap(inCard('a', find.text('Edit')));
      await tester.pumpAndSettle();
      expect(find.text('edit g-mine'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('on a run I lead, other groups offer nothing (D108)', (
      tester,
    ) async {
      await pumpRoster(
        tester,
        seed: () => SessionLocalStore(db).mergeGroup(
          Group.fromJson(
            groupJson(
              'g-other',
              sessionId: 'a',
              label: 'Theirs',
              leaders: [other],
              paceFromS: 540,
              paceToS: null,
            ),
          ),
          myMemberId: 'me',
        ),
      );
      expect(inCard('a', find.text('Edit')), findsOneWidget);
      expect(inCard('a', find.text('Join as co-leader')), findsNothing);
      expect(inCard('a', find.text('Lead this group')), findsNothing);
      expect(inCard('a', find.text('Offer to lead')), findsNothing);
      expect(
        inCard('a', find.textContaining("You're already leading the")),
        findsOneWidget,
      );
      // Other runs are unaffected.
      expect(inCard('b', find.text('Join as co-leader')), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Offer to lead opens the editor with the lead intent', (
      tester,
    ) async {
      await pumpRoster(tester);
      await tester.tap(inCard('b', find.text('Offer to lead')));
      await tester.pumpAndSettle();
      expect(find.text('new intent=lead'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Step down asks first, then withdraws', (tester) async {
      await pumpRoster(
        tester,
        routes: {
          'DELETE /app/clubs/1/groups/g-mine/leaders/me': FakeResponse(
            200,
            groupJson('g-mine', sessionId: 'a', status: 'needs_leader'),
          ),
        },
      );
      await tester.tap(inCard('a', find.text('Step down')));
      await tester.pumpAndSettle();
      expect(find.text('Step down?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Step down'));
      await settle(tester);
      expect(
        sent(adapter, 'DELETE', '/app/clubs/1/groups/g-mine/leaders/me'),
        hasLength(1),
      );
      expect(inCard('a', find.text('Needs a leader')), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Join as co-leader asks for a role', (tester) async {
      const path = '/app/clubs/1/groups/g-other/leaders';
      await pumpRoster(
        tester,
        routes: {
          'POST $path': FakeResponse(
            200,
            groupJson(
              'g-other',
              sessionId: 'b',
              leaders: [
                other,
                leaderJson('me', role: 'co_leader'),
              ],
            ),
          ),
        },
      );
      await tester.tap(inCard('b', find.text('Join as co-leader')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Co-leader'));
      await settle(tester);
      expect(sent(adapter, 'POST', path).single.data, {'role': 'co_leader'});
      await finish(tester);
    });

    testWidgets('offline: shows the cached roster and a banner', (
      tester,
    ) async {
      await pumpRoster(tester); // no sessions route: offline
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.byType(RosterRunCard), findsNWidgets(2));
      await finish(tester);
    });
  });

  group('same as last time', () {
    final last = LastGroupSpec(
      kind: 'run',
      label: 'Easy',
      pace: PaceRange(
        const Pace(570, DistUnit.mi),
        const Pace(600, DistUnit.mi),
      ),
      distance: const Distance(3, DistUnit.mi),
    );

    Future<void> seedLast() => LastGroupStore(db).write(1, null, last);

    testWidgets('is offered with the remembered spec', (tester) async {
      await pumpRoster(tester, seed: seedLast);
      expect(
        inCard('b', find.text('Same as last time: 9:30-10:00/mi · 3 mi')),
        findsOneWidget,
      );
      // Not on a run I already lead.
      expect(
        inCard('a', find.textContaining('Same as last time')),
        findsNothing,
      );
      await finish(tester);
    });

    testWidgets('is not offered with no history', (tester) async {
      await pumpRoster(tester);
      expect(find.textContaining('Same as last time'), findsNothing);
      await finish(tester);
    });

    testWidgets('creates the group at once; Undo deletes it', (tester) async {
      const post = '/app/clubs/1/sessions/b/groups';
      await pumpRoster(
        tester,
        seed: seedLast,
        routes: {
          'POST $post': FakeResponse(
            201,
            groupJson(
              'new-g',
              sessionId: 'b',
              label: 'Easy',
              leaders: [me],
              distanceValue: 3,
              distanceUnit: 'mi',
            ),
          ),
          'DELETE /app/clubs/1/groups/new-g': const FakeResponse(204),
        },
      );
      await tester.tap(inCard('b', find.textContaining('Same as last time')));
      await settle(tester);

      final body = Map<String, Object?>.from(
        sent(adapter, 'POST', post).single.data as Map,
      );
      expect(body['kind'], 'run');
      expect(body['label'], 'Easy');
      expect(body['paceFromS'], 570);
      expect(body['paceToS'], 600);
      expect(body['distanceValue'], 3.0);
      expect(body['lead'], true);
      expect(find.text("You're leading a group for this run"), findsOneWidget);
      expect(inCard('b', find.text('Edit')), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(
        sent(adapter, 'DELETE', '/app/clubs/1/groups/new-g'),
        hasLength(1),
      );
      expect(inCard('b', find.text('Edit')), findsNothing);
      await finish(tester);
    });

    testWidgets('offline shows the friendly error and creates nothing', (
      tester,
    ) async {
      await pumpRoster(tester, seed: seedLast);
      await tester.tap(inCard('b', find.textContaining('Same as last time')));
      await settle(tester);
      expect(find.text('You need a connection to do that.'), findsOneWidget);
      await finish(tester);
    });
  });

  group('buildRoster', () {
    Session s(String id, String date, {String status = 'scheduled'}) => Session(
      id: id,
      clubId: 1,
      title: id,
      startsAt: DateTime.utc(2026, 10, 12, 18),
      endsAt: DateTime.parse('${date}T19:30:00Z'),
      localDate: date,
      localStartTime: '19:00',
      localEndTime: '20:30',
      groupMode: 'paced',
      status: status,
      seriesId: null,
      occurrenceDate: null,
      venueId: null,
      notes: null,
      cancelReason: null,
      coordinatorMemberId: null,
      coordinatorName: null,
      originalJson: null,
      groupsJson: null,
      summaryJson: null,
      isDetached: false,
      updatedAt: DateTime.utc(2026, 10, 1),
    );

    test('starts weeks on Monday and labels them', () {
      final weeks = buildRoster([
        s('sun', '2026-10-11'),
        s('mon', '2026-10-12'),
        s('tue', '2026-10-13'),
        s('next', '2026-10-26'),
      ], testNow);
      expect(weeks.map((w) => w.label), [
        'This week',
        'Next week',
        'Week of 26 Oct',
      ]);
      expect(weeks[1].sessions.map((x) => x.id), ['mon', 'tue']);
    });

    test('drops cancelled, finished and beyond six weeks', () {
      final weeks = buildRoster([
        s('past', '2026-10-05'),
        s('gone', '2026-10-13', status: 'cancelled'),
        s('far', '2026-11-30'),
        s('ok', '2026-11-17'),
      ], testNow);
      expect(weeks.expand((w) => w.sessions).map((x) => x.id), ['ok']);
    });
  });
}
