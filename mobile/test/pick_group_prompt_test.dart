import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/small_kv_store.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _put = '/app/clubs/1/sessions/a/attendance';
const _title = 'Pick your pace group?';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final fast = groupJson(
    'fast',
    label: 'Tempo',
    paceFromS: 540,
    paceToS: null,
    leaders: [leaderJson('l1', name: 'Jo Bloggs')],
    goingCount: 5,
    maybeCount: 1,
  );
  final slow = groupJson('slow', label: 'Steady', paceFromS: 600, paceToS: 660);

  Future<void> pumpDetail(
    WidgetTester tester, {
    List<Map<String, Object?>>? groups,
    Map<String, Object?>? summary,
    String groupMode = 'paced',
    bool alreadyPrompted = false,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      routes: {
        'PUT $_put': FakeResponse(200, attendanceJson('a')),
        'GET $_put': const FakeResponse(200, null),
      },
    );
    final list = groups ?? [fast, slow];
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: list,
        summary: summary ?? summaryJson(groupCount: list.length),
        groupMode: groupMode,
      );
      await seedUnits(db);
      if (alreadyPrompted) {
        await SmallKvStore(db).set(SmallKvStore.pickGroupKey(1, 'a'), '1');
      }
    });
    await pumpGroupsApp(
      tester,
      db,
      adapter,
      const SessionDetailScreen(sessionId: 'a'),
    );
  }

  Future<void> tapComing(WidgetTester tester) async {
    await tester.tap(find.text("I'm coming"));
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  Map<String, Object?> body(int i) =>
      Map<String, Object?>.from(sent(adapter, 'PUT', _put)[i].data as Map);

  testWidgets('offers the groups after "I\'m coming" and Join picks one', (
    tester,
  ) async {
    await pumpDetail(tester);
    await tapComing(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Join'), findsNWidgets(2));
    expect(find.text('Led by Jo Bloggs'), findsWidgets);
    expect(find.text('5 going, 1 maybe'), findsWidgets);
    expect(find.text("I'll decide on the day"), findsOneWidget);
    expect(body(0), {'status': 'going'});

    await tester.tap(find.text('Join').first);
    await settle(tester);
    expect(find.text(_title), findsNothing);
    // The existing join flow: going with the chosen group.
    expect(body(1), {'status': 'going', 'groupId': 'fast'});
    await finish(tester);
  });

  testWidgets('"I\'ll decide on the day" closes it and it is not asked again', (
    tester,
  ) async {
    await pumpDetail(tester);
    await tapComing(tester);
    await tester.tap(find.text("I'll decide on the day"));
    await settle(tester);
    expect(find.text(_title), findsNothing);
    expect(sent(adapter, 'PUT', _put), hasLength(1));

    // Remembered per run and device: switching away and back stays quiet.
    await tester.tap(find.text('Maybe'));
    await settle(tester);
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    final stored = await tester.runAsync(
      () => SmallKvStore(db).get(SmallKvStore.pickGroupKey(1, 'a')),
    );
    expect(stored, isNotNull);
    await finish(tester);
  });

  testWidgets('dismissing by tapping away also counts as asked', (
    tester,
  ) async {
    await pumpDetail(tester);
    await tapComing(tester);
    await tester.tapAt(const Offset(10, 10)); // the scrim
    await settle(tester);
    expect(find.text(_title), findsNothing);
    await tester.tap(find.text("Can't come"));
    await settle(tester);
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    await finish(tester);
  });

  testWidgets('never after Maybe or "Can\'t come"', (tester) async {
    await pumpDetail(tester);
    await tester.tap(find.text('Maybe'));
    await settle(tester);
    expect(find.text(_title), findsNothing);
    await tester.tap(find.text("Can't come"));
    await settle(tester);
    expect(find.text(_title), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    await finish(tester);
  });

  testWidgets('not for someone leading a group', (tester) async {
    await pumpDetail(
      tester,
      summary: summaryJson(groupCount: 2, myLeading: true),
    );
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    await finish(tester);
  });

  testWidgets('not for someone who leads according to the group list', (
    tester,
  ) async {
    final mine = groupJson('mine', label: 'Mine', leaders: [leaderJson('me')]);
    await pumpDetail(tester, groups: [mine, slow]);
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    await finish(tester);
  });

  testWidgets('not for someone already in a group', (tester) async {
    await pumpDetail(
      tester,
      summary: summaryJson(groupCount: 2, myStatus: 'maybe', myGroupId: 'slow'),
    );
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    await finish(tester);
  });

  testWidgets('not when this run was already prompted', (tester) async {
    await pumpDetail(tester, alreadyPrompted: true);
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    await finish(tester);
  });

  testWidgets('no groups: a snackbar instead of the sheet', (tester) async {
    await pumpDetail(tester, groups: const []);
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    expect(
      find.text(
        "Pace groups are confirmed at the start. We'll let you know if one is "
        'added that suits you.',
      ),
      findsOneWidget,
    );
    await finish(tester);
  });

  testWidgets('groups that still need a leader are not offered', (
    tester,
  ) async {
    final needs = groupJson('n', status: 'needs_leader');
    await pumpDetail(tester, groups: [needs]);
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    expect(find.textContaining('Pace groups are confirmed'), findsWidgets);
    await finish(tester);
  });

  testWidgets('Sunday routes runs are not asked', (tester) async {
    await pumpDetail(tester, groupMode: 'routes');
    await tapComing(tester);
    expect(find.text(_title), findsNothing);
    await finish(tester);
  });
}
