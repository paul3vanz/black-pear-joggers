import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
    int? usualFromS,
    int? usualToS,
    bool withRouter = false,
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
      await seedUnits(
        db,
        pace: paceUnit,
        usualFromS: usualFromS,
        usualToS: usualToS,
      );
      if (attendance != null) {
        await db.into(db.myAttendance).insert(attendance);
      }
    });
    if (withRouter) {
      await pumpGroupsRouter(
        tester,
        db,
        adapter,
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const SessionDetailScreen(sessionId: 'a'),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Text('Profile page'),
            ),
          ],
        ),
      );
      return;
    }
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
      expect(find.text('No usual pace set'), findsOneWidget);
      await tester.tap(find.text('Set pace for this run'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('pace-fast-min')), '5');
      await tester.enterText(find.byKey(const ValueKey('pace-fast-sec')), '50');
      await tester.tap(find.text('Save pace'));
      await settle(tester);

      expect(body(0), {'status': 'going', 'paceUnit': 'km', 'paceFromS': 350});
      expect(find.text('Running at 5:50/km this run'), findsOneWidget);
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
      expect(find.text('Running at 9:30-10:00/mi this run'), findsOneWidget);

      await tester.tap(find.text('Change'));
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
      expect(find.text('No usual pace set'), findsOneWidget);
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
  group('the pace line in "Are you coming?" (D89)', () {
    MyAttendanceCompanion row(
      String status, {
      int? fromS,
      int? toS,
      String unit = 'mi',
    }) => MyAttendanceCompanion.insert(
      sessionId: 'a',
      clubId: 1,
      status: status,
      paceUnit: Value(fromS == null ? null : unit),
      paceFromS: Value(fromS),
      paceToS: Value(toS),
      updatedAt: DateTime.utc(2026, 10, 6),
    );

    const paceTexts = [
      'No usual pace set',
      'Set your usual pace',
      'Set pace for this run',
      'Change for this run',
      'Change',
    ];

    testWidgets("can't come hides every pace link", (tester) async {
      await pumpDetail(
        tester,
        attendance: row('not_going'),
        usualFromS: 540,
        usualToS: 570,
      );
      expect(selectedStatus(tester), 'not_going');
      for (final t in paceTexts) {
        expect(find.text(t), findsNothing, reason: t);
      }
      expect(find.textContaining('Usual pace'), findsNothing);
      expect(find.textContaining('Running at'), findsNothing);
      await finish(tester);
    });

    testWidgets("can't come hides them even with a pace for this run", (
      tester,
    ) async {
      await pumpDetail(tester, attendance: row('not_going', fromS: 570));
      for (final t in paceTexts) {
        expect(find.text(t), findsNothing, reason: t);
      }
      expect(find.textContaining('Running at'), findsNothing);
      await finish(tester);
    });

    testWidgets('going with a usual pace shows it in the viewer units', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        attendance: row('going'),
        usualFromS: 540,
        usualToS: 570,
      );
      expect(find.text('Usual pace: 9:00-9:30/mi'), findsOneWidget);
      expect(find.text('Change for this run'), findsOneWidget);
      expect(find.text('No usual pace set'), findsNothing);
      expect(find.text('Set your usual pace'), findsNothing);
      expect(find.text('My pace for this run'), findsNothing);
      await finish(tester);
    });

    testWidgets('a usual pace in km shows as is for a km viewer', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        paceUnit: DistUnit.km,
        attendance: row('going'),
        usualFromS: 330,
        usualToS: 350,
      );
      expect(find.text('Usual pace: 5:30-5:50/km'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('going with no pace at all asks for one', (tester) async {
      await pumpDetail(tester, attendance: row('going'));
      expect(find.text('No usual pace set'), findsOneWidget);
      expect(find.text('Set your usual pace'), findsOneWidget);
      expect(find.text('Set pace for this run'), findsOneWidget);
      expect(find.text('Using my usual pace'), findsNothing);
      await finish(tester);
    });

    testWidgets('maybe behaves like going', (tester) async {
      await pumpDetail(tester, attendance: row('maybe'));
      expect(find.text('Set your usual pace'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('no answer yet still offers the pace links', (tester) async {
      await pumpDetail(tester);
      expect(find.text('Set pace for this run'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('"Set your usual pace" opens the Profile tab', (tester) async {
      await pumpDetail(tester, attendance: row('going'), withRouter: true);
      await tester.tap(find.text('Set your usual pace'));
      await tester.pumpAndSettle();
      expect(find.text('Profile page'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a pace for this run is shown with a Change link', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        attendance: row('going', fromS: 570),
        usualFromS: 540,
        usualToS: 570,
        routes: {
          'PUT $_put': FakeResponse(
            200,
            attendanceJson('a', paceUnit: 'mi', paceFromS: 600),
          ),
        },
      );
      expect(find.text('Running at 9:30/mi this run'), findsOneWidget);
      expect(find.text('My pace for this run'), findsNothing);
      expect(find.textContaining('Usual pace'), findsNothing);

      // Change opens the same sheet, which can go back to the usual pace.
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.text('Use my usual pace'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('pace-fast-min')), '10');
      await tester.enterText(find.byKey(const ValueKey('pace-fast-sec')), '');
      await tester.tap(find.text('Save pace'));
      await settle(tester);
      expect(find.text('Running at 10:00/mi this run'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('the run pace is converted for a km viewer, original kept', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        paceUnit: DistUnit.km,
        attendance: row('going', fromS: 570),
      );
      expect(
        find.text('Running at 5:54/km (9:30/mi) this run'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('a usual pace saved in the profile shows here at once', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        attendance: row('going'),
        routes: {
          'PUT /app/clubs/1/preferences': const FakeResponse(200, {
            'paceUnit': 'mi',
            'distanceUnit': 'mi',
            'paceFromS': 540,
            'paceToS': null,
            'updatedAt': '2026-10-07T10:00:00.000Z',
          }),
        },
      );
      expect(find.text('No usual pace set'), findsOneWidget);

      // What the Profile tab's Save button calls; nothing else is refreshed.
      await tester.runAsync(
        () => RunPreferencesRepository(db, fakeDio(adapter)).save(
          1,
          paceUnit: DistUnit.mi,
          distanceUnit: DistUnit.mi,
          usualPace: const SinglePace(Pace(540, DistUnit.mi)),
        ),
      );
      await settle(tester);

      expect(find.text('Usual pace: 9:00/mi'), findsOneWidget);
      expect(find.text('No usual pace set'), findsNothing);
      await finish(tester);
    });
  });
}
