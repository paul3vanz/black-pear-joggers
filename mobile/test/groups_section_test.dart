import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pumpDetail(
    WidgetTester tester, {
    List<String> roles = const [],
    List<Map<String, Object?>> groups = const [],
    Map<String, Object?>? summary,
    String groupMode = 'paced',
    String status = 'scheduled',
    String? coordinator,
    DistUnit paceUnit = DistUnit.mi,
    DistUnit distanceUnit = DistUnit.mi,
  }) async {
    final adapter = await prepareMember(tester, db, roles: roles);
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: groups,
        summary: summary ?? summaryJson(groupCount: groups.length),
        groupMode: groupMode,
        status: status,
        coordinatorMemberId: coordinator,
      );
      await seedUnits(db, pace: paceUnit, distance: distanceUnit);
    });
    await pumpGroupsApp(
      tester,
      db,
      adapter,
      const SessionDetailScreen(sessionId: 'a'),
    );
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  final fast = groupJson(
    'fast',
    label: 'Tempo',
    paceFromS: 540,
    paceToS: null,
    paceFromSPerKm: 336,
    paceToSPerKm: null,
    distanceValue: 3,
    distanceUnit: 'mi',
    leaders: [leaderJson('l1', name: 'Jo Bloggs')],
    goingCount: 5,
    maybeCount: 1,
  );
  final slow = groupJson(
    'slow',
    label: 'Steady',
    paceFromS: 570,
    paceToS: 600,
    leaders: [
      leaderJson('l2', name: 'Sam Lapsed'),
      leaderJson('l3', name: 'Pat Back', role: 'backmarker'),
    ],
  );
  final noPace = groupJson(
    'np',
    kind: 'jog_walk',
    label: 'Jog and walk',
    paceUnit: null,
    paceFromS: null,
    paceToS: null,
    paceFromSPerKm: null,
    paceToSPerKm: null,
    status: 'needs_leader',
  );

  testWidgets('sorts fastest first and shows paces in miles for a mile user', (
    tester,
  ) async {
    await pumpDetail(tester, groups: [noPace, slow, fast]);

    expect(find.text('9:00/mi'), findsOneWidget);
    expect(find.text('9:30-10:00/mi'), findsOneWidget);
    expect(find.text('3 mi'), findsOneWidget);
    expect(top(tester, 'Tempo'), lessThan(top(tester, 'Steady')));
    expect(top(tester, 'Steady'), lessThan(top(tester, 'Jog and walk')));
    await unmount(tester);
  });

  testWidgets('shows paces and distances in km with the original in brackets', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      groups: [fast, slow],
      paceUnit: DistUnit.km,
      distanceUnit: DistUnit.km,
    );

    expect(find.text('5:36/km (9:00/mi)'), findsOneWidget);
    expect(find.text('5:54-6:13/km (9:30-10:00/mi)'), findsOneWidget);
    expect(find.text('4.8 km (3 mi)'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('shows kind, leaders with role tags, going counts and badge', (
    tester,
  ) async {
    await pumpDetail(tester, groups: [fast, slow, noPace]);

    expect(find.text('Jog/walk'), findsOneWidget);
    expect(find.text('Pace group'), findsNWidgets(2));
    expect(find.text('Led by Jo Bloggs'), findsOneWidget);
    expect(
      find.text('Led by Sam Lapsed, Pat Back (backmarker)'),
      findsOneWidget,
    );
    expect(find.text('5 going, 1 maybe'), findsOneWidget);
    expect(find.text('Needs a leader'), findsOneWidget);
    expect(find.text('No leader yet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('collapses a long description until expanded', (tester) async {
    final long = List.filled(40, 'muster').join(' ');
    await pumpDetail(tester, groups: [groupJson('g', description: long)]);

    expect(find.text('Show more'), findsOneWidget);
    await tester.tap(find.text('Show more'));
    await tester.pump();
    expect(find.text('Show less'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('empty state offers to lead; cancelled run is read-only', (
    tester,
  ) async {
    await pumpDetail(tester);
    expect(
      find.text('No groups yet. Leaders can offer to lead one.'),
      findsOneWidget,
    );
    expect(find.text('Lead a group'), findsOneWidget);
    await unmount(tester);

    await db.clearAll();
    await pumpDetail(tester, groups: [fast], status: 'cancelled');
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Join this group'), findsNothing);
    expect(find.text('Lead a group'), findsNothing);
    expect(find.text("I'll lead this group too"), findsNothing);
    expect(find.byTooltip('Group options'), findsNothing);
    expect(
      find.textContaining("This run has been cancelled. You can't respond"),
      findsOneWidget,
    );
    expect(find.text("I'm coming"), findsNothing);
    await unmount(tester);
  });

  testWidgets('session-mode wording', (tester) async {
    await pumpDetail(tester, groups: [fast]);
    expect(find.text('Pace groups'), findsOneWidget);
    await unmount(tester);

    await db.clearAll();
    await pumpDetail(tester, groups: [fast], groupMode: 'single');
    expect(find.text('Coached session'), findsOneWidget);
    // One group in a coached session: no second "Lead a group".
    expect(find.text('Lead a group'), findsNothing);
    await unmount(tester);

    await db.clearAll();
    await pumpDetail(tester, groupMode: 'open');
    expect(
      find.text(
        'Everyone starts together; you can say what pace you will run and '
        'others can join you.',
      ),
      findsOneWidget,
    );
    await unmount(tester);

    await db.clearAll();
    await pumpDetail(tester, groupMode: 'routes');
    expect(find.text('Routes'), findsOneWidget);
    await unmount(tester);
  });

  group('edit and delete visibility', () {
    Future<void> check(
      WidgetTester tester, {
      required bool visible,
      List<String> roles = const [],
      String? coordinator,
      List<Map<String, Object?>>? groups,
    }) async {
      await pumpDetail(
        tester,
        roles: roles,
        coordinator: coordinator,
        groups: groups ?? [fast],
      );
      expect(
        find.byTooltip('Group options'),
        visible ? findsOneWidget : findsNothing,
      );
      if (visible) {
        await tester.tap(find.byTooltip('Group options'));
        await tester.pumpAndSettle();
        expect(find.text('Edit group'), findsOneWidget);
        expect(find.text('Delete group'), findsOneWidget);
      }
      await unmount(tester);
      await db.clearAll();
    }

    testWidgets('a plain member cannot edit or delete', (tester) async {
      await check(tester, visible: false);
    });

    testWidgets('a leader of the group can', (tester) async {
      final mine = groupJson(
        'mine',
        label: 'Mine',
        leaders: [leaderJson('me', name: 'Jo Bloggs')],
      );
      await check(tester, visible: true, groups: [mine]);
    });

    testWidgets('the session coordinator can', (tester) async {
      await check(tester, visible: true, coordinator: 'me');
    });

    testWidgets('committee and admin can', (tester) async {
      await check(tester, visible: true, roles: ['committee']);
      await check(tester, visible: true, roles: ['admin']);
    });

    testWidgets('a leader badge alone does not', (tester) async {
      await check(tester, visible: false, roles: ['leader']);
    });
  });

  group('Sunday routes', () {
    final route = groupJson(
      'r1',
      kind: 'route',
      label: '10 mile loop',
      description: 'Meet at the bridge',
      paceUnit: null,
      paceFromS: null,
      paceToS: null,
      paceFromSPerKm: null,
      paceToSPerKm: null,
      distanceValue: 10,
      distanceUnit: 'mi',
      goingCount: 3,
    );

    testWidgets('a plain member can join a route but not add one', (
      tester,
    ) async {
      await pumpDetail(tester, groupMode: 'routes', groups: [route]);
      expect(find.text('Add route'), findsNothing);
      expect(find.text("I'm doing this route"), findsOneWidget);
      expect(find.text('10 mi'), findsOneWidget);
      expect(find.text('Meet at the bridge'), findsOneWidget);
      expect(find.text('3 going'), findsOneWidget);
      expect(find.text('Lead a group'), findsOneWidget);
      // The pace action sits next to the routes, once.
      expect(find.text('My pace for this run'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('committee and the coordinator see Add route', (tester) async {
      await pumpDetail(
        tester,
        roles: ['committee'],
        groupMode: 'routes',
        groups: [route],
      );
      expect(find.text('Add route'), findsOneWidget);
      await unmount(tester);

      await db.clearAll();
      await pumpDetail(
        tester,
        groupMode: 'routes',
        groups: [route],
        coordinator: 'me',
      );
      expect(find.text('Add route'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('a group I lead', () {
    final mineLed = groupJson(
      'mine',
      label: 'Mine',
      leaders: [leaderJson('me', name: 'Jo Bloggs')],
      goingCount: 1,
    );

    testWidgets('has no Join or Leave, only Step down', (tester) async {
      await pumpDetail(
        tester,
        groups: [mineLed, fast],
        summary: summaryJson(
          groupCount: 2,
          myStatus: 'going',
          myGroupId: 'mine',
          myLeading: true,
        ),
      );
      expect(find.text("You're leading this group"), findsOneWidget);
      expect(find.text("You're in this group"), findsNothing);
      expect(find.text('Step down'), findsOneWidget);
      expect(find.text('Leave group'), findsNothing);
      // Only the other group (which I do not lead) can be joined.
      expect(find.text('Join this group'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('even before the attendance row catches up', (tester) async {
      await pumpDetail(tester, groups: [mineLed]);
      expect(find.text('Join this group'), findsNothing);
      expect(find.text('Leave group'), findsNothing);
      expect(find.text('Step down'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a member of a group they do not lead is unchanged', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        groups: [fast],
        summary: summaryJson(
          groupCount: 1,
          myStatus: 'going',
          myGroupId: 'fast',
        ),
      );
      expect(find.text("You're in this group"), findsOneWidget);
      expect(find.text('Leave group'), findsOneWidget);
      expect(find.text('Join this group'), findsNothing);
      await unmount(tester);
    });

    testWidgets('after stepping down I am still in it and can leave', (
      tester,
    ) async {
      final withMe = groupJson(
        'mine',
        label: 'Mine',
        leaders: [leaderJson('l1', name: 'Pat')],
        goingCount: 1,
      );
      await pumpDetail(
        tester,
        groups: [withMe],
        summary: summaryJson(
          groupCount: 1,
          myStatus: 'going',
          myGroupId: 'mine',
        ),
      );
      expect(find.text("You're in this group"), findsOneWidget);
      expect(find.text('Leave group'), findsOneWidget);
      expect(find.text('Step down'), findsNothing);
      await unmount(tester);
    });
  });
}
