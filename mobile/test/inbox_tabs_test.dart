import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/inbox/logic/inbox_folders.dart';
import 'package:bpj/features/inbox/ui/inbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase2.dart';
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

/// The Inbox's smart views: All, Chats, Updates, Runs (D121).
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('each category lands in one view besides All', () {
    for (final c in [
      'club_updates',
      'run_reminders',
      'group_matches',
      'my_group_changes',
      'leaders_needed',
      'group_messages',
    ]) {
      final homes = [
        for (final f in InboxFolder.values)
          if (f != InboxFolder.all && f.holds(c)) f,
      ];
      expect(homes, hasLength(1), reason: c);
      expect(InboxFolder.all.holds(c), isTrue);
    }
  });

  final allKinds = [
    inboxJson('u1', category: 'club_updates'),
    inboxJson('r1', category: 'run_reminders'),
    inboxJson(
      'r2',
      category: 'my_group_changes',
      readAt: '2026-10-05T11:00:00.000Z',
    ),
    inboxJson('c1', category: 'group_messages'),
  ];

  Future<FakeAdapter> pumpInbox(
    WidgetTester tester, {
    List<Map<String, Object?>>? items,
  }) async {
    final adapter = await prepareMember(
      tester,
      db,
      routes: {
        'GET /app/clubs/1/notifications': FakeResponse(200, {
          'items': items ?? allKinds,
          'serverTime': '2026-10-07T12:00:00.000Z',
        }),
        'GET /app/clubs/1/threads': FakeResponse(200, threadsBody([])),
        'POST /app/clubs/1/notifications/read': const FakeResponse(204),
      },
    );
    await pumpGroupsApp(tester, db, adapter, const InboxScreen());
    return adapter;
  }

  Future<void> openTab(WidgetTester tester, InboxFolder f) async {
    await tester.tap(find.byKey(ValueKey('inbox-tab-${f.name}')));
    await tester.pumpAndSettle();
  }

  Finder tile(String id) => find.byKey(ValueKey('inbox-$id'));

  testWidgets('All shows everything; each tab filters', (tester) async {
    await pumpInbox(tester);
    for (final id in ['u1', 'r1', 'r2', 'c1']) {
      expect(tile(id), findsOneWidget, reason: id);
    }

    await openTab(tester, InboxFolder.updates);
    expect(tile('u1'), findsOneWidget);
    expect(tile('r1'), findsNothing);

    await openTab(tester, InboxFolder.runs);
    expect(tile('r1'), findsOneWidget);
    expect(tile('r2'), findsOneWidget);
    expect(tile('u1'), findsNothing);
    expect(tile('c1'), findsNothing);

    await openTab(tester, InboxFolder.chats);
    expect(tile('c1'), findsOneWidget);
    expect(tile('u1'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a dot marks only the tabs with something unread', (
    tester,
  ) async {
    // Only the run notification r2 exists, and it is read.
    await pumpInbox(tester, items: [allKinds[2], allKinds[0]]);
    bool dot(InboxFolder f) => tester
        .widget<Badge>(find.byKey(ValueKey('inbox-tab-dot-${f.name}')))
        .isLabelVisible;
    expect(dot(InboxFolder.all), isTrue); // u1 is unread
    expect(dot(InboxFolder.updates), isTrue);
    expect(dot(InboxFolder.runs), isFalse);
    expect(dot(InboxFolder.chats), isFalse);
    await unmount(tester);
  });

  testWidgets('Mark all read inside a tab only marks that tab', (tester) async {
    final adapter = await pumpInbox(tester);
    await openTab(tester, InboxFolder.runs);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    final posts = sent(adapter, 'POST', '/app/clubs/1/notifications/read');
    expect(posts, hasLength(1));
    expect(posts.single.data, {
      'ids': ['r1'],
    });
    await unmount(tester);
  });

  testWidgets('a tab with nothing in it says so', (tester) async {
    await pumpInbox(tester, items: [allKinds[0]]);
    await openTab(tester, InboxFolder.runs);
    expect(find.text(InboxFolder.runs.emptyText), findsOneWidget);
    await unmount(tester);
  });
}
