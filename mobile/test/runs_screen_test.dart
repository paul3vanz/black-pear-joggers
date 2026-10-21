import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/runs/data/follows_repository.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/runs/ui/runs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_follows.dart';
import 'support/fake_api_phase3.dart';
import 'support/fake_api_phase4.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  String day(int offset) =>
      localDateString(DateTime.now().add(Duration(days: offset)));

  late FakeAdapter adapter;
  late FakeFollowsServer follows;

  // [series] is what `GET /follows` returns (empty = no choices yet, so the
  // tab opens on All runs). The router gives the Runs I follow link a target.
  Future<void> pumpRuns(
    WidgetTester tester, {
    required List<String> roles,
    required List<Map<String, Object?>> sessions,
    List<Map<String, Object?>> series = const [],
  }) async {
    follows = FakeFollowsServer(series);
    adapter = FakeAdapter({
      ...follows.routes(() => adapter.requests.last.data),
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
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const RunsScreen()),
        GoRoute(
          path: '/follows',
          builder: (_, _) => const Scaffold(body: Text('Follows page')),
        ),
        GoRoute(
          path: '/runs/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Run ${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          runPreferencesRepositoryProvider.overrideWithValue(
            RunPreferencesRepository(db, dio),
          ),
          membershipRepositoryProvider.overrideWithValue(
            MembershipRepository(db, dio),
          ),
          runsRepositoryProvider.overrideWithValue(RunsRepository(db, dio)),
          messagesRepositoryProvider.overrideWithValue(
            MessagesRepository(db, dio),
          ),
          followsRepositoryProvider.overrideWithValue(
            FollowsRepository(db, dio),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
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

  testWidgets('shows group and going counts with your status chips', (
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
    // Going (leading counts, run a) on a, e and f.
    expect(find.text('Going'), findsNWidgets(3));
    expect(find.text("You're leading"), findsOneWidget);
    expect(find.text('1 group'), findsOneWidget);
    expect(find.text('Maybe'), findsOneWidget);
    expect(find.text("Can't come"), findsOneWidget);
    expect(find.text('Not following'), findsOneWidget);
    // A cancelled run keeps its badge and drops the summary.
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('2 groups · 4 going'), findsNothing);
    await unmount(tester);
  });

  group('My runs and All runs (D117)', () {
    // The member's feedback: The Mug Run (Thursday) on Follow, Thursday
    // Perdiswell on Hide, Monday club run on Auto (usually comes), a Saturday
    // run on Auto (rarely), and a one-off social.
    Map<String, Object?> run(
      String id,
      int offset,
      String? seriesId, {
      String? title,
      Map<String, Object?>? summary,
    }) => {
      ...sessionJson(
        id,
        localDate: day(offset),
        title: title ?? 'Run $id',
        seriesId: seriesId,
      ),
      'groups': <Object?>[],
      'summary': summary ?? summaryJson(),
    };
    List<Map<String, Object?>> feed() => [
      run('mug', 1, 'mug', title: 'The Mug Run'),
      run('perd', 1, 'perd', title: 'Thursday Perdiswell'),
      run('mon', 2, 'mon', title: 'Monday club run'),
      run('sat', 3, 'sat', title: 'Saturday long run'),
      run('social', 4, null, title: 'Social run'),
      run(
        'perdGoing',
        5,
        'perd',
        title: 'Perdiswell, going',
        summary: summaryJson(myStatus: 'going'),
      ),
    ];
    final series = [
      followJson('mon', usuallyComes: true),
      followJson('mug', title: 'The Mug Run', weekday: 4, mode: 'follow'),
      followJson(
        'perd',
        title: 'Thursday Perdiswell',
        weekday: 4,
        mode: 'hide',
      ),
      followJson('sat', title: 'Saturday long run', weekday: 6),
    ];

    testWidgets('My runs shows follows, usual runs, RSVPs and one-offs only', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);

      expect(find.text('Followed runs and your RSVPs'), findsOneWidget);
      expect(find.text('The Mug Run'), findsOneWidget);
      expect(find.text('Monday club run'), findsOneWidget); // auto, usual
      expect(find.text('Social run'), findsOneWidget); // one-off
      expect(find.text('Perdiswell, going'), findsOneWidget); // RSVP wins
      expect(find.text('Thursday Perdiswell'), findsNothing); // hidden
      expect(find.text('Saturday long run'), findsNothing); // auto, rarely
      expect(find.text('Following'), findsNWidgets(2));
      // Footer: the two runs All runs adds, both this week.
      expect(find.text('2 other runs this week'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('switching views is instant and saves nothing', (tester) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);
      final before = adapter.requests.length;

      await tester.tap(find.byKey(const ValueKey('view-all')));
      await tester.pump();
      expect(find.text('Thursday Perdiswell'), findsOneWidget);
      expect(find.text('Saturday long run'), findsOneWidget);
      expect(find.textContaining('Just looking'), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.text('Not following'), findsOneWidget);
      expect(find.text('Followed runs and your RSVPs'), findsNothing);
      expect(find.text('2 other runs this week'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('view-mine')));
      await tester.pump();
      expect(find.text('Thursday Perdiswell'), findsNothing);
      // No request at all, let alone a preference write.
      expect(adapter.requests.length, before);
      await unmount(tester);
    });

    testWidgets('the footer link switches to All runs', (tester) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);

      await tester.tap(find.byKey(const ValueKey('showAllRuns')));
      await tester.pump();
      expect(find.text('Saturday long run'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      await unmount(tester);
    });

    testWidgets('a hidden run in All runs is dimmed and offers Follow', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);
      await tester.tap(find.byKey(const ValueKey('view-all')));
      await tester.pump();

      Card cardOf(String title) => tester.widget<Card>(
        find.ancestor(of: find.text(title), matching: find.byType(Card)),
      );
      expect(cardOf('Thursday Perdiswell').color, isNotNull); // dimmed fill
      expect(cardOf('The Mug Run').color, isNull);
      expect(find.byKey(const ValueKey('follow-perd')), findsOneWidget);
      expect(find.byKey(const ValueKey('follow-sat')), findsOneWidget);
      expect(find.byKey(const ValueKey('manage-mug')), findsOneWidget);
      // RSVP'd runs and one-offs are managed, never followed.
      expect(find.byKey(const ValueKey('manage-perdGoing')), findsOneWidget);
      expect(find.byKey(const ValueKey('manage-social')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Follow on a card saves at once and updates it in place', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);
      await tester.tap(find.byKey(const ValueKey('view-all')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('follow-sat')));
      await settle(tester);

      expect(sent(adapter, 'PUT', '/app/clubs/1/follows/sat').single.data, {
        'mode': 'follow',
      });
      expect(find.byKey(const ValueKey('follow-sat')), findsNothing);
      expect(find.byKey(const ValueKey('manage-sat')), findsOneWidget);
      expect(find.text('Not following'), findsNothing);
      // Still on All runs.
      expect(find.textContaining('Just looking'), findsOneWidget);
      // And it is in My runs now.
      await tester.tap(find.byKey(const ValueKey('view-mine')));
      await tester.pump();
      expect(find.text('Saturday long run'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a failed Follow leaves the card as it was', (tester) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);
      await tester.tap(find.byKey(const ValueKey('view-all')));
      await tester.pump();
      follows.fail = true;

      await tester.tap(find.byKey(const ValueKey('follow-sat')));
      await settle(tester);

      expect(find.textContaining("Couldn't follow that run"), findsOneWidget);
      expect(find.byKey(const ValueKey('follow-sat')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('everything hidden but one: only that and RSVPs remain', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(
        tester,
        roles: [],
        sessions: [
          for (final r in feed())
            if (r['seriesId'] != null) r,
        ],
        series: [
          followJson('mon', usuallyComes: true, mode: 'hide'),
          followJson('mug', title: 'The Mug Run', weekday: 4, mode: 'follow'),
          followJson('perd', title: 'Perdiswell', weekday: 4, mode: 'hide'),
          followJson('sat', title: 'Saturday', weekday: 6, mode: 'hide'),
        ],
      );
      expect(find.text('The Mug Run'), findsOneWidget);
      expect(find.text('Perdiswell, going'), findsOneWidget);
      expect(find.text('Monday club run'), findsNothing);
      expect(find.text('Saturday long run'), findsNothing);
      expect(find.text('Thursday Perdiswell'), findsNothing);
      await unmount(tester);
    });

    testWidgets('zero follows: an empty My runs with a way out, no error', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(
        tester,
        roles: [],
        sessions: [run('sat', 3, 'sat', title: 'Saturday long run')],
        series: [
          followJson(
            'sat',
            title: 'Saturday long run',
            weekday: 6,
            mode: 'hide',
          ),
        ],
      );
      expect(find.text("You're not following any runs yet"), findsOneWidget);
      expect(find.text('Choose runs'), findsOneWidget);
      expect(find.text('Saturday long run'), findsNothing);

      await tester.tap(find.text('Show all runs').first);
      await tester.pump();
      expect(find.text('Saturday long run'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('with no choices yet it opens on All runs', (tester) async {
      tallSurface(tester);
      await pumpRuns(
        tester,
        roles: [],
        sessions: feed(),
        series: [
          for (final s in series) {...s, 'mode': 'auto'},
        ],
      );
      expect(find.textContaining('Just looking'), findsOneWidget);
      expect(find.text('Saturday long run'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Runs I follow link opens the settings screen', (tester) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);
      await tester.tap(find.byKey(const ValueKey('runsIFollowLink')));
      await tester.pumpAndSettle();
      expect(find.text('Follows page'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the view switch is 48dp and marks the selected side', (
      tester,
    ) async {
      tallSurface(tester);
      await pumpRuns(tester, roles: [], sessions: feed(), series: series);
      expect(
        tester.getSize(find.byKey(const ValueKey('view-mine'))).height,
        48,
      );
      Finder check(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byIcon(Icons.check),
      );
      expect(check('view-mine'), findsOneWidget);
      expect(check('view-all'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('manage-mug'))).height,
        greaterThanOrEqualTo(44),
      );
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
