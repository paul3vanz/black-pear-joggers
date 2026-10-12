import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/messages/ui/chat_screen.dart';
import 'package:bpj/features/messages/ui/messages_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart';
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const listKey = 'GET /app/clubs/1/groups/g1/messages';
  const postKey = 'POST /app/clubs/1/groups/g1/messages';
  const readKey = 'POST /app/clubs/1/groups/g1/messages/read';

  /// Messages for "yesterday" and "today" relative to [testNow] (2026-10-07).
  final conversation = [
    messageJson(
      'm1',
      memberId: 'sam',
      authorName: 'Sam B.',
      authorRole: 'leader',
      body: 'Meet at the back car park',
      createdAt: '2026-10-06T12:00:00.000Z',
    ),
    messageJson(
      'm2',
      memberId: 'me',
      authorName: 'Jo B.',
      body: 'On my way',
      createdAt: '2026-10-07T10:00:00.000Z',
    ),
    messageJson(
      'm3',
      memberId: 'pat',
      authorName: 'Pat C.',
      authorRole: 'committee',
      body: 'Route is the canal loop',
      createdAt: '2026-10-07T10:05:00.000Z',
    ),
    messageJson(
      'm4',
      memberId: 'alex',
      authorName: 'Alex D.',
      authorRole: 'coordinator',
      body: 'Bring a torch',
      createdAt: '2026-10-07T10:06:00.000Z',
    ),
    messageJson(
      'm5',
      memberId: 'kim',
      authorName: 'Kim E.',
      body: 'See you there',
      createdAt: '2026-10-07T10:07:00.000Z',
    ),
  ];

  /// Pumps the chat for group `g1` of session `a` as member `me`.
  Future<void> pumpChat(
    WidgetTester tester, {
    List<String> roles = const [],
    String? coordinator,
    bool leading = false,
    Map<String, Object> routes = const {},
    Widget Function(Widget chat)? wrap,
  }) async {
    adapter = await prepareMember(
      tester,
      db,
      roles: roles,
      routes: {
        listKey: FakeResponse(200, messagesBody(conversation)),
        readKey: const FakeResponse(204),
        ...routes,
      },
    );
    await tester.runAsync(
      () => seedSession(
        db,
        'a',
        groups: [
          groupJson(
            'g1',
            label: 'Tempo',
            leaders: [if (leading) leaderJson('me')],
          ),
        ],
        coordinatorMemberId: coordinator,
      ),
    );
    final dio = fakeDio(adapter);
    tallSurface(tester);
    const chat = ChatScreen(sessionId: 'a', groupId: 'g1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...groupsOverrides(db, dio),
          messagesRepositoryProvider.overrideWithValue(
            MessagesRepository(db, dio, newId: () => 'new-1'),
          ),
        ],
        child: MaterialApp(home: wrap == null ? chat : wrap(chat)),
      ),
    );
    await settle(tester);
  }

  /// A test that always unmounts the screen so its poll Timer is cancelled.
  void chatTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        await unmount(tester);
      });

  group('thread', () {
    chatTest('shows bubbles, names, role badges and day headings', (
      tester,
    ) async {
      await pumpChat(tester);

      expect(find.text('Meet at the back car park'), findsOneWidget);
      expect(find.text('Sam B.'), findsOneWidget);
      expect(find.text('Leader'), findsOneWidget);
      expect(find.text('Pat C.'), findsOneWidget);
      expect(find.text('Committee'), findsOneWidget);
      expect(find.text('Coordinator'), findsOneWidget);
      // A plain member has a name but no badge.
      expect(find.text('Kim E.'), findsOneWidget);
      // Own messages carry no author name.
      expect(find.text('Jo B.'), findsNothing);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Group chat'), findsOneWidget);
      expect(find.text('Tempo · Monday club run'), findsOneWidget);

      // Own bubble on the right, others on the left.
      final mine = tester.getCenter(find.text('On my way')).dx;
      final theirs = tester.getCenter(find.text('See you there')).dx;
      expect(mine, greaterThan(theirs));
    });

    chatTest('shows a deleted message as a tombstone', (tester) async {
      await pumpChat(
        tester,
        routes: {
          listKey: FakeResponse(
            200,
            messagesBody([
              messageJson(
                'm1',
                body: 'Oops',
                createdAt: '2026-10-07T10:00:00Z',
              ),
            ]),
          ),
        },
      );
      expect(find.text('Oops'), findsOneWidget);

      // The tombstone arrives through the since delta.
      adapter.routes[listKey] = FakeResponse(
        200,
        messagesBody([
          messageJson('m1', deletedAt: '2026-10-07T11:00:00.000Z'),
        ]),
      );
      await tester.pump(chatPollInterval);
      await settle(tester);
      expect(find.text('Message deleted'), findsOneWidget);
      expect(find.text('Oops'), findsNothing);
    });

    chatTest('marks the thread read when opened', (tester) async {
      await pumpChat(tester);
      expect(
        sent(adapter, 'POST', '/app/clubs/1/groups/g1/messages/read'),
        isNotEmpty,
      );
    });

    chatTest('marks it read again when a new message arrives while open', (
      tester,
    ) async {
      await pumpChat(tester);
      final before = sent(
        adapter,
        'POST',
        '/app/clubs/1/groups/g1/messages/read',
      ).length;

      adapter.routes[listKey] = FakeResponse(
        200,
        messagesBody([
          messageJson(
            'm9',
            memberId: 'sam',
            body: 'New one',
            createdAt: '2026-10-07T11:00:00.000Z',
          ),
        ]),
      );
      await tester.pump(chatPollInterval); // the poll Timer fires
      await settle(tester);

      expect(find.text('New one'), findsOneWidget);
      expect(
        sent(adapter, 'POST', '/app/clubs/1/groups/g1/messages/read').length,
        greaterThan(before),
      );
    });

    chatTest('polls every 8 seconds with the since cursor', (tester) async {
      await pumpChat(tester);
      final first = sent(adapter, 'GET', '/app/clubs/1/groups/g1/messages');
      expect(first, hasLength(1));
      expect(first.single.queryParameters, isEmpty);

      await tester.pump(chatPollInterval);
      await settle(tester);
      final second = sent(adapter, 'GET', '/app/clubs/1/groups/g1/messages');
      expect(second, hasLength(2));
      expect(second.last.queryParameters['since'], isNotNull);
    });

    chatTest('is registered as the open chat while shown', (tester) async {
      await pumpChat(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      expect(container.read(openChatGroupIdProvider), 'g1');
    });
  });

  group('info line', () {
    chatTest('is shown, dismissable and remembered', (tester) async {
      await pumpChat(tester);
      const text =
          'Everyone in this group can see your name. Committee can read '
          'group chats.';
      expect(find.text(text), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await settle(tester);
      expect(find.text(text), findsNothing);
      final dismissed = await tester.runAsync(
        () => MessagesRepository(db, fakeDio(adapter)).isInfoDismissed(),
      );
      expect(dismissed, isTrue);
    });
  });

  group('sending', () {
    chatTest('sends, clears the field and shows the message', (tester) async {
      await pumpChat(
        tester,
        routes: {
          postKey: FakeResponse(
            201,
            messageJson(
              'new-1',
              memberId: 'me',
              authorName: 'Jo B.',
              body: 'Running late',
              createdAt: '2026-10-07T11:00:00.000Z',
            ),
          ),
        },
      );
      await tester.enterText(find.byType(TextField), '  Running late ');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await settle(tester);

      final posts = sent(adapter, 'POST', '/app/clubs/1/groups/g1/messages');
      expect(posts.single.data, {'id': 'new-1', 'body': 'Running late'});
      expect(find.text('Running late'), findsOneWidget);
      expect(find.text('Sending...'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    chatTest('Send is disabled for an empty message', (tester) async {
      await pumpChat(tester);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
            .onPressed,
        isNull,
      );
    });

    chatTest('offline: the message shows as sending and the banner appears', (
      tester,
    ) async {
      await pumpChat(
        tester,
        routes: {
          // The messages endpoint is down, so the poll fails too.
          listKey: const FakeResponse(503, {'error': 'down'}),
        },
      );
      await tester.enterText(find.byType(TextField), 'Anyone there?');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await settle(tester);

      expect(find.text('Anyone there?'), findsOneWidget);
      expect(find.text('Sending...'), findsOneWidget);
      expect(find.textContaining('Offline'), findsOneWidget);
    });

    chatTest('shows the counter only near the 1000 character limit', (
      tester,
    ) async {
      await pumpChat(tester);
      await tester.enterText(find.byType(TextField), 'x' * 100);
      await tester.pump();
      expect(find.text('100/1000'), findsNothing);

      await tester.enterText(find.byType(TextField), 'x' * 950);
      await tester.pump();
      expect(find.text('950/1000'), findsOneWidget);
    });

    chatTest('a refused send is marked failed and keeps the text', (
      tester,
    ) async {
      await pumpChat(
        tester,
        routes: {
          postKey: const FakeResponse(409, {
            'error': 'thread_closed',
            'message': 'This run has finished.',
          }),
        },
      );
      await tester.enterText(find.byType(TextField), 'Too late');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await settle(tester);

      expect(find.text('Too late'), findsOneWidget);
      expect(find.text('Failed - tap to retry or delete'), findsOneWidget);
      expect(find.text('This run has finished.'), findsOneWidget); // snackbar
    });
  });

  group('closed thread', () {
    chatTest('shows "Chat closed" instead of the input', (tester) async {
      await pumpChat(
        tester,
        routes: {
          listKey: FakeResponse(200, messagesBody(conversation, closed: true)),
        },
      );
      expect(find.text('Chat closed'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('See you there'), findsOneWidget); // still readable
    });

    chatTest('has the input while open', (tester) async {
      await pumpChat(tester);
      expect(find.text('Chat closed'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('deleting', () {
    Future<void> longPress(WidgetTester tester, String text) async {
      await tester.longPress(find.text(text));
      await settle(tester);
    }

    Future<void> expectDeletable(
      WidgetTester tester,
      String text, {
      required bool deletable,
    }) async {
      await longPress(tester, text);
      expect(
        find.text('Delete this message?'),
        deletable ? findsOneWidget : findsNothing,
        reason: text,
      );
      if (deletable) {
        await tester.tap(find.text('Keep'));
        await settle(tester);
      }
    }

    chatTest('a member can delete only their own messages', (tester) async {
      await pumpChat(tester);
      await expectDeletable(tester, 'See you there', deletable: false);
      await expectDeletable(tester, 'On my way', deletable: true);
    });

    chatTest('own delete asks, tombstones and calls the API', (tester) async {
      await pumpChat(
        tester,
        routes: {
          'DELETE /app/clubs/1/groups/g1/messages/m2': const FakeResponse(204),
        },
      );
      await longPress(tester, 'On my way');
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(
        sent(adapter, 'DELETE', '/app/clubs/1/groups/g1/messages/m2'),
        hasLength(1),
      );
      expect(find.text('Message deleted'), findsOneWidget);
      expect(find.text('On my way'), findsNothing);
    });

    chatTest('a refused delete puts the message back', (tester) async {
      await pumpChat(
        tester,
        routes: {
          'DELETE /app/clubs/1/groups/g1/messages/m2': const FakeResponse(403, {
            'error': 'forbidden',
            'message': 'No',
          }),
        },
      );
      await longPress(tester, 'On my way');
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('On my way'), findsOneWidget);
      expect(find.text("You can't delete that message."), findsOneWidget);
    });

    chatTest('a leader of the group can delete others', (tester) async {
      await pumpChat(tester, leading: true);
      await expectDeletable(tester, 'See you there', deletable: true);
    });

    chatTest('the run coordinator can delete others', (tester) async {
      await pumpChat(tester, coordinator: 'me');
      await expectDeletable(tester, 'See you there', deletable: true);
    });

    chatTest('committee can delete others', (tester) async {
      await pumpChat(tester, roles: const ['committee']);
      await expectDeletable(tester, 'See you there', deletable: true);
    });

    chatTest('a leader of another group cannot', (tester) async {
      // Having the `leader` role is not enough: it must be THIS group.
      await pumpChat(tester, roles: const ['leader']);
      await expectDeletable(tester, 'See you there', deletable: false);
    });
  });

  group('unsent messages', () {
    chatTest('tapping a failed message offers Retry and Delete', (
      tester,
    ) async {
      await pumpChat(tester);
      await tester.runAsync(
        () => seedMessage(
          db,
          'f1',
          memberId: 'me',
          body: 'Never sent',
          sendState: 'failed',
          createdAt: DateTime.utc(2026, 10, 7, 11),
        ),
      );
      await settle(tester);
      expect(find.text('Failed - tap to retry or delete'), findsOneWidget);

      await tester.tap(find.text('Never sent'));
      await settle(tester);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Delete message'), findsOneWidget);

      await tester.tap(find.text('Delete message'));
      await settle(tester);
      expect(find.text('Never sent'), findsNothing);
    });

    chatTest('Retry re-sends the same message', (tester) async {
      await pumpChat(
        tester,
        routes: {
          postKey: FakeResponse(
            201,
            messageJson(
              'f1',
              memberId: 'me',
              body: 'Never sent',
              createdAt: '2026-10-07T11:00:00.000Z',
            ),
          ),
        },
      );
      await tester.runAsync(
        () => seedMessage(
          db,
          'f1',
          memberId: 'me',
          body: 'Never sent',
          sendState: 'failed',
          createdAt: DateTime.utc(2026, 10, 7, 11),
        ),
      );
      await settle(tester);

      await tester.tap(find.text('Never sent'));
      await settle(tester);
      await tester.tap(find.text('Retry'));
      await settle(tester);

      final posts = sent(adapter, 'POST', '/app/clubs/1/groups/g1/messages');
      expect((posts.single.data as Map)['id'], 'f1');
      expect(find.text('Failed - tap to retry or delete'), findsNothing);
    });

    chatTest('a sending message cannot be deleted', (tester) async {
      await pumpChat(tester);
      await tester.runAsync(
        () => seedMessage(
          db,
          'p1',
          memberId: 'me',
          body: 'On its way',
          sendState: 'pending',
          createdAt: DateTime.utc(2026, 10, 7, 11),
        ),
      );
      await settle(tester);
      await tester.longPress(find.text('On its way'));
      await settle(tester);
      expect(find.text('Delete this message?'), findsNothing);
    });
  });

  group('mute', () {
    chatTest('the menu switch mutes the thread', (tester) async {
      await pumpChat(
        tester,
        routes: {
          'PUT /app/clubs/1/groups/g1/thread': const FakeResponse(200, {
            'muted': true,
            'unreadCount': 0,
          }),
        },
      );
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);

      await tester.tap(find.byTooltip('Chat options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mute notifications'), warnIfMissed: false);
      await settle(tester);

      final puts = sent(adapter, 'PUT', '/app/clubs/1/groups/g1/thread');
      expect(puts.single.data, {'muted': true});
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    chatTest('a muted thread offers to unmute', (tester) async {
      await pumpChat(
        tester,
        routes: {
          listKey: FakeResponse(200, messagesBody(conversation, muted: true)),
          'PUT /app/clubs/1/groups/g1/thread': const FakeResponse(200, {
            'muted': false,
            'unreadCount': 0,
          }),
        },
      );
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      await tester.tap(find.byTooltip('Chat options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mute notifications'), warnIfMissed: false);
      await settle(tester);

      expect(
        sent(adapter, 'PUT', '/app/clubs/1/groups/g1/thread').single.data,
        {'muted': false},
      );
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
    });

    chatTest('offline: says so and stays unmuted', (tester) async {
      await pumpChat(tester);
      await tester.tap(find.byTooltip('Chat options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mute notifications'), warnIfMissed: false);
      await settle(tester);
      expect(
        find.text('You need a connection to change that.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
    });
  });

  group('access lost', () {
    chatTest('403 shows "no longer in this group" and goes back', (
      tester,
    ) async {
      await pumpChat(
        tester,
        routes: {
          listKey: const FakeResponse(403, {
            'error': 'not_in_group',
            'message': 'Not in this group',
          }),
        },
        // A page to come back to, like the session screen the chat is pushed on.
        wrap: (chat) => Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => chat)),
              child: const Text('Open chat'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open chat'));
      await settle(tester);

      // Popped back to the first page; the explanation is a SnackBar.
      expect(find.text('Open chat'), findsOneWidget);
      expect(find.byType(ChatScreen), findsNothing);
      expect(find.text("You're no longer in this group"), findsOneWidget);
    });

    chatTest('403 with nowhere to go back to fills the screen', (tester) async {
      await pumpChat(
        tester,
        routes: {
          listKey: const FakeResponse(403, {'error': 'not_in_group'}),
        },
      );
      expect(find.text("You're no longer in this group"), findsWidgets);
    });
  });
}
