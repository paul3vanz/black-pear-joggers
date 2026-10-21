import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/inbox/ui/inbox_screen.dart';
import 'package:bpj/features/messages/data/message_dtos.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/messages/ui/chat_screen.dart';
import 'package:bpj/features/updates/data/posts_repository.dart';
import 'package:bpj/features/updates/ui/post_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase2.dart';
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

/// Comments on a club update (D126): a Q&A thread under each post.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const base = '/app/clubs/1/posts/p1/comments';
  const thread = 'post:p1';

  List<Map<String, Object?>> conversation() => [
    messageJson(
      'c1',
      groupId: thread,
      memberId: 'abi',
      authorName: 'Abi L.',
      body: 'What time does the track open?',
      createdAt: '2026-10-07T10:00:00.000Z',
    ),
    messageJson(
      'c2',
      groupId: thread,
      memberId: 'cam',
      authorName: 'Cam C.',
      authorRole: 'committee',
      body: 'Seven o clock',
      createdAt: '2026-10-07T10:05:00.000Z',
    ),
  ];

  test('thread ids', () {
    expect(postThreadId('p1'), 'post:p1');
    expect(isPostThread('post:p1'), isTrue);
    expect(isPostThread('leaders:a'), isFalse);
    expect(isPostThread('g1'), isFalse);
    expect(postIdOfThread('post:p1'), 'p1');
  });

  group('repository', () {
    late FakeAdapter adapter;
    late MessagesRepository repo;

    setUp(() {
      adapter = FakeAdapter({
        'GET $base/messages': FakeResponse(200, messagesBody(conversation())),
        'POST $base/messages': FakeResponse(
          201,
          messageJson('new-1', groupId: thread, memberId: 'me', body: 'Hi'),
        ),
        'POST $base/messages/read': const FakeResponse(204),
        'PUT $base/thread': const FakeResponse(200, {
          'muted': true,
          'unreadCount': 0,
        }),
      });
      repo = MessagesRepository(db, fakeDio(adapter), newId: () => 'new-1');
    });

    test('reads, sends, marks read and mutes under the post', () async {
      await seedMembership(db);
      await repo.refresh(1, thread);
      await repo.send(1, thread, 'Hi');
      await repo.markRead(1, thread);
      await repo.setMuted(1, thread, true);

      expect((await repo.watchThread(thread).first).map((m) => m.id), [
        'c1',
        'c2',
        'new-1',
      ]);
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'GET $base/messages',
        'POST $base/messages',
        'POST $base/messages/read',
        'PUT $base/thread',
      ]);
    });

    test('closing patches the post, then refreshes the closed flag', () async {
      adapter.routes['PATCH /app/clubs/1/posts/p1'] = FakeResponse(
        200,
        postJson('p1'),
      );
      adapter.routes['GET $base/messages'] = FakeResponse(
        200,
        messagesBody(conversation(), closed: true),
      );

      await repo.setCommentsClosed(1, 'p1', closed: true);

      expect(adapter.requests.first.method, 'PATCH');
      expect(adapter.requests.first.data, {'commentsClosed': true});
      expect((await repo.watchThreadState(thread).first)!.closed, isTrue);
    });
  });

  group('comments screen', () {
    Future<FakeAdapter> pumpComments(
      WidgetTester tester, {
      List<String> roles = const [],
      bool closed = false,
      List<Map<String, Object?>>? items,
    }) async {
      final adapter = await prepareMember(
        tester,
        db,
        roles: roles,
        routes: {
          'GET $base/messages': FakeResponse(
            200,
            messagesBody(items ?? conversation(), closed: closed),
          ),
          'POST $base/messages/read': const FakeResponse(204),
          'PATCH /app/clubs/1/posts/p1': FakeResponse(200, postJson('p1')),
          'GET /app/clubs/1/posts': FakeResponse(200, {
            'items': [postJson('p1', title: 'Track night')],
            'serverTime': '2026-10-07T12:00:00.000Z',
          }),
        },
      );
      await tester.runAsync(
        () => PostsRepository(db, fakeDio(adapter)).refresh(1),
      );
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const ChatScreen(sessionId: '', groupId: thread),
      );
      return adapter;
    }

    testWidgets('titled Comments, with the update and a committee badge', (
      tester,
    ) async {
      await pumpComments(tester);

      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Track night'), findsOneWidget);
      expect(find.text('What time does the track open?'), findsOneWidget);
      expect(find.text('Seven o clock'), findsOneWidget);
      expect(find.text('Committee'), findsOneWidget); // the reply is badged
      expect(find.text('Ask a question or comment'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the committee replies, with its own hint', (tester) async {
      await pumpComments(tester, roles: ['committee']);
      expect(find.text('Reply to the comments'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('closed: a member can read but not write', (tester) async {
      await pumpComments(tester, closed: true);

      expect(find.text('Comments closed'), findsOneWidget);
      expect(
        find.textContaining('The committee has closed comments'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text('What time does the track open?'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('closed: the committee is told but can still reply', (
      tester,
    ) async {
      await pumpComments(tester, roles: ['committee'], closed: true);

      expect(
        find.byKey(const ValueKey('comments-closed-notice')),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('only the committee gets the close switch', (tester) async {
      await pumpComments(tester);
      await tester.tap(find.byTooltip('Chat options'));
      await tester.pumpAndSettle();
      expect(find.text('Mute notifications'), findsOneWidget);
      expect(find.text('Comments closed'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the committee can close comments from the menu', (
      tester,
    ) async {
      final adapter = await pumpComments(tester, roles: ['committee']);

      await tester.tap(find.byTooltip('Chat options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comments closed'));
      await tester.pumpAndSettle();

      final patch = adapter.requests.firstWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'commentsClosed': true});
      await unmount(tester);
    });
  });

  group('on the update', () {
    Future<void> pumpPost(
      WidgetTester tester, {
      List<String> roles = const [],
      List<Map<String, Object?>>? items,
      bool closed = false,
    }) async {
      final adapter = await prepareMember(
        tester,
        db,
        roles: roles,
        routes: {
          'GET $base/messages': FakeResponse(
            200,
            messagesBody(items ?? conversation(), closed: closed),
          ),
          'GET /app/clubs/1/posts': FakeResponse(200, {
            'items': [postJson('p1')],
            'serverTime': '2026-10-07T12:00:00.000Z',
          }),
          'POST /app/clubs/1/posts/receipts': const FakeResponse(204),
        },
      );
      await tester.runAsync(
        () => PostsRepository(db, fakeDio(adapter)).refresh(1),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const PostDetailScreen(postId: 'p1'),
          ),
          GoRoute(
            path: '/updates/:id/comments',
            builder: (_, state) => Scaffold(
              body: Text('comments of ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      await pumpGroupsRouter(tester, db, adapter, router);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    testWidgets('a Comments card counts them and opens the thread', (
      tester,
    ) async {
      await pumpPost(tester);

      expect(find.byKey(const ValueKey('commentsCard')), findsOneWidget);
      expect(find.text('2 comments'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('commentsCard')));
      await tester.pumpAndSettle();
      expect(find.text('comments of p1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no comments yet invites a question', (tester) async {
      await pumpPost(tester, items: const []);
      expect(find.text('Ask a question or leave a comment'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('closed with comments says so', (tester) async {
      await pumpPost(tester, closed: true);
      expect(find.text('2 comments · closed'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('closed and empty is hidden from members', (tester) async {
      await pumpPost(tester, items: const [], closed: true);
      expect(find.byKey(const ValueKey('commentsCard')), findsNothing);
      await unmount(tester);
    });

    testWidgets('closed and empty stays for the committee', (tester) async {
      await pumpPost(
        tester,
        roles: ['committee'],
        items: const [],
        closed: true,
      );
      expect(find.byKey(const ValueKey('commentsCard')), findsOneWidget);
      await unmount(tester);
    });
  });

  testWidgets('update threads are listed under Chats and open the comments', (
    tester,
  ) async {
    final adapter = await prepareMember(
      tester,
      db,
      routes: {
        'GET /app/clubs/1/notifications': const FakeResponse(200, {
          'items': <Object?>[],
          'serverTime': '2026-10-07T12:00:00.000Z',
        }),
        'GET /app/clubs/1/threads': FakeResponse(
          200,
          threadsBody([
            {
              ...threadJson(
                thread,
                label: 'Summer social',
                lastBody: 'Can I bring a friend?',
                unreadCount: 1,
              ),
              'sessionId': null,
              'kind': 'post',
            },
          ]),
        ),
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
        GoRoute(
          path: '/updates/:id/comments',
          builder: (_, state) =>
              Scaffold(body: Text('comments of ${state.pathParameters['id']}')),
        ),
      ],
    );
    await pumpGroupsRouter(tester, db, adapter, router);

    expect(find.textContaining('Summer social'), findsOneWidget);
    expect(find.textContaining('Can I bring a friend?'), findsOneWidget);
    await tester.tap(find.textContaining('Summer social'));
    await tester.pumpAndSettle();
    expect(find.text('comments of p1'), findsOneWidget);
    await unmount(tester);
  });
}
