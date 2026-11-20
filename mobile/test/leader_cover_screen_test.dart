import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/ui/leader_cover_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

/// Profile > Leader cover (D127, D128): the next four weeks of runs that use
/// pace groups, each with the picture of who leads and where the holes are.
/// "Now" is 2026-10-07, so four weeks end on 2026-11-04.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Map<String, Object?> group(
    String id, {
    int? from,
    int? to,
    String kind = 'run',
    bool led = true,
  }) => groupJson(
    id,
    kind: kind,
    paceUnit: from == null ? null : 'mi',
    paceFromS: from,
    paceToS: to,
    paceFromSPerKm: null,
    paceToSPerKm: null,
    leaders: led ? [leaderJson('l$id', name: 'Jo Bloggs')] : const [],
    status: led ? 'active' : 'needs_leader',
  );

  /// A run on 2026-10-12 with a gap (9:15 and 10:30), one covered run, one with
  /// no groups, an open run that is covered, and three that must not show: a
  /// cancelled one, a routes one, and one beyond four weeks.
  Future<void> seed(
    WidgetTester tester, {
    List<String> roles = const ['committee'],
  }) async {
    final adapter = await prepareMember(tester, db, roles: roles);
    await tester.runAsync(() async {
      await seedSession(
        db,
        'gap',
        localDate: '2026-10-12',
        groups: [group('g1', from: 555), group('g2', from: 630)],
      );
      await seedSession(
        db,
        'full',
        localDate: '2026-10-14',
        groups: [
          group('f0', from: 465, to: 480),
          for (final (i, p) in [510, 540, 570, 600, 630, 660, 690].indexed)
            group('f${i + 1}', from: p),
          group('fj', kind: 'jog_walk'),
        ],
      );
      await seedSession(db, 'none', localDate: '2026-10-20', groups: const []);
      await seedSession(
        db,
        'open',
        localDate: '2026-10-21',
        groupMode: 'open',
        groups: [group('o1', from: 600)],
      );
      await seedSession(
        db,
        'cancelled',
        localDate: '2026-10-13',
        status: 'cancelled',
        groups: const [],
      );
      await seedSession(
        db,
        'routes',
        localDate: '2026-10-15',
        groupMode: 'routes',
        groups: const [],
      );
      await seedSession(db, 'later', localDate: '2026-12-01', groups: const []);
    });
    await pumpGroupsApp(tester, db, adapter, const LeaderCoverScreen());
  }

  Finder run(String id) => find.byKey(ValueKey('cover-$id'));
  Finder inRun(String id, Finder f) =>
      find.descendant(of: run(id), matching: f);

  testWidgets('lists the runs in the next four weeks that use pace groups', (
    tester,
  ) async {
    await seed(tester);

    for (final id in ['gap', 'full', 'none', 'open']) {
      expect(run(id), findsOneWidget, reason: id);
    }
    for (final id in ['cancelled', 'routes', 'later']) {
      expect(run(id), findsNothing, reason: id);
    }
    expect(
      find.textContaining('2 runs could use a leader.'),
      findsOneWidget,
    ); // the gap run and the empty one
    await unmount(tester);
  });

  testWidgets('runs that need attention are open, covered ones are collapsed', (
    tester,
  ) async {
    await seed(tester);

    // The gap run shows its groups and the gap between them.
    expect(inRun('gap', find.text('9:15/mi')), findsOneWidget);
    expect(inRun('gap', find.text('10:30/mi')), findsOneWidget);
    expect(
      inRun('gap', find.text('Need groups between 9:45/mi and 10:00/mi')),
      findsOneWidget,
    );
    expect(inRun('gap', find.text('1 gap')), findsOneWidget);

    // A run with no groups says so and offers the ask.
    expect(inRun('none', find.text('No groups yet')), findsWidgets);
    expect(find.byKey(const ValueKey('ask-run')), findsOneWidget);

    // The covered run says Covered and stays closed until tapped.
    expect(inRun('full', find.text('Covered')), findsOneWidget);
    expect(inRun('full', find.text('7:45-8:00/mi')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cover-toggle-full')));
    await tester.pump();
    expect(inRun('full', find.text('7:45-8:00/mi')), findsOneWidget);
    expect(inRun('full', find.textContaining('Range')), findsOneWidget);

    // And a run that needs attention can be closed by hand.
    await tester.tap(find.byKey(const ValueKey('cover-toggle-gap')));
    await tester.pump();
    expect(inRun('gap', find.text('9:15/mi')), findsNothing);
    await unmount(tester);
  });

  testWidgets('a run without a spread target just says Covered', (
    tester,
  ) async {
    await seed(tester);

    expect(inRun('open', find.text('Covered')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the toggle hides runs that are fine', (tester) async {
    await seed(tester);

    await tester.tap(find.byKey(const ValueKey('only-needs')));
    await tester.pump();

    expect(run('gap'), findsOneWidget);
    expect(run('none'), findsOneWidget);
    expect(run('full'), findsNothing);
    expect(run('open'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a plain member is told it is for the committee', (tester) async {
    await seed(tester, roles: const []);

    expect(
      find.text('Only committee members and admins can see this.'),
      findsOneWidget,
    );
    expect(run('gap'), findsNothing);
    await unmount(tester);
  });

  testWidgets('each run has an Open run button', (tester) async {
    await seed(tester);

    expect(find.byKey(const ValueKey('cover-open-gap')), findsOneWidget);
    await unmount(tester);
  });
}
