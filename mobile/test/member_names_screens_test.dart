import 'package:bpj/core/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:bpj/features/members/ui/member_avatar.dart';
import 'package:bpj/features/members/ui/member_providers.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

// Phase 6.5c on the run page: the coordinator row, the group card leaders and
// the who's-coming names, inside a real router so a tap really pushes.

const _plan = '/app/clubs/1/sessions/a/plan';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester, {
    String memberId = 'me',
    String? coordinator = 'alex',
    Map<String, Object> routes = const {},
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      memberId: memberId,
      routes: routes,
    );
    await tester.runAsync(() async {
      await seedUnits(db);
      await seedSession(
        db,
        'a',
        groups: [
          groupJson(
            'g1',
            label: 'Steady',
            leaders: [leaderJson('lead', name: 'Lee Leader')],
            goingCount: 2,
          ),
        ],
        summary: summaryJson(groupCount: 1, leaderCount: 1),
        coordinatorMemberId: coordinator,
        coordinatorName: coordinator == null ? null : 'Alex Coord',
      );
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SessionDetailScreen(sessionId: 'a'),
        ),
        GoRoute(
          path: '/members/:memberId',
          builder: (_, state) => Scaffold(
            appBar: AppBar(),
            body: Text('Profile ${state.pathParameters['memberId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, fakeDio(adapter)),
          // No card photos here: initials everywhere.
          memberCardsProvider.overrideWith(
            (ref) => Stream.value(const <String, MemberCard>{}),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  testWidgets('coordinator row: label, avatar and tappable name', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Coordinator:'), findsOneWidget);
    expect(find.text('Alex Coord'), findsOneWidget);
    expect(find.text('AC'), findsOneWidget); // initials, no photo
    await tester.tap(find.text('Alex Coord'));
    await tester.pumpAndSettle();
    expect(find.text('Profile alex'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Profile alex'), findsNothing);
    expect(find.text('Coordinator:'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('coordinator without a member id is plain text', (tester) async {
    await pump(tester, coordinator: 'x');
    // Rewrite the cached row so the id is missing but the name stays.
    await tester.runAsync(
      () => (db.update(db.sessions)..where((s) => s.id.equals('a'))).write(
        const SessionsCompanion(coordinatorMemberId: Value(null)),
      ),
    );
    await settle(tester);
    expect(find.text('Alex Coord'), findsOneWidget);
    await tester.tap(find.text('Alex Coord'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Profile'), findsNothing);
    await finish(tester);
  });

  testWidgets('no coordinator: no row', (tester) async {
    await pump(tester, coordinator: null);
    expect(find.text('Coordinator:'), findsNothing);
    await finish(tester);
  });

  testWidgets('the group card leader on the run page is a link', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Led by'), findsOneWidget);
    expect(find.text('Lee Leader'), findsOneWidget);
    expect(find.text('LL'), findsOneWidget);
    await tester.tap(find.text('Lee Leader'));
    await tester.pumpAndSettle();
    expect(find.text('Profile lead'), findsOneWidget);
    await finish(tester);
  });

  testWidgets("a leader's who's-coming names have avatars and are links", (
    tester,
  ) async {
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
    await tester.tap(find.text("Who's in this group (2)"));
    await settle(tester);
    expect(find.text('Sam Runner'), findsOneWidget);
    expect(find.text('SR'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    // The pace text stays on the row.
    expect(find.text('9:30/mi'), findsWidgets);
    expect(find.text('no pace set'), findsOneWidget);
    expect(find.byType(MemberLink), findsWidgets);
    await tester.tap(find.text('Pat Maybe'));
    await tester.pumpAndSettle();
    expect(find.text('Profile m2'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Pat Maybe'), findsOneWidget);
    await finish(tester);
  });
}
