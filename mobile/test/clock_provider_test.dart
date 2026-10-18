import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/util/clock.dart';
import 'package:bpj/core/util/relative_time.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/runs/ui/runs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';

/// D87: "today" and "N minutes ago" come from one clock provider that moves on
/// by itself (midnight timer, minute tick, app resume). The fake clock is a
/// variable the tests move; `tester.pump(duration)` runs the fake timers.
void main() {
  // Day D at noon, with a clock the tests can move.
  var clock = DateTime(2026, 10, 14, 12);
  setUp(() => clock = DateTime(2026, 10, 14, 12));

  ProviderScope scope(Widget child, {List<Override> more = const []}) =>
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => clock), ...more],
        child: MaterialApp(home: child),
      );

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  group('clubTodayProvider', () {
    Future<ProviderContainer> pumpContainer(WidgetTester tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        scope(
          Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return Text(ref.watch(clubTodayProvider).date);
            },
          ),
        ),
      );
      return container;
    }

    testWidgets('exposes the club-local date', (tester) async {
      await pumpContainer(tester);
      expect(find.text('2026-10-14'), findsOneWidget);
    });

    testWidgets('moves to the next day when the midnight timer fires', (
      tester,
    ) async {
      await pumpContainer(tester);

      // The phone clock passes midnight; the timer was armed for 12h + 1s.
      clock = DateTime(2026, 10, 15, 0, 0, 1);
      await tester.pump(const Duration(hours: 11, minutes: 59));
      expect(find.text('2026-10-14'), findsOneWidget, reason: 'not yet');
      await tester.pump(const Duration(minutes: 1, seconds: 2));
      expect(find.text('2026-10-15'), findsOneWidget);
    });

    testWidgets('re-arms for the following midnight', (tester) async {
      await pumpContainer(tester);
      clock = DateTime(2026, 10, 15, 0, 0, 1);
      await tester.pump(const Duration(hours: 12, seconds: 5));
      expect(find.text('2026-10-15'), findsOneWidget);

      clock = DateTime(2026, 10, 16, 0, 0, 1);
      await tester.pump(const Duration(hours: 24));
      expect(find.text('2026-10-16'), findsOneWidget);
    });

    testWidgets('an app resume recomputes without waiting for the timer', (
      tester,
    ) async {
      await pumpContainer(tester);
      // The device slept through midnight: no timer ran.
      clock = DateTime(2026, 10, 15, 7);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('2026-10-14'), findsOneWidget);

      await resume(tester);
      expect(find.text('2026-10-15'), findsOneWidget);
    });

    testWidgets('does not notify while the date is unchanged', (tester) async {
      var builds = 0;
      await tester.pumpWidget(
        scope(
          Consumer(
            builder: (context, ref, _) {
              builds++;
              ref.watch(clubTodayProvider);
              return const SizedBox();
            },
          ),
        ),
      );
      final before = builds;
      clock = DateTime(2026, 10, 14, 18);
      await resume(tester);
      expect(builds, before);
    });
  });

  group('nowProvider', () {
    Widget agoLabel(DateTime then) => Consumer(
      builder: (context, ref, _) =>
          Text(relativeTime(then, now: ref.watch(nowProvider))),
    );

    testWidgets('relative labels move on every minute', (tester) async {
      final then = clock;
      await tester.pumpWidget(scope(agoLabel(then)));
      expect(find.text('just now'), findsOneWidget);

      clock = then.add(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('5 minutes ago'), findsOneWidget);
    });

    testWidgets('and on resume', (tester) async {
      final then = clock;
      await tester.pumpWidget(scope(agoLabel(then)));

      clock = then.add(const Duration(hours: 3));
      await resume(tester);
      expect(find.text('3 hours ago'), findsOneWidget);
    });
  });

  group('Runs list', () {
    late AppDatabase db;
    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    }

    Future<void> pumpRuns(WidgetTester tester) async {
      final adapter = FakeAdapter({
        'POST /app/clubs/1/link': FakeResponse(200, membershipJson()),
        'GET /app/clubs/1/sessions': FakeResponse(200, {
          'items': [
            sessionJson('a', localDate: '2026-10-14', title: 'Wednesday run'),
            sessionJson('b', localDate: '2026-10-15', title: 'Thursday run'),
          ],
          'serverTime': '2026-10-14T12:00:00.000Z',
        }),
        'GET /app/clubs/1/venues': FakeResponse(200, {
          'items': [venueJson('v1', name: 'OECC')],
          'serverTime': '2026-10-14T12:00:00.000Z',
        }),
        'GET /app/clubs/1/series': FakeResponse(200, {
          'items': [seriesJson('s1')],
          'serverTime': '2026-10-14T12:00:00.000Z',
        }),
      });
      final dio = fakeDio(adapter);
      await tester.runAsync(
        () => MembershipRepository(
          db,
          dio,
        ).link(1, urn: 1, dob: DateTime(1990, 1, 1)),
      );
      await tester.pumpWidget(
        scope(
          const RunsScreen(),
          more: [
            membershipRepositoryProvider.overrideWithValue(
              MembershipRepository(db, dio),
            ),
            // The repository's own clock only prunes very old rows.
            runsRepositoryProvider.overrideWithValue(
              RunsRepository(db, dio, clock: () => clock),
            ),
            messagesRepositoryProvider.overrideWithValue(
              MessagesRepository(db, dio),
            ),
            runPreferencesRepositoryProvider.overrideWithValue(
              RunPreferencesRepository(db, dio),
            ),
            activeClubIdProvider.overrideWithValue(1),
            activeSubProvider.overrideWithValue('test|sub'),
          ],
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a run on day D shows "Today", then the next day moves on', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpRuns(tester);

      // Day D: Wednesday's run is today (header + badge), Thursday's tomorrow.
      expect(find.text('Wednesday run'), findsOneWidget);
      expect(find.text('Today'), findsNWidgets(2));
      expect(find.text('Tomorrow'), findsOneWidget);

      // Midnight passes while the app stays open.
      clock = DateTime(2026, 10, 15, 0, 0, 5);
      await tester.pump(const Duration(hours: 12, seconds: 1));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      // Yesterday's run has dropped out; Thursday's run is now today.
      expect(find.text('Wednesday run'), findsNothing);
      expect(find.text('Thursday run'), findsOneWidget);
      expect(find.text('Today'), findsNWidgets(2));
      expect(find.text('Tomorrow'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the same happens when the app resumes the next morning', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpRuns(tester);
      expect(find.text('Wednesday run'), findsOneWidget);

      clock = DateTime(2026, 10, 15, 8);
      await resume(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(find.text('Wednesday run'), findsNothing);
      expect(find.text('Thursday run'), findsOneWidget);
      expect(find.text('Today'), findsNWidgets(2));
      await unmount(tester);
    });
  });
}
