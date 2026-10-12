import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

/// The "Group chat" button on group cards: who sees it, the unread dot and
/// where it goes.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  // Two groups: `g1` is led by `lead`; `g2` has no leader.
  final groups = [
    groupJson(
      'g1',
      label: 'Tempo',
      leaders: [leaderJson('lead')],
      paceFromS: 540,
      paceToS: null,
      paceFromSPerKm: 336,
      paceToSPerKm: null,
    ),
    groupJson('g2', label: 'Steady'),
  ];

  Future<void> pumpDetail(
    WidgetTester tester, {
    List<String> roles = const [],
    String memberId = 'me',
    String? coordinator,
    String? myStatus,
    String? myGroupId,
    int unreadG1 = 0,
    GoRouter? router,
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      memberId: memberId,
    );
    await tester.runAsync(() async {
      await seedSession(
        db,
        'a',
        groups: groups,
        summary: summaryJson(
          groupCount: 2,
          myStatus: myStatus,
          myGroupId: myGroupId,
        ),
        coordinatorMemberId: coordinator,
      );
      if (unreadG1 > 0) await seedThread(db, 'g1', unreadCount: unreadG1);
    });
    if (router != null) {
      await pumpGroupsRouter(tester, db, adapter, router);
    } else {
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const SessionDetailScreen(sessionId: 'a'),
      );
    }
  }

  Finder chatButtons() => find.text('Group chat');

  testWidgets('a member who is not in a group has no chat button', (
    tester,
  ) async {
    await pumpDetail(tester);
    expect(chatButtons(), findsNothing);
    await unmount(tester);
  });

  testWidgets('having the leader role is not enough', (tester) async {
    await pumpDetail(tester, roles: const ['leader']);
    expect(chatButtons(), findsNothing);
    await unmount(tester);
  });

  testWidgets('"not coming" hides it even with a remembered group', (
    tester,
  ) async {
    await pumpDetail(tester, myStatus: 'not_going', myGroupId: 'g1');
    expect(chatButtons(), findsNothing);
    await unmount(tester);
  });

  testWidgets('a member in a group sees the button on that group only', (
    tester,
  ) async {
    await pumpDetail(tester, myStatus: 'going', myGroupId: 'g2');
    expect(chatButtons(), findsOneWidget);
    // It is on the Steady card (g2), not the Tempo card.
    final button = tester.getTopLeft(chatButtons()).dy;
    expect(button, greaterThan(tester.getTopLeft(find.text('Steady')).dy));
    await unmount(tester);
  });

  testWidgets('a leader of the group sees it on their group only', (
    tester,
  ) async {
    await pumpDetail(tester, memberId: 'lead', roles: const ['leader']);
    expect(chatButtons(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the run coordinator sees it on every group', (tester) async {
    await pumpDetail(tester, coordinator: 'me');
    expect(chatButtons(), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('committee and admin see it on every group', (tester) async {
    await pumpDetail(tester, roles: const ['committee']);
    expect(chatButtons(), findsNWidgets(2));
    await unmount(tester);
  });

  group('unread dot', () {
    bool dotShown(WidgetTester tester) => tester
        .widget<Badge>(find.byKey(const ValueKey('chat-unread')))
        .isLabelVisible;

    testWidgets('shows when the thread has unread messages', (tester) async {
      await pumpDetail(tester, myStatus: 'going', myGroupId: 'g1', unreadG1: 2);
      expect(dotShown(tester), isTrue);
      await unmount(tester);
    });

    testWidgets('is hidden when everything is read', (tester) async {
      await pumpDetail(tester, myStatus: 'going', myGroupId: 'g1');
      expect(dotShown(tester), isFalse);
      await unmount(tester);
    });
  });

  testWidgets('tapping the button opens the group chat route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SessionDetailScreen(sessionId: 'a'),
        ),
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
    await pumpDetail(
      tester,
      myStatus: 'going',
      myGroupId: 'g1',
      router: router,
    );
    await tester.tap(chatButtons());
    await settle(tester);
    expect(find.text('chat a g1'), findsOneWidget);
    await unmount(tester);
  });
}
