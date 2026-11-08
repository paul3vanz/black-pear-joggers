import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/ui/coverage_card.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _plan = '/app/clubs/1/sessions/a/plan';

void main() {
  late AppDatabase db;

  // The detail screen lists the groups too; look inside the coverage card.
  Finder inCard(Finder f) =>
      find.descendant(of: find.byType(CoverageCard), matching: f);

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Map<String, Object?> led(
    String id, {
    int? from = 540,
    int? to,
    String kind = 'run',
    String? label,
  }) => groupJson(
    id,
    kind: kind,
    label: label,
    paceUnit: from == null ? null : 'mi',
    paceFromS: from,
    paceToS: to,
    paceFromSPerKm: null,
    paceToSPerKm: null,
    leaders: [leaderJson('l$id', name: 'Jo Bloggs')],
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<Map<String, Object?>> groups,
    List<String> roles = const ['committee'],
    DistUnit paceUnit = DistUnit.mi,
    Map<String, Object?>? plan,
    String groupMode = 'paced',
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      routes: {if (plan != null) 'GET $_plan': FakeResponse(200, plan)},
    );
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: groups,
        summary: summaryJson(groupCount: groups.length),
        groupMode: groupMode,
      );
      await seedUnits(db, pace: paceUnit);
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

  testWidgets('committee sees the groups in pace order with the gap between', (
    tester,
  ) async {
    await pump(tester, groups: [led('a', from: 480), led('b', from: 630)]);
    expect(find.text('Group coverage'), findsOneWidget);
    // Groups are rows, fastest first, with the gap between them.
    expect(inCard(find.text('8:00/mi')), findsOneWidget);
    expect(inCard(find.text('10:30/mi')), findsOneWidget);
    expect(inCard(find.text('Jo Bloggs')), findsNWidgets(2));
    final gap = find.text('Gap · 8:15 to 10:15/mi');
    expect(gap, findsOneWidget);
    expect(find.text('Nobody between 8:00 and 10:30'), findsOneWidget);
    double top(Finder f) => tester.getTopLeft(f).dy;
    expect(top(inCard(find.text('8:00/mi'))), lessThan(top(gap)));
    expect(top(gap), lessThan(top(inCard(find.text('10:30/mi')))));
    // The header says what is left: one red gap, and amber things to add.
    expect(find.byKey(const ValueKey('coverage-status')), findsOneWidget);
    expect(find.text('1 gap'), findsOneWidget);
    expect(find.text('Add if you can: slower end, jog/walk'), findsOneWidget);
    expect(find.text('Nothing slower than 11:30/mi'), findsOneWidget);
    expect(find.text('Covered'), findsNothing);
    await finish(tester);
  });

  testWidgets('9:15 and 10:30 leave a gap, 8:00 and 8:40 do not', (
    tester,
  ) async {
    await pump(tester, groups: [led('a', from: 555), led('b', from: 630)]);
    expect(find.text('Gap · 9:30 to 10:15/mi'), findsOneWidget);
    await unmount(tester);
    await db.clearAll();

    await pump(tester, groups: [led('a', from: 480), led('b', from: 520)]);
    expect(find.textContaining('Gap ·'), findsNothing);
    await finish(tester);
  });

  testWidgets('a single pace and a range are labelled and treated alike', (
    tester,
  ) async {
    await pump(
      tester,
      groups: [led('a', from: 540, to: 555), led('b', from: 630)],
    );
    expect(inCard(find.text('9:00-9:15/mi')), findsOneWidget);
    expect(inCard(find.textContaining('Range')), findsOneWidget);
    expect(inCard(find.textContaining('Single pace')), findsOneWidget);
    // The range's slow edge (9:15) sets the gap, exactly as a single 9:15 would.
    expect(find.text('Gap · 9:30 to 10:15/mi'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a full spread with jog/walk is covered', (tester) async {
    await pump(
      tester,
      groups: [
        led('a', from: 465, to: 480),
        for (final (i, p) in [520, 560, 600, 640, 680, 720].indexed)
          led('s$i', from: p),
        led('j', from: null, kind: 'jog_walk'),
      ],
    );
    expect(find.text('Covered'), findsOneWidget);
    expect(find.textContaining('Gap ·'), findsNothing);
    expect(find.textContaining('Nothing faster'), findsNothing);
    expect(find.textContaining('Nothing slower'), findsNothing);
    await finish(tester);
  });

  testWidgets('one group at 8:45 only has amber things to add', (tester) async {
    await pump(tester, groups: [led('a', from: 525)]);
    expect(find.text('Covered'), findsNothing);
    expect(find.text('Nothing faster than 8:30/mi'), findsOneWidget);
    expect(find.text('Nothing slower than 11:30/mi'), findsOneWidget);
    expect(find.text('Jog/walk: nobody yet'), findsOneWidget);
    expect(find.textContaining('Gap ·'), findsNothing);
    expect(find.text('1 gap'), findsNothing);
    await finish(tester);
  });

  testWidgets('a plain member does not see it', (tester) async {
    await pump(tester, roles: const [], groups: [led('a')]);
    expect(find.text('Group coverage'), findsNothing);
    await finish(tester);
  });

  testWidgets('a led jog/walk group replaces the jog/walk row', (tester) async {
    await pump(
      tester,
      groups: [
        led('a', from: 480),
        led('j', from: null, kind: 'jog_walk'),
      ],
    );
    expect(inCard(find.text('Jog/walk')), findsOneWidget);
    expect(find.text('Jog/walk: nobody yet'), findsNothing);
    expect(find.text('Nothing slower than 11:30/mi'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('groups without a leader are listed as needing one', (
    tester,
  ) async {
    await pump(
      tester,
      groups: [
        led('a'),
        groupJson('x', paceFromS: 660, paceToS: null, status: 'needs_leader'),
      ],
    );
    // On the list at its pace, flagged, and not counted as covered.
    expect(inCard(find.text('Needs a leader')), findsOneWidget);
    expect(inCard(find.text('11:00/mi')), findsOneWidget);
    expect(find.text('1 group needs a leader'), findsOneWidget);
    expect(find.text('Nothing slower than 11:30/mi'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('empty states', (tester) async {
    await pump(tester, groups: const []);
    expect(find.text('No groups yet'), findsOneWidget);
    await unmount(tester);
    await db.clearAll();

    await pump(tester, groups: [groupJson('x', status: 'needs_leader')]);
    expect(find.text('No groups with a leader yet'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('km viewers get the same rule in km', (tester) async {
    await pump(
      tester,
      paceUnit: DistUnit.km,
      groups: [
        groupJson(
          'k',
          paceUnit: 'km',
          paceFromS: 360,
          paceToS: null,
          leaders: [leaderJson('lk')],
        ),
      ],
    );
    expect(find.text('Nothing slower than 7:10/km'), findsOneWidget);
    expect(find.text('Nothing faster than 5:15/km'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('only paced runs get the spread: an open run just lists groups', (
    tester,
  ) async {
    await pump(tester, groupMode: 'open', groups: [led('a', from: 600)]);
    expect(inCard(find.text('10:00/mi')), findsOneWidget);
    expect(find.textContaining('Nothing faster'), findsNothing);
    expect(find.textContaining('Nothing slower'), findsNothing);
    expect(find.text('Jog/walk: nobody yet'), findsNothing);
    await finish(tester);
  });

  group('people coming with no matching group', () {
    Map<String, Object?> planWith(List<Map<String, Object?>> people) =>
        planJson(
          'a',
          groups: [groupPlanJson('a', attendees: const [])],
          unassignedGoing: people.length,
          unassignedMembers: people,
        );

    testWidgets('is hidden when every pace is covered', (tester) async {
      await pump(
        tester,
        groups: [led('a', from: 540)],
        plan: planWith([attendeeJson('u1', 'Una Near', paceFromS: 550)]),
      );
      expect(find.text('Group coverage'), findsOneWidget);
      expect(find.text('People coming with no matching group'), findsNothing);
      expect(find.textContaining('Every pace has a group'), findsNothing);
      await finish(tester);
    });

    testWidgets('lists uncovered paces and people with no pace', (
      tester,
    ) async {
      await pump(
        tester,
        groups: [led('a', from: 540)],
        plan: planWith([
          attendeeJson('u1', 'Una Slow', paceFromS: 700),
          attendeeJson('u2', 'Nell', paceUnit: null, paceFromS: null),
        ]),
      );
      expect(find.text('People coming with no matching group'), findsOneWidget);
      expect(
        find.textContaining('Based on the 2 people who have said'),
        findsOneWidget,
      );
      expect(find.textContaining('1 runner around'), findsOneWidget);
      expect(find.text('1 going with no pace set'), findsOneWidget);
      await finish(tester);
    });
  });
}
