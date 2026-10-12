import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/inbox/ui/inbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

/// The "Group chats" section at the top of the Inbox tab.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Map<String, Object> routes(List<Map<String, Object?>> threads) => {
    'GET /app/clubs/1/notifications': const FakeResponse(200, {
      'items': <Object?>[],
      'serverTime': '2026-10-12T18:00:00.000Z',
    }),
    'GET /app/clubs/1/threads': FakeResponse(200, threadsBody(threads)),
  };

  Future<FakeAdapter> pumpInbox(
    WidgetTester tester,
    List<Map<String, Object?>> threads, {
    GoRouter? router,
  }) async {
    final adapter = await prepareMember(tester, db, routes: routes(threads));
    if (router != null) {
      await pumpGroupsRouter(tester, db, adapter, router);
    } else {
      await pumpGroupsApp(tester, db, adapter, const InboxScreen());
    }
    return adapter;
  }

  testWidgets('lists threads with label, run date, last message and badge', (
    tester,
  ) async {
    await pumpInbox(tester, [
      threadJson(
        'g1',
        label: '9:00-9:30/mi',
        localDate: '2026-10-07',
        lastAuthor: 'Sam B.',
        lastBody: 'Running 5 minutes late',
        unreadCount: 3,
      ),
      threadJson(
        'g2',
        sessionId: 's2',
        label: 'Jog and walk',
        localDate: '2026-10-05',
        lastAt: '2026-10-05T17:00:00.000Z',
        muted: true,
      ),
    ]);

    expect(find.text('Group chats'), findsOneWidget);
    expect(find.text('9:00-9:30/mi · Today'), findsOneWidget);
    expect(find.text('Sam B.: Running 5 minutes late'), findsOneWidget);
    // The unread badge is on the first thread only; the second is muted.
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    expect(find.text('Jog and walk · Mon 5 Oct'), findsOneWidget);
    // Newest message first.
    expect(
      tester.getTopLeft(find.text('9:00-9:30/mi · Today')).dy,
      lessThan(tester.getTopLeft(find.text('Jog and walk · Mon 5 Oct')).dy),
    );
    await unmount(tester);
  });

  testWidgets('has no section when there are no threads', (tester) async {
    await pumpInbox(tester, []);
    expect(find.text('Group chats'), findsNothing);
    await unmount(tester);
  });

  testWidgets('tapping a thread opens its chat route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
        GoRoute(
          path: '/runs/:id/groups/:groupId/chat',
          builder: (_, state) => Scaffold(
            body: Text(
              'chat ${state.pathParameters['id']} '
              '${state.pathParameters['groupId']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpInbox(tester, [
      threadJson('g1', sessionId: 's9'),
    ], router: router);

    await tester.tap(find.byKey(const ValueKey('thread-g1')));
    await settle(tester);
    expect(find.text('chat s9 g1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('opening the Inbox refreshes the threads', (tester) async {
    final adapter = await pumpInbox(tester, [threadJson('g1')]);
    expect(sent(adapter, 'GET', '/app/clubs/1/threads'), hasLength(1));
    await unmount(tester);
  });
}
