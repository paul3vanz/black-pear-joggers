import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
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

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  String day(int offset) =>
      localDateString(DateTime.now().add(Duration(days: offset)));

  Future<void> pumpRuns(
    WidgetTester tester, {
    required List<String> roles,
    required List<Map<String, Object?>> sessions,
  }) async {
    final adapter = FakeAdapter({
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
