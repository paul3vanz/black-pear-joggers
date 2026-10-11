import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _leaders = '/app/clubs/1/groups/g/leaders';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Map<String, Object?> tempo({
    List<Map<String, Object?>> leaders = const [],
    String status = 'active',
  }) => groupJson(
    'g',
    label: 'Tempo',
    paceFromS: 540,
    paceToS: null,
    leaders: leaders,
    status: status,
  );

  Future<void> pumpDetail(
    WidgetTester tester, {
    required Map<String, Object?> group,
    List<String> roles = const [],
    Map<String, Object> routes = const {},
    String groupMode = 'paced',
    Map<String, Object?>? summary,
  }) async {
    adapter = await prepareMember(tester, db, roles: roles, routes: routes);
    await tester.runAsync(
      () => seedSession(
        db,
        'a',
        groups: [group],
        summary: summary ?? summaryJson(groupCount: 1),
        groupMode: groupMode,
      ),
    );
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

  final jo = leaderJson('l1', name: 'Jo Bloggs');
  final me = leaderJson('me', name: 'Jo Bloggs', role: 'co_leader');

  group('offering to lead', () {
    testWidgets('"I\'ll lead this group too" asks for a role and joins', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [jo]),
        routes: {
          'POST $_leaders': FakeResponse(200, tempo(leaders: [jo, me])),
        },
      );
      await tester.tap(find.text("I'll lead this group too"));
      await tester.pumpAndSettle();
      expect(find.text('Co-leader'), findsOneWidget);
      expect(find.text('Backmarker'), findsOneWidget);

      await tester.tap(find.text('Co-leader'));
      await settle(tester);

      expect(sent(adapter, 'POST', _leaders).single.data, {
        'role': 'co_leader',
      });
      expect(
        find.text('Led by Jo Bloggs, Jo Bloggs (co-leader)'),
        findsOneWidget,
      );
      expect(find.text('Step down'), findsOneWidget);
      expect(find.text("I'll lead this group too"), findsNothing);
      expect(find.text("You're leading this group"), findsWidgets);
      expect(find.text('Join this group'), findsNothing);
      expect(find.text('Leave group'), findsNothing);
      await finish(tester);
    });

    testWidgets('a leaderless needs-leader group becomes active', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(status: 'needs_leader'),
        routes: {
          'POST $_leaders': FakeResponse(200, tempo(leaders: [me])),
        },
      );
      expect(find.text('Needs a leader'), findsOneWidget);
      await tester.tap(find.text("I'll lead this group too"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leader'));
      await settle(tester);
      expect(find.text('Needs a leader'), findsNothing);
      await finish(tester);
    });

    testWidgets('a refusal and being offline get friendly messages', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(),
        routes: {
          'POST $_leaders': const FakeResponse(403, {'error': 'forbidden'}),
        },
      );
      await tester.tap(find.text("I'll lead this group too"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leader'));
      await settle(tester);
      expect(find.text("You can't do that."), findsOneWidget);
      await finish(tester);

      await db.clearAll();
      await pumpDetail(tester, group: tempo());
      await tester.tap(find.text("I'll lead this group too"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leader'));
      await settle(tester);
      expect(find.text('You need a connection to do that.'), findsOneWidget);
      await finish(tester);
    });
  });

  group('stepping down', () {
    testWidgets('asks first and warns the group may need a leader', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me]),
        routes: {
          'DELETE $_leaders/me': FakeResponse(
            200,
            tempo(status: 'needs_leader'),
          ),
        },
      );
      expect(find.text('Led by Jo Bloggs (co-leader)'), findsOneWidget);

      await tester.tap(find.text('Step down'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "If you're the last leader, this group will be marked as needing a "
          'leader.',
        ),
        findsOneWidget,
      );

      // Keep: nothing is sent.
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(sent(adapter, 'DELETE', '$_leaders/me'), isEmpty);

      await tester.tap(find.text('Step down'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Step down'));
      await settle(tester);
      expect(sent(adapter, 'DELETE', '$_leaders/me'), hasLength(1));
      expect(find.text('Needs a leader'), findsOneWidget);
      expect(find.text('No leader yet'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a leader is already in the group, and stays in it', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me]),
        summary: summaryJson(
          groupCount: 1,
          myStatus: 'going',
          myGroupId: 'g',
          myLeading: true,
        ),
        routes: {
          'DELETE $_leaders/me': FakeResponse(
            200,
            tempo(status: 'needs_leader'),
          ),
        },
      );
      expect(find.text("You're leading this group"), findsOneWidget);
      expect(find.text('Join this group'), findsNothing);
      expect(find.text('Leave group'), findsNothing);

      await tester.tap(find.text('Step down'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Step down'));
      await settle(tester);

      // Withdrawing does not change attendance: still in the group.
      expect(find.text("You're in this group"), findsOneWidget);
      expect(find.text('Leave group'), findsOneWidget);
      expect(find.text('Step down'), findsNothing);
      await finish(tester);
    });
  });

  group('deleting a group', () {
    testWidgets('confirms, explains where people go, then removes it', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me]),
        routes: {'DELETE /app/clubs/1/groups/g': const FakeResponse(204)},
      );
      await tester.tap(find.byTooltip('Group options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete group'));
      await tester.pumpAndSettle();
      expect(
        find.text("People who chose it will be moved to 'no group yet'."),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(sent(adapter, 'DELETE', '/app/clubs/1/groups/g'), isEmpty);

      await tester.tap(find.byTooltip('Group options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete group'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(sent(adapter, 'DELETE', '/app/clubs/1/groups/g'), hasLength(1));
      expect(find.text('Tempo'), findsNothing);
      expect(
        find.text('No groups yet. Leaders can offer to lead one.'),
        findsOneWidget,
      );
      await finish(tester);
    });
  });
}
