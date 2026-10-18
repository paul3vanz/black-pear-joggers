import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/runs/ui/runs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase3.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

import 'package:bpj/features/runs/logic/my_days.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  String day(int offset) =>
      localDateString(DateTime.now().add(Duration(days: offset)));

  late FakeAdapter adapter;

  // [runDays] / [leadDays] are what `GET /preferences` returns; a PUT echoes
  // what was sent (and keeps the lead days, as the server would here).
  Future<void> pumpRuns(
    WidgetTester tester, {
    required List<String> roles,
    required List<Map<String, Object?>> sessions,
    List<int>? runDays,
    List<int>? leadDays,
  }) async {
    Map<String, Object?> prefs(List<int>? run) => {
      'paceUnit': 'mi',
      'distanceUnit': 'mi',
      'runDays': run,
      'leadDays': leadDays,
    };
    adapter = FakeAdapter({
      'GET /app/clubs/1/preferences': FakeResponse(200, prefs(runDays)),
      'PUT /app/clubs/1/preferences': () => FakeResponse(
        200,
        prefs(
          ((adapter.requests.last.data as Map)['runDays'] as List?)
              ?.cast<int>(),
        ),
      ),
      'POST /app/clubs/1/link': FakeResponse(200, membershipJson(roles: roles)),
      'GET /app/clubs/1/sessions': FakeResponse(200, {
        'items': sessions,
        'serverTime': '2026-10-07T12:00:00.000Z',
      }),
      'GET /app/clubs/1/venues': FakeResponse(200, {
        'items': [
          venueJson('v1', name: 'OECC'),
          venueJson('v2', name: 'Perdiswell'),
        ],
        'serverTime': '2026-10-07T12:00:00.000Z',
      }),
      'GET /app/clubs/1/series': FakeResponse(200, {
        'items': [seriesJson('s1')],
        'serverTime': '2026-10-07T12:00:00.000Z',
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
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(
            MembershipRepository(db, dio),
          ),
          runsRepositoryProvider.overrideWithValue(RunsRepository(db, dio)),
          messagesRepositoryProvider.overrideWithValue(
            MessagesRepository(db, dio),
          ),
          runPreferencesRepositoryProvider.overrideWithValue(
            RunPreferencesRepository(db, dio),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
        ],
        child: const MaterialApp(home: RunsScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  // Works around Drift's stream-cleanup timer outliving the test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  final sessions = [
    sessionJson('a', localDate: day(0), title: 'Club run today'),
    sessionJson(
      'b',
      localDate: day(1),
      title: 'Track night',
      status: 'cancelled',
      cancelReason: 'Track closed',
      groupMode: 'single',
    ),
    sessionJson(
      'c',
      localDate: day(3),
      title: 'Thursday run',
      start: '18:30',
      venueId: 'v2',
      original: {
        'localStartTime': '19:00',
        'venueId': 'v1',
        'title': 'Thursday run',
      },
    ),
  ];

  testWidgets('groups runs by day with cancelled and changed badges', (
    tester,
  ) async {
    tallSurface(tester);
    await pumpRuns(tester, roles: [], sessions: sessions);

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Club run today'), findsOneWidget);
    // Header "Today" plus the Today badge on the row.
    expect(find.text('Today'), findsNWidgets(2));
    expect(find.text('Track night'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Track closed'), findsOneWidget);
    expect(find.text('Changed'), findsOneWidget);
    expect(find.text('Moved from OECC'), findsOneWidget);
    expect(find.text('Starts at 6:30pm (usually 7pm)'), findsOneWidget);
    expect(find.text('Perdiswell'), findsOneWidget);
    expect(find.text('Coached session'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Track night'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
    await unmount(tester);
  });

  testWidgets('shows group and going counts with your response chips', (
    tester,
  ) async {
    tallSurface(tester);
    Map<String, Object?> run(
      String id,
      int offset,
      Map<String, Object?> summary, {
      String status = 'scheduled',
    }) => {
      ...sessionJson(
        id,
        localDate: day(offset),
        title: 'Run $id',
        status: status,
      ),
      'groups': <Object?>[],
      'summary': summary,
    };
    await pumpRuns(
      tester,
      roles: [],
      sessions: [
        run(
          'a',
          1,
          summaryJson(
            groupCount: 3,
            goingCount: 12,
            myStatus: 'going',
            myLeading: true,
          ),
        ),
        run(
          'b',
          2,
          summaryJson(groupCount: 1, goingCount: 0, myStatus: 'maybe'),
        ),
        run('c', 3, summaryJson(myStatus: 'not_going')),
        run('d', 4, summaryJson()),
        run(
          'e',
          5,
          summaryJson(groupCount: 2, goingCount: 4, myStatus: 'going'),
          status: 'cancelled',
        ),
        run(
          'f',
          6,
          summaryJson(groupCount: 1, goingCount: 2, myStatus: 'going'),
        ),
      ],
    );

    expect(find.text('3 groups · 12 going'), findsOneWidget);
    // Only the member's run (f) shows "You're going": on run a the viewer is
    // leading, which implies going, so the chip is hidden.
    expect(find.text("You're going"), findsOneWidget);
    expect(find.text("You're leading"), findsOneWidget);
    expect(find.text('1 group'), findsOneWidget);
    expect(find.text('Maybe'), findsOneWidget);
    expect(find.text("Can't come"), findsOneWidget);
    // A cancelled run keeps its badge and drops the summary.
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('2 groups · 4 going'), findsNothing);
    await unmount(tester);
  });

  group('days I run (D115)', () {
    // One run on each of the next seven days, so every weekday occurs once.
    // Run 1 has my "going", run 2 my "maybe", run 3 has me leading, run 4 my
    // "can't come".
    List<Map<String, Object?>> week() => [
      for (var i = 1; i <= 7; i++)
        {
          ...sessionJson('r$i', localDate: day(i), title: 'Run $i'),
          'groups': <Object?>[],
          'summary': switch (i) {
            1 => summaryJson(myStatus: 'going'),
            2 => summaryJson(myStatus: 'maybe'),
            3 => summaryJson(myLeading: true),
            4 => summaryJson(myStatus: 'not_going'),
            _ => summaryJson(),
          },
        },
    ];
    int weekday(int offset) =>
        DateTime.now().add(Duration(days: offset)).weekday;
    String short(int offset) => weekdayShort[weekday(offset) - 1];

    testWidgets('no choice: every day, with a quiet Choose days', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: week());
      expect(find.text('Showing every day'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
      for (var i = 1; i <= 7; i++) {
        expect(find.text('Run $i'), findsOneWidget);
      }
      await unmount(tester);
    });

    testWidgets('run days hide other days but keep runs I answered or lead', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(
        tester,
        roles: [],
        sessions: week(),
        runDays: [weekday(5)],
      );
      expect(find.text('Run days: ${short(5)}'), findsOneWidget);
      expect(find.text('Run 5'), findsOneWidget);
      expect(find.text('Run 1'), findsOneWidget); // going
      expect(find.text('Run 2'), findsOneWidget); // maybe
      expect(find.text('Run 3'), findsOneWidget); // leading
      expect(find.text('Run 4'), findsNothing); // can't come
      expect(find.text('Run 6'), findsNothing);
      expect(find.text('Run 7'), findsNothing);

      await tester.tap(find.text('Show 3 more'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 7; i++) {
        expect(find.text('Run $i'), findsOneWidget);
      }
      await tester.tap(find.text('Just my days'));
      await tester.pumpAndSettle();
      expect(find.text('Run 6'), findsNothing);
      expect(sent(adapter, 'PUT', '/app/clubs/1/preferences'), isEmpty);
      await unmount(tester);
    });

    testWidgets('a lead day also shows on the Runs tab', (tester) async {
      tallSurface(tester);
      await pumpRuns(
        tester,
        roles: [],
        sessions: week(),
        runDays: [weekday(5)],
        leadDays: [weekday(6)],
      );
      expect(find.text('Run 6'), findsOneWidget);
      expect(find.text('Run 7'), findsNothing);
      await unmount(tester);
    });

    testWidgets('Choose days saves runDays; Show every day clears them', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: week());
      await tester.tap(find.text('Choose days'));
      await tester.pumpAndSettle();
      expect(find.text('Which days do you usually run?'), findsOneWidget);
      // Nothing ticked: a run day needs at least one day.
      final save = find.byKey(const ValueKey('runDaysSave'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.tap(find.widgetWithText(FilterChip, short(6)));
      await tester.pump();
      await tester.tap(save);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(sent(adapter, 'PUT', '/app/clubs/1/preferences').single.data, {
        'runDays': [weekday(6)],
      });
      expect(find.text('Run days: ${short(6)}'), findsOneWidget);
      expect(find.text('Run 7'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('runDaysChange')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('runDaysEveryDay')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(sent(adapter, 'PUT', '/app/clubs/1/preferences').last.data, {
        'runDays': null,
      });
      expect(find.text('Showing every day'), findsOneWidget);
      expect(find.text('Run 7'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('dropping a lead day warns that leading stops too', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(
        tester,
        roles: [],
        sessions: week(),
        runDays: [weekday(5), weekday(6)],
        leadDays: [weekday(6)],
      );
      await tester.tap(find.byKey(const ValueKey('runDaysChange')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, short(6)));
      await tester.pump();
      expect(
        find.text("You'll stop being asked to lead on ${short(6)}."),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('a single weekday and no choice shows no panel', (
      tester,
    ) async {
      await pumpRuns(
        tester,
        roles: [],
        sessions: [sessionJson('a', localDate: day(1), title: 'Only run')],
      );
      expect(find.byKey(const ValueKey('runDaysPanel')), findsNothing);
      await unmount(tester);
    });
  });

  testWidgets('shows an empty state with no upcoming runs', (tester) async {
    await pumpRuns(tester, roles: [], sessions: []);
    expect(find.text('No upcoming runs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the manage button shows for committee, not plain members', (
    tester,
  ) async {
    await pumpRuns(tester, roles: ['committee'], sessions: sessions);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await unmount(tester);

    await db.clearAll();
    await pumpRuns(tester, roles: ['leader'], sessions: sessions);
    expect(find.text('Club run today'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await unmount(tester);
  });
}
