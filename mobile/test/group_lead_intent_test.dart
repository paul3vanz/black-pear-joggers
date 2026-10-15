import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/ui/group_editor_screen.dart';
import 'package:bpj/features/groups/ui/leader_roster_screen.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _create = '/app/clubs/1/sessions/b/groups';
const _plan = '/app/clubs/1/sessions/b/plan';

/// D86: the "I will lead this group" switch exists only for an "add a group"
/// action by someone who may create a leaderless group. Every "lead" action
/// (roster, run page) skips it and creates a group the member leads. These
/// tests start from the real entry buttons and the real editor, joined by a
/// router that builds the editor the way the app router does
/// (`GroupEditorScreen.fromUri`).
void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final created = FakeResponse(201, groupJson('new', sessionId: 'b'));

  Future<void> pump(
    WidgetTester tester, {
    required String start,
    List<String> roles = const [],
    String? coordinator,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      routes: {
        'POST $_create': created,
        // Only the committee's coverage card asks for it.
        'GET $_plan': FakeResponse(200, planJson('b')),
      },
    );
    await tester.runAsync(() async {
      await seedUnits(db);
      await seedSession(
        db,
        'b',
        localDate: '2026-10-20',
        summary: summaryJson(),
        coordinatorMemberId: coordinator,
      );
    });
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(
          path: '/runs/lead',
          builder: (_, _) => const LeaderRosterScreen(),
        ),
        GoRoute(
          path: '/runs/:id',
          builder: (_, state) =>
              SessionDetailScreen(sessionId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'groups/new',
              builder: (_, state) => GroupEditorScreen.fromUri(
                state.pathParameters['id']!,
                state.uri,
              ),
            ),
          ],
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);
  }

  final leadSwitch = find.widgetWithText(
    SwitchListTile,
    'I will lead this group',
  );

  Future<void> saveWithLabel(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Label (required)'),
      'Jog/walk',
    );
    await tester.tap(find.text('Save group'));
    await settle(tester);
  }

  Map<String, Object?> posted() => Map<String, Object?>.from(
    sent(adapter, 'POST', _create).single.data as Map,
  );

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  group('from the leader roster ("Offer to lead")', () {
    testWidgets('a member: no switch, creates a group they lead', (
      tester,
    ) async {
      await pump(tester, start: '/runs/lead');
      await tester.tap(find.text('Offer to lead'));
      await tester.pumpAndSettle();

      expect(find.text('Lead a group'), findsOneWidget); // app bar
      expect(leadSwitch, findsNothing);
      expect(find.text('You lead the groups you create.'), findsNothing);
      await saveWithLabel(tester);
      expect(posted()['lead'], isTrue);
      await finish(tester);
    });

    testWidgets('committee: still no switch, lead is true', (tester) async {
      await pump(tester, start: '/runs/lead', roles: ['committee']);
      await tester.tap(find.text('Offer to lead'));
      await tester.pumpAndSettle();

      expect(leadSwitch, findsNothing);
      await saveWithLabel(tester);
      expect(posted()['lead'], isTrue);
      await finish(tester);
    });
  });

  group('from the run page', () {
    testWidgets('a member: "Lead a group" has no switch and leads', (
      tester,
    ) async {
      await pump(tester, start: '/runs/b');
      await tester.tap(find.text('Lead a group'));
      await tester.pumpAndSettle();

      expect(leadSwitch, findsNothing);
      await saveWithLabel(tester);
      expect(posted()['lead'], isTrue);
      await finish(tester);
    });

    testWidgets('committee: "Lead a group" has no switch either', (
      tester,
    ) async {
      await pump(tester, start: '/runs/b', roles: ['committee']);
      await tester.tap(find.text('Lead a group'));
      await tester.pumpAndSettle();

      expect(leadSwitch, findsNothing);
      await saveWithLabel(tester);
      expect(posted()['lead'], isTrue);
      await finish(tester);
    });

    testWidgets('committee: "Add a group" shows the switch, on by default', (
      tester,
    ) async {
      await pump(tester, start: '/runs/b', roles: ['committee']);
      await tester.tap(find.text('Add a group'));
      await tester.pumpAndSettle();

      expect(find.text('Add a group'), findsOneWidget); // app bar
      expect(leadSwitch, findsOneWidget);
      expect(tester.widget<SwitchListTile>(leadSwitch).value, isTrue);
      await saveWithLabel(tester);
      expect(posted()['lead'], isTrue);
      await finish(tester);
    });

    testWidgets('committee can turn it off for a leaderless group', (
      tester,
    ) async {
      await pump(tester, start: '/runs/b', roles: ['committee']);
      await tester.tap(find.text('Add a group'));
      await tester.pumpAndSettle();

      await tester.tap(leadSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(leadSwitch).value, isFalse);
      await saveWithLabel(tester);
      expect(posted()['lead'], isFalse);
      await finish(tester);
    });

    testWidgets('the run coordinator sees the switch for an added group', (
      tester,
    ) async {
      await pump(
        tester,
        start: '/runs/b/groups/new?intent=add',
        coordinator: 'me',
      );
      expect(leadSwitch, findsOneWidget);
      await unmount(tester);
    });
  });

  group('the route parameters', () {
    testWidgets('a member who arrives with intent=add still gets no switch', (
      tester,
    ) async {
      await pump(tester, start: '/runs/b/groups/new?intent=add&lead=false');
      expect(leadSwitch, findsNothing);
      await saveWithLabel(tester);
      expect(
        posted()['lead'],
        isTrue,
        reason: 'the server would 403 otherwise',
      );
      await finish(tester);
    });

    testWidgets('no intent means lead, and a committee gets no switch', (
      tester,
    ) async {
      await pump(tester, start: '/runs/b/groups/new', roles: ['committee']);
      expect(leadSwitch, findsNothing);
      await unmount(tester);
    });

    test('GroupIntent.fromQuery', () {
      expect(GroupIntent.fromQuery('add'), GroupIntent.add);
      expect(GroupIntent.fromQuery('lead'), GroupIntent.lead);
      expect(GroupIntent.fromQuery(null), GroupIntent.lead);
      expect(GroupIntent.fromQuery('nonsense'), GroupIntent.lead);
    });
  });

  testWidgets('"Add route" keeps its switch, off by default, for committee', (
    tester,
  ) async {
    await pump(
      tester,
      start: '/runs/b/groups/new?kind=route&intent=add&lead=false',
      roles: ['committee'],
    );
    expect(leadSwitch, findsOneWidget);
    expect(tester.widget<SwitchListTile>(leadSwitch).value, isFalse);
    await unmount(tester);
  });
}
