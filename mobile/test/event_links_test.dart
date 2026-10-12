import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/ui/group_actions.dart';
import 'package:bpj/features/groups/ui/group_editor_screen.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/messages/ui/chat_screen.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase6.dart';
import 'support/fake_api_phase8.dart';
import 'support/groups_test_support.dart';

/// Phase 8c, step 4 and 5: the pace group editor never opens for event runs,
/// and a reminder (`/runs/:id`) or a chat push (`/runs/:id/groups/:gid/chat`)
/// lands on working screens for `events` and `race` runs.
void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  final worcester = eventGroupJson(
    'g1',
    label: 'Worcester parkrun',
    locationId: 'l-worcester',
    goingCount: 2,
    createdByMemberId: 'me',
  );

  Future<FakeAdapter> seed(WidgetTester tester, String mode) async {
    final adapter = await prepareMember(
      tester,
      db,
      routes: {
        'GET /app/clubs/1/groups/g1/messages': FakeResponse(
          200,
          messagesBody([
            messageJson('m1', authorName: 'Sam B.', body: 'Lift from 8?'),
          ]),
        ),
        'POST /app/clubs/1/groups/g1/messages/read': const FakeResponse(204),
      },
    );
    await tester.runAsync(() async {
      await seedUnits(db);
      await seedSession(
        db,
        'a',
        groupMode: mode,
        groups: [worcester],
        summary: summaryJson(
          groupCount: 1,
          goingCount: 2,
          myStatus: 'going',
          myGroupId: 'g1',
        ),
      );
    });
    return adapter;
  }

  // The same shape as the real router: the run page with the chat nested.
  GoRouter routerAt(String location) => GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/runs/:id',
        builder: (_, s) =>
            SessionDetailScreen(sessionId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'groups/:groupId/chat',
            builder: (_, s) => ChatScreen(
              sessionId: s.pathParameters['id']!,
              groupId: s.pathParameters['groupId']!,
            ),
          ),
        ],
      ),
    ],
  );

  Future<void> pumpRouter(
    WidgetTester tester,
    FakeAdapter adapter,
    GoRouter router,
  ) async {
    tallSurface(tester);
    final dio = fakeDio(adapter);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, dio),
          messagesRepositoryProvider.overrideWithValue(
            MessagesRepository(db, dio, newId: () => 'new-1'),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  for (final mode in ['events', 'race']) {
    testWidgets('a reminder tap on a $mode run opens its page', (tester) async {
      final adapter = await seed(tester, mode);
      final router = routerAt('/runs/a');
      addTearDown(router.dispose);
      await pumpRouter(tester, adapter, router);
      expect(find.text('Monday club run'), findsOneWidget);
      expect(
        find.text(mode == 'events' ? 'Where are you running?' : "Who's going?"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('a chat push for a $mode run opens the event chat', (
      tester,
    ) async {
      final adapter = await seed(tester, mode);
      final router = routerAt('/runs/a/groups/g1/chat');
      addTearDown(router.dispose);
      await pumpRouter(tester, adapter, router);
      expect(find.text('Lift from 8?'), findsOneWidget);
      // The label (the event), not a pace, then the run.
      expect(find.text('Worcester parkrun · Monday club run'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('the Chat button on the run page reaches the chat', (
    tester,
  ) async {
    final adapter = await seed(tester, 'events');
    final router = routerAt('/runs/a');
    addTearDown(router.dispose);
    await pumpRouter(tester, adapter, router);
    await tester.tap(find.text('Chat'));
    await settle(tester);
    expect(find.text('Lift from 8?'), findsOneWidget);
    await unmount(tester);
  });

  for (final mode in ['events', 'race']) {
    testWidgets('the group editor refuses a $mode run (new and edit)', (
      tester,
    ) async {
      final adapter = await seed(tester, mode);
      for (final editor in [
        const GroupEditorScreen(sessionId: 'a'),
        const GroupEditorScreen(sessionId: 'a', groupId: 'g1'),
      ]) {
        await pumpGroupsApp(tester, db, adapter, editor);
        expect(
          find.textContaining('Events have no pace groups'),
          findsOneWidget,
        );
        expect(find.byType(GroupForm), findsNothing);
        expect(find.text('Save'), findsNothing);
        await unmount(tester);
      }
    });
  }
  testWidgets('lead and step-down paths do nothing for an event group', (
    tester,
  ) async {
    final adapter = await seed(tester, 'events');
    late Session session;
    late Group group;
    await tester.runAsync(() async {
      session = await db.select(db.sessions).getSingle();
      group = decodeGroups(session.groupsJson).single;
    });
    tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: groupsOverrides(db, fakeDio(adapter)),
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Column(
              children: [
                TextButton(
                  onPressed: () =>
                      joinAsLeaderWithRole(context, ref, session, group),
                  child: const Text('lead'),
                ),
                TextButton(
                  onPressed: () => stepDownFrom(context, ref, session, group),
                  child: const Text('step'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('lead'));
    await tester.tap(find.text('step'));
    await settle(tester);
    expect(find.text('How will you help lead?'), findsNothing);
    expect(find.text('Step down?'), findsNothing);
    expect(adapter.requests.where((r) => r.path.contains('leaders')), isEmpty);
    await unmount(tester);
  });
}
