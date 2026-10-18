import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:drift/drift.dart' show Value;
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
    int goingCount = 0,
    String? createdByMemberId,
    String? deletedAt,
  }) => groupJson(
    'g',
    label: 'Tempo',
    paceFromS: 540,
    paceToS: null,
    leaders: leaders,
    status: status,
    goingCount: goingCount,
    createdByMemberId: createdByMemberId,
    deletedAt: deletedAt,
  );

  Future<void> pumpDetail(
    WidgetTester tester, {
    required Map<String, Object?> group,
    List<String> roles = const [],
    Map<String, Object> routes = const {},
    String groupMode = 'paced',
    Map<String, Object?>? summary,
    // Give the viewer a local 'going' row in this group.
    String? seedAttendance,
  }) async {
    adapter = await prepareMember(tester, db, roles: roles, routes: routes);
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: [group],
        summary: summary ?? summaryJson(groupCount: 1),
        groupMode: groupMode,
      );
      if (seedAttendance != null) {
        await db
            .into(db.myAttendance)
            .insert(
              MyAttendanceCompanion.insert(
                sessionId: 'a',
                clubId: 1,
                status: 'going',
                groupId: Value(seedAttendance),
                updatedAt: DateTime.utc(2026, 10, 6),
              ),
            );
      }
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
      // The group already has a leader (Jo): only the helper roles are offered.
      expect(find.text('Leader'), findsNothing);

      await tester.tap(find.text('Co-leader'));
      await settle(tester);

      expect(sent(adapter, 'POST', _leaders).single.data, {
        'role': 'co_leader',
      });
      expect(find.text('Jo Bloggs'), findsNWidgets(2));
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

    testWidgets('offers all three roles when the group has no leader', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(
          leaders: [leaderJson('l2', name: 'Pat', role: 'co_leader')],
        ),
      );
      // Only a co-leader so far: "Leader" is still free.
      await tester.tap(find.text("I'll lead this group too"));
      await tester.pumpAndSettle();
      expect(find.text('Leader'), findsOneWidget);
      expect(find.text('Co-leader'), findsOneWidget);
      expect(find.text('Backmarker'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a 409 leader_exists shows the message, refreshes and drops '
        '"Leader"', (tester) async {
      await pumpDetail(
        tester,
        group: tempo(),
        routes: {
          'POST $_leaders': const FakeResponse(409, {
            'error': 'leader_exists',
            'message':
                'This group already has a leader. Join as co-leader or '
                'backmarker.',
          }),
          'GET /app/clubs/1/sessions': FakeResponse(200, {
            'items': [
              sessionWithGroups(
                'a',
                localDate: '2026-10-12',
                groups: [
                  tempo(leaders: [jo]),
                ],
                summary: summaryJson(groupCount: 1, leaderCount: 1),
              ),
            ],
            'serverTime': '2026-10-07T10:00:00+00:00',
          }),
        },
      );
      await tester.tap(find.text("I'll lead this group too"));
      await tester.pumpAndSettle();
      expect(find.text('Leader'), findsOneWidget);
      await tester.tap(find.text('Leader'));
      await settle(tester);

      // The dialog stays open with the reason; only helper roles remain.
      expect(find.text('How will you help lead?'), findsOneWidget);
      expect(
        find.text(
          'This group already has a leader. Join as co-leader or backmarker.',
        ),
        findsOneWidget,
      );
      expect(find.text('Leader'), findsNothing);
      expect(find.text('Co-leader'), findsOneWidget);
      expect(find.text('Backmarker'), findsOneWidget);
      expect(sent(adapter, 'GET', '/app/clubs/1/sessions'), hasLength(1));

      // Retrying as co-leader goes through (fresh route response below).
      adapter.routes['POST $_leaders'] = FakeResponse(
        200,
        tempo(leaders: [jo, me]),
      );
      await tester.tap(find.text('Co-leader'));
      await settle(tester);
      expect(find.text('How will you help lead?'), findsNothing);
      expect(find.text("You're leading this group"), findsWidgets);
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

  group('stepping down (D109)', () {
    Future<void> openStepDown(WidgetTester tester) async {
      await tester.tap(find.text('Step down'));
      await tester.pumpAndSettle();
    }

    Future<void> confirmStepDown(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Step down'));
      await settle(tester);
    }

    Future<MyAttendanceRow?> attendanceRow(WidgetTester tester) async =>
        tester.runAsync<MyAttendanceRow?>(
          () => db.select(db.myAttendance).getSingleOrNull(),
        );

    testWidgets('asks first: removed from the group, plus a not-going box', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me], goingCount: 3),
        routes: {
          'DELETE $_leaders/me': FakeResponse(
            200,
            tempo(status: 'needs_leader', goingCount: 2),
          ),
        },
      );
      expect(find.text('Jo Bloggs'), findsOneWidget);
      expect(find.text('(co-leader)'), findsOneWidget);

      await openStepDown(tester);
      expect(find.text("You'll be removed from this group."), findsOneWidget);
      expect(find.text("I can't make this run at all"), findsOneWidget);
      expect(find.textContaining('will be deleted'), findsNothing);
      expect(find.textContaining('marked as needing'), findsNothing);

      // Keep: nothing is sent.
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(sent(adapter, 'DELETE', '$_leaders/me'), isEmpty);

      await openStepDown(tester);
      await confirmStepDown(tester);
      final calls = sent(adapter, 'DELETE', '$_leaders/me');
      expect(calls, hasLength(1));
      expect(calls.single.data, {'notGoing': false});
      expect(find.text('Needs a leader'), findsOneWidget);
      expect(find.text('No leader yet'), findsOneWidget);
      expect(find.text('You stepped down'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('afterwards I am an ordinary non-member of the group', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me], goingCount: 2),
        summary: summaryJson(
          groupCount: 1,
          goingCount: 2,
          myStatus: 'going',
          myGroupId: 'g',
          myLeading: true,
        ),
        seedAttendance: 'g',
        routes: {
          'DELETE $_leaders/me': FakeResponse(
            200,
            tempo(status: 'needs_leader', goingCount: 1),
          ),
        },
      );
      expect(find.text("You're leading this group"), findsOneWidget);
      expect(find.text('Join this group'), findsNothing);
      expect(find.text('Leave group'), findsNothing);

      await openStepDown(tester);
      await confirmStepDown(tester);

      // No longer leading, no longer in the group: it can be joined again.
      expect(find.text("You're leading this group"), findsNothing);
      expect(find.text("You're in this group"), findsNothing);
      expect(find.text('Leave group'), findsNothing);
      expect(find.text('Join this group'), findsOneWidget);
      expect(find.text('Step down'), findsNothing);
      final row = await attendanceRow(tester);
      expect(row?.status, 'going', reason: 'still going to the run');
      expect(row?.groupId, isNull);
      await finish(tester);
    });

    testWidgets('"I can\'t make this run at all" sends notGoing: true', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me], goingCount: 2),
        summary: summaryJson(
          groupCount: 1,
          goingCount: 2,
          myStatus: 'going',
          myGroupId: 'g',
          myLeading: true,
        ),
        seedAttendance: 'g',
        routes: {
          'DELETE $_leaders/me': FakeResponse(
            200,
            tempo(status: 'needs_leader', goingCount: 1),
          ),
        },
      );
      await openStepDown(tester);
      await tester.tap(find.byKey(const ValueKey('stepDownNotGoing')));
      await tester.pump();
      await confirmStepDown(tester);

      expect(sent(adapter, 'DELETE', '$_leaders/me').single.data, {
        'notGoing': true,
      });
      final row = await attendanceRow(tester);
      expect(row?.status, 'not_going');
      expect(row?.groupId, isNull);
      await finish(tester);
    });

    testWidgets('my own empty group says it will be deleted, and goes', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me], goingCount: 1, createdByMemberId: 'me'),
        summary: summaryJson(
          groupCount: 1,
          goingCount: 1,
          myStatus: 'going',
          myGroupId: 'g',
          myLeading: true,
        ),
        seedAttendance: 'g',
        routes: {
          'DELETE $_leaders/me': FakeResponse(
            200,
            tempo(
              goingCount: 0,
              createdByMemberId: 'me',
              deletedAt: '2026-10-07T10:00:00.000Z',
            ),
          ),
        },
      );
      await openStepDown(tester);
      expect(find.text("You'll be removed from this group."), findsOneWidget);
      expect(
        find.text('Nobody else has joined, so this group will be deleted.'),
        findsOneWidget,
      );
      await confirmStepDown(tester);

      expect(find.text('Tempo'), findsNothing);
      expect(
        find.text('No groups yet. Leaders can offer to lead one.'),
        findsOneWidget,
      );
      expect(find.text('Group deleted'), findsOneWidget);
      final row = await attendanceRow(tester);
      expect(row?.groupId, isNull);
      expect(row?.status, 'going');
      await finish(tester);
    });

    testWidgets('no deletion copy when someone else is in the group', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me], goingCount: 2, createdByMemberId: 'me'),
      );
      await openStepDown(tester);
      expect(find.textContaining('will be deleted'), findsNothing);
      await finish(tester);
    });

    testWidgets('no deletion copy for a group someone else created', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [me], goingCount: 1, createdByMemberId: 'l1'),
      );
      await openStepDown(tester);
      expect(find.textContaining('will be deleted'), findsNothing);
      await finish(tester);
    });

    testWidgets('no deletion copy while another leader remains', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        group: tempo(leaders: [jo, me], goingCount: 1, createdByMemberId: 'me'),
      );
      await openStepDown(tester);
      expect(find.textContaining('will be deleted'), findsNothing);
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
