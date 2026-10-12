import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/groups/data/small_kv_store.dart';
import 'package:bpj/features/groups/logic/roster.dart';
import 'package:bpj/features/groups/ui/leader_roster_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

const _put = '/app/clubs/1/sessions/mon/attendance';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late List<Uri> opened;

  setUp(() {
    db = memoryDb();
    opened = [];
  });
  tearDown(() => db.close());

  // "Now" is Wed 7 Oct 2026. mon = Mon 12, tue1 = Tue 13, wed = Wed 14,
  // tue2 = Tue 20; lead = Wed 21 and the viewer leads a group on it.
  Future<void> pumpRoster(
    WidgetTester tester, {
    List<String> days = const ['mon', 'tue1', 'wed', 'tue2', 'lead'],
    String? storedDays,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      routes: {
        'PUT $_put': FakeResponse(
          200,
          attendanceJson('mon', status: 'not_going'),
        ),
      },
    );
    const dates = {
      'mon': '2026-10-12',
      'tue1': '2026-10-13',
      'wed': '2026-10-14',
      'tue2': '2026-10-20',
      'lead': '2026-10-21',
    };
    await tester.runAsync(() async {
      await seedUnits(db);
      for (final id in days) {
        final leading = id == 'lead';
        await seedSession(
          db,
          id,
          localDate: dates[id]!,
          groups: leading
              ? [
                  groupJson(
                    'g-$id',
                    sessionId: id,
                    leaders: [leaderJson('me', name: 'Jo Bloggs')],
                  ),
                ]
              : const [],
          summary: summaryJson(groupCount: leading ? 1 : 0, myLeading: leading),
        );
      }
      if (storedDays != null) {
        await SmallKvStore(db).set(SmallKvStore.leadDaysKey(1), storedDays);
      }
    });
    final router = GoRouter(
      initialLocation: '/runs/lead',
      routes: [
        GoRoute(
          path: '/runs/lead',
          builder: (_, _) => const LeaderRosterScreen(),
        ),
        GoRoute(
          path: '/runs/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail ${state.pathParameters['id']}')),
        ),
      ],
    );
    tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, fakeDio(adapter)),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  Finder card(String id) => find.byKey(ValueKey(id));
  Finder chip(String day) => find.widgetWithText(FilterChip, day);

  Future<String?> storedDays(WidgetTester tester) async =>
      tester.runAsync<String?>(
        () => SmallKvStore(db).get(SmallKvStore.leadDaysKey(1)),
      );

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  }

  group('day filter', () {
    testWidgets('only offers weekdays that appear in the runs', (tester) async {
      await pumpRoster(tester);
      expect(chip('Mon'), findsOneWidget);
      expect(chip('Tue'), findsOneWidget);
      expect(chip('Wed'), findsOneWidget);
      expect(chip('Thu'), findsNothing);
      expect(chip('Sun'), findsNothing);
      expect(find.text('Show all'), findsNothing);
      expect(find.byType(Card), findsNWidgets(5));
      await finish(tester);
    });

    testWidgets('is hidden when every run is on the same weekday', (
      tester,
    ) async {
      await pumpRoster(tester, days: ['tue1', 'tue2']);
      expect(find.byType(FilterChip), findsNothing);
      expect(card('tue1'), findsOneWidget);
      expect(card('tue2'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('filters, keeps the runs I lead, counts and remembers', (
      tester,
    ) async {
      await pumpRoster(tester);
      await tester.tap(chip('Tue'));
      await settle(tester);

      expect(card('tue1'), findsOneWidget);
      expect(card('tue2'), findsOneWidget);
      expect(card('mon'), findsNothing);
      expect(card('wed'), findsNothing);
      // I lead 'lead' (a Wednesday): still shown despite the filter.
      expect(card('lead'), findsOneWidget);
      expect(find.text('2 runs hidden by your day filter'), findsOneWidget);
      expect(find.text('Show all'), findsOneWidget);
      expect(await storedDays(tester), '2'); // Tuesday

      // Multi-select: add Monday.
      await tester.tap(chip('Mon'));
      await settle(tester);
      expect(card('mon'), findsOneWidget);
      expect(find.text('1 run hidden by your day filter'), findsOneWidget);
      expect(await storedDays(tester), '1,2');

      await tester.tap(find.text('Show all'));
      await settle(tester);
      expect(card('wed'), findsOneWidget);
      expect(find.textContaining('hidden by your day filter'), findsNothing);
      expect(find.text('Show all'), findsNothing);
      expect(await storedDays(tester), isNull);
      await finish(tester);
    });

    testWidgets('a remembered selection is applied when the page opens', (
      tester,
    ) async {
      await pumpRoster(tester, storedDays: '3'); // Wednesday
      expect(card('wed'), findsOneWidget);
      expect(card('lead'), findsOneWidget);
      expect(card('mon'), findsNothing);
      expect(find.text('3 runs hidden by your day filter'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a remembered day with no runs is ignored', (tester) async {
      await pumpRoster(tester, storedDays: '5'); // Friday: none
      expect(card('mon'), findsOneWidget);
      expect(find.textContaining('hidden by your day filter'), findsNothing);
      expect(find.text('Show all'), findsNothing);
      await finish(tester);
    });
  });

  group("Can't attend", () {
    testWidgets('collapses the card to one line, in place, with no Undo', (
      tester,
    ) async {
      await pumpRoster(tester);
      final before = tester.getTopLeft(card('tue1')).dy;
      // Not offered on the run I lead.
      expect(
        find.descendant(of: card('lead'), matching: find.text("Can't attend")),
        findsNothing,
      );
      final fullHeight = tester.getSize(card('mon')).height;

      await tester.tap(
        find.descendant(of: card('mon'), matching: find.text("Can't attend")),
      );
      await settle(tester);

      expect(sent(adapter, 'PUT', _put).single.data, {'status': 'not_going'});
      // The one-line view: day and time, the label and "Change" (the API has
      // no way to clear an answer, so there is no Undo).
      expect(
        find.descendant(
          of: card('mon'),
          matching: find.text('Mon 12 Oct, 7pm'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card('mon'), matching: find.text("Can't attend")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card('mon'), matching: find.text('Offer to lead')),
        findsNothing,
      );
      expect(find.text('Undo'), findsNothing);
      expect(tester.getSize(card('mon')).height, lessThan(fullHeight / 2));
      // Still in date order: the next card follows directly.
      expect(tester.getTopLeft(card('tue1')).dy, lessThan(before));
      expect(
        tester.getTopLeft(card('mon')).dy,
        lessThan(tester.getTopLeft(card('tue1')).dy),
      );
      await finish(tester);
    });

    testWidgets('Change opens the run to answer again', (tester) async {
      await pumpRoster(tester);
      await tester.tap(
        find.descendant(of: card('mon'), matching: find.text("Can't attend")),
      );
      await settle(tester);
      await tester.tap(find.text('Change'));
      await settle(tester);
      expect(find.text('detail mon'), findsOneWidget);
      await finish(tester);
    });
  });

  testWidgets('has a tips link that opens the website page', (tester) async {
    await pumpRoster(tester);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    await tester.tap(find.text('Tips on leading a group'));
    await settle(tester);
    expect(opened, [Uri.parse('https://bpj.org.uk/leading-a-group')]);
    await finish(tester);
  });

  group('roster helpers', () {
    test('decode and encode weekday lists', () {
      expect(decodeWeekdays('1,3'), {1, 3});
      expect(decodeWeekdays(null), isEmpty);
      expect(decodeWeekdays('0,8,x,7'), {7});
      expect(encodeWeekdays({3, 1}), '1,3');
    });
  });
}
