import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/runs/ui/runs_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase8.dart';
import 'support/groups_test_support.dart';

/// Phase 8c: the Runs-tab card for `events` and `race` runs (D79, D84).
void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pumpCard(
    WidgetTester tester, {
    String mode = 'events',
    List<Map<String, Object?>> groups = const [],
    Map<String, Object?>? summary,
  }) async {
    final adapter = await prepareMember(tester, db);
    await tester.runAsync(
      () => seedSession(
        db,
        'a',
        localDate: localDateString(DateTime.now()),
        groupMode: mode,
        groups: groups,
        summary: summary,
      ),
    );
    await pumpGroupsApp(tester, db, adapter, const RunsScreen());
  }

  Finder anyGroupsText() =>
      find.textContaining(RegExp('groups?', caseSensitive: false));

  group('events summary line', () {
    testWidgets('nobody yet', (tester) async {
      await pumpCard(tester, summary: summaryJson());
      expect(find.text('No one has picked a parkrun yet'), findsOneWidget);
      expect(anyGroupsText(), findsNothing);
      await unmount(tester);
    });

    testWidgets('one person, one event', (tester) async {
      await pumpCard(
        tester,
        groups: [
          eventGroupJson('g1', label: 'Worcester parkrun', goingCount: 1),
        ],
        summary: summaryJson(groupCount: 1, goingCount: 1),
      );
      expect(find.text('1 going to 1 event'), findsOneWidget);
      expect(anyGroupsText(), findsNothing);
      await unmount(tester);
    });

    testWidgets('three people, two events', (tester) async {
      await pumpCard(
        tester,
        groups: [
          eventGroupJson('g1', label: 'Worcester parkrun', goingCount: 2),
          eventGroupJson('g2', label: 'Bromsgrove parkrun', goingCount: 1),
          // An event nobody is going to does not count.
          eventGroupJson('g3', label: 'Cannon Hill parkrun'),
        ],
        summary: summaryJson(groupCount: 3, goingCount: 3),
      );
      expect(find.text('3 going to 2 events'), findsOneWidget);
      expect(anyGroupsText(), findsNothing);
      await unmount(tester);
    });

    testWidgets('going with no event picked is just "1 going"', (tester) async {
      await pumpCard(
        tester,
        groups: [eventGroupJson('g1', label: 'Worcester parkrun')],
        summary: summaryJson(groupCount: 1, goingCount: 1),
      );
      expect(find.text('1 going'), findsOneWidget);
      expect(find.textContaining(' to '), findsNothing);
      await unmount(tester);
    });

    testWidgets('people with no event add to the going count', (tester) async {
      await pumpCard(
        tester,
        groups: [
          eventGroupJson('g1', label: 'Worcester parkrun', goingCount: 2),
        ],
        summary: summaryJson(groupCount: 1, goingCount: 3),
      );
      expect(find.text('3 going to 1 event'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('you are in an event: the chip names it', (tester) async {
      await pumpCard(
        tester,
        groups: [
          eventGroupJson('g1', label: 'Worcester parkrun', goingCount: 1),
        ],
        summary: summaryJson(
          groupCount: 1,
          goingCount: 1,
          myStatus: 'going',
          myGroupId: 'g1',
        ),
      );
      expect(find.text("You're going to Worcester parkrun"), findsOneWidget);
      expect(find.text("You're going"), findsNothing);
      expect(find.text('1 going to 1 event'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('you are going with no event: the plain chip', (tester) async {
      await pumpCard(
        tester,
        summary: summaryJson(goingCount: 1, myStatus: 'going'),
      );
      expect(find.text("You're going"), findsOneWidget);
      expect(find.text('1 going'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('your other answers keep their chips', (tester) async {
      await pumpCard(
        tester,
        groups: [eventGroupJson('g1', label: 'Worcester parkrun')],
        summary: summaryJson(groupCount: 1, myStatus: 'not_going'),
      );
      expect(find.text("Can't come"), findsOneWidget);
      expect(find.text('No one has picked a parkrun yet'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no "needs a leader" or leading chip, ever', (tester) async {
      await pumpCard(
        tester,
        groups: [
          eventGroupJson('g1', label: 'Worcester parkrun', goingCount: 1),
        ],
        summary: summaryJson(
          groupCount: 1,
          goingCount: 1,
          myStatus: 'going',
          myGroupId: 'g1',
          myLeading: true,
        ),
      );
      expect(find.text("You're leading"), findsNothing);
      expect(find.textContaining('leader'), findsNothing);
      await unmount(tester);
    });
  });

  group('race summary line', () {
    testWidgets('nobody yet', (tester) async {
      await pumpCard(
        tester,
        mode: 'race',
        groups: [eventGroupJson('g1', label: 'Droitwich 10k')],
        summary: summaryJson(groupCount: 1),
      );
      expect(find.text("No one has said they're going yet"), findsOneWidget);
      expect(anyGroupsText(), findsNothing);
      await unmount(tester);
    });

    testWidgets('four going and you are one of them', (tester) async {
      await pumpCard(
        tester,
        mode: 'race',
        groups: [eventGroupJson('g1', label: 'Droitwich 10k', goingCount: 4)],
        summary: summaryJson(
          groupCount: 1,
          goingCount: 4,
          myStatus: 'going',
          myGroupId: 'g1',
        ),
      );
      expect(find.text('4 going'), findsOneWidget);
      expect(find.textContaining(' to '), findsNothing);
      expect(find.text("You're going"), findsOneWidget);
      expect(anyGroupsText(), findsNothing);
      await unmount(tester);
    });
  });

  testWidgets('pace runs still show their group count', (tester) async {
    await pumpCard(
      tester,
      mode: 'paced',
      groups: [groupJson('g1'), groupJson('g2')],
      summary: summaryJson(groupCount: 2, goingCount: 5),
    );
    expect(find.text('2 groups · 5 going'), findsOneWidget);
    await unmount(tester);
  });
}
