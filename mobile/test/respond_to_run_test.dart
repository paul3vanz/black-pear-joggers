import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _put = '/app/clubs/1/sessions/a/attendance';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final fast = groupJson(
    'fast',
    label: 'Tempo',
    paceFromS: 540,
    paceToS: null,
    leaders: [leaderJson('l1', name: 'Jo Bloggs')],
  );

  late FakeAdapter adapter;

  Future<void> pumpDetail(
    WidgetTester tester, {
    Map<String, Object> routes = const {},
    List<Map<String, Object?>>? groups,
    Map<String, Object?>? summary,
    String groupMode = 'paced',
    DistUnit paceUnit = DistUnit.mi,
    MyAttendanceCompanion? attendance,
  }) async {
    adapter = await prepareMember(tester, db, routes: routes);
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: groups ?? [fast],
        summary: summary ?? summaryJson(groupCount: 1),
        groupMode: groupMode,
      );
      await seedUnits(db, pace: paceUnit);
      if (attendance != null) {
        await db.into(db.myAttendance).insert(attendance);
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

  String? selectedStatus(WidgetTester tester) {
    final b = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    return b.selected.isEmpty ? null : b.selected.first;
  }

  Map<String, Object?> body(int i) =>
      Map<String, Object?>.from(sent(adapter, 'PUT', _put)[i].data as Map);

  group('respond to the run', () {
    testWidgets('saves "I\'m coming" optimistically', (tester) async {
      await pumpDetail(
        tester,
        routes: {'PUT $_put': FakeResponse(200, attendanceJson('a'))},
      );
      expect(selectedStatus(tester), isNull);

      await tester.tap(find.text("I'm coming"));
      await settle(tester);

      expect(body(0), {'status': 'going'});
      expect(selectedStatus(tester), 'going');
      expect(find.text('Waiting to sync'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      await finish(tester);
    });

    testWidgets('offline: queued with a snackbar and a pending marker', (
      tester,
    ) async {
      await pumpDetail(tester); // no PUT route: the network is "down"
      await tester.tap(find.text('Maybe'));
      await settle(tester);

      expect(selectedStatus(tester), 'maybe');
      expect(find.text("Saved, will sync when you're online"), findsOneWidget);
      expect(find.text('Waiting to sync'), findsOneWidget);
      await finish(tester);
    });

    for (final (code, text) in const [
      ('session_cancelled', 'This run has been cancelled.'),
      ('session_past', 'This run has finished.'),
    ]) {
      testWidgets('rejected ($code) shows the reason and reverts', (
        tester,
      ) async {
        await pumpDetail(
          tester,
          routes: {
            'PUT $_put': FakeResponse(409, {'error': code, 'message': 'x'}),
            'GET $_put': const FakeResponse(200, null),
          },
        );
        await tester.tap(find.text("Can't come"));
        await settle(tester);

        expect(find.text(text), findsOneWidget);
        expect(selectedStatus(tester), isNull);
        expect(find.text('Waiting to sync'), findsNothing);
        await finish(tester);
      });
    }

    testWidgets('a finished run cannot be answered', (tester) async {
      adapter = await prepareMember(tester, db);
      await tester.runAsync(() async {
        await seedSession(db, 'a', groups: [fast], summary: summaryJson());
        await seedUnits(db);
      });
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const SessionDetailScreen(sessionId: 'a'),
        now: DateTime.utc(2026, 10, 13),
      );
      expect(
        find.textContaining("This run has finished. You can't respond"),
        findsOneWidget,
      );
      expect(find.text("I'm coming"), findsNothing);
      expect(find.text('Join this group'), findsNothing);
      await unmount(tester);
    });
  });

  group('join and leave a group', () {
    testWidgets('join sets going plus the group; leave clears the group', (
      tester,
    ) async {
      var n = 0;
      await pumpDetail(
        tester,
        routes: {
          'PUT $_put': () => FakeResponse(
            200,
            attendanceJson('a', groupId: n++ == 0 ? 'fast' : null),
          ),
        },
      );
      await tester.tap(find.text('Join this group'));
      await settle(tester);
      expect(body(0), {'status': 'going', 'groupId': 'fast'});
      expect(find.text("You're in this group"), findsOneWidget);
      expect(find.text('Join this group'), findsNothing);

      await tester.tap(find.text('Leave group'));
      await settle(tester);
      expect(body(1), {'status': 'going'});
      expect(find.text("You're in this group"), findsNothing);
      expect(find.text('Join this group'), findsOneWidget);
      expect(selectedStatus(tester), 'going');
      await finish(tester);
    });

    testWidgets('choosing a group while "Can\'t come" sets going', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        summary: summaryJson(groupCount: 1, myStatus: 'not_going'),
        routes: {
          'PUT $_put': FakeResponse(200, attendanceJson('a', groupId: 'fast')),
        },
      );
      expect(selectedStatus(tester), 'not_going');
      await tester.tap(find.text('Join this group'));
      await settle(tester);
      expect(body(0), {'status': 'going', 'groupId': 'fast'});
      expect(selectedStatus(tester), 'going');
      await finish(tester);
    });

    testWidgets('a route is joined with "I\'m doing this route"', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        groupMode: 'routes',
        groups: [
          groupJson('r', kind: 'route', paceUnit: null, paceFromS: null),
        ],
        routes: {
          'PUT $_put': FakeResponse(200, attendanceJson('a', groupId: 'r')),
        },
      );
      await tester.tap(find.text("I'm doing this route"));
      await settle(tester);
      expect(body(0), {'status': 'going', 'groupId': 'r'});
      await finish(tester);
    });
  });

  group('my pace for this run', () {
    testWidgets('saves a single pace in the viewer unit', (tester) async {
      await pumpDetail(
        tester,
        paceUnit: DistUnit.km,
        routes: {
          'PUT $_put': FakeResponse(
            200,
            attendanceJson('a', paceUnit: 'km', paceFromS: 350),
          ),
        },
      );
      expect(find.text('Using my usual pace'), findsOneWidget);
      await tester.tap(find.text('My pace for this run'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('pace-fast-min')), '5');
      await tester.enterText(find.byKey(const ValueKey('pace-fast-sec')), '50');
      await tester.tap(find.text('Save pace'));
      await settle(tester);

      expect(body(0), {'status': 'going', 'paceUnit': 'km', 'paceFromS': 350});
      expect(find.text('My pace: 5:50/km'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('rejects a bad pace and clears with "usual pace"', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        attendance: MyAttendanceCompanion.insert(
          sessionId: 'a',
          clubId: 1,
          status: 'going',
          paceUnit: const Value('mi'),
          paceFromS: const Value(570),
          paceToS: const Value(600),
          updatedAt: DateTime.utc(2026, 10, 6),
        ),
        routes: {'PUT $_put': FakeResponse(200, attendanceJson('a'))},
      );
      expect(find.text('My pace: 9:30-10:00/mi'), findsOneWidget);

      await tester.tap(find.text('My pace for this run'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('pace-fast-min')), '');
      await tester.enterText(find.byKey(const ValueKey('pace-fast-sec')), '30');
      await tester.tap(find.text('Save pace'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a pace like 9:30'), findsOneWidget);
      expect(sent(adapter, 'PUT', _put), isEmpty);

      await tester.tap(find.text('Use my usual pace'));
      await settle(tester);
      expect(body(0), {'status': 'going'});
      expect(find.text('Using my usual pace'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('changing status keeps the pace override', (tester) async {
      await pumpDetail(
        tester,
        attendance: MyAttendanceCompanion.insert(
          sessionId: 'a',
          clubId: 1,
          status: 'going',
          paceUnit: const Value('mi'),
          paceFromS: const Value(540),
          updatedAt: DateTime.utc(2026, 10, 6),
        ),
        routes: {'PUT $_put': FakeResponse(200, attendanceJson('a'))},
      );
      await tester.tap(find.text('Maybe'));
      await settle(tester);
      expect(body(0), {'status': 'maybe', 'paceUnit': 'mi', 'paceFromS': 540});
      await finish(tester);
    });
  });
}
