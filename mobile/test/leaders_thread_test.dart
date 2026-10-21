import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/messages/data/message_dtos.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/messages/ui/chat_screen.dart';
import 'package:bpj/features/runs/ui/session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase4.dart' hide seedMembership;
import 'support/fake_api_phase6.dart';
import 'support/groups_test_support.dart';

/// The leaders thread of a run (D125): committee, the run's leaders and people
/// asked to lead. The app addresses it as `leaders:<sessionId>`.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const base = '/app/clubs/1/sessions/a/leaders-chat';
  const thread = 'leaders:a';

  group('ask body', () {
    test('encodes and decodes pace and note', () {
      final body = encodeAskBody(
        const AskBody(fastSPerKm: 330, slowSPerKm: 360, note: 'Thursday'),
      );
      final ask = decodeAskBody(body)!;
      expect(
        (ask.fastSPerKm, ask.slowSPerKm, ask.note),
        (330, 360, 'Thursday'),
      );
      expect(ask.hasPace, isTrue);
    });

    test('an ask with no pace, and a plain message', () {
      final ask = decodeAskBody(encodeAskBody(const AskBody()))!;
      expect(ask.hasPace, isFalse);
      expect(ask.note, '');
      expect(decodeAskBody('I can lead 9:00'), isNull);
      expect(decodeAskBody('ask|330|360|x'), isNull);
    });

    test('a note may contain anything, including the separator', () {
      final ask = decodeAskBody(
        encodeAskBody(const AskBody(fastSPerKm: 1, slowSPerKm: 2, note: 'a␞b')),
      )!;
      expect(ask.note, 'a␞b');
    });

    test('the server message becomes an ask; a tombstone does not', () {
      final dto = MessageDto.fromJson(
        messageJson(
          'm',
          kind: 'ask',
          askFast: 330,
          askSlow: 360,
          body: 'Short of leaders',
        ),
      );
      expect(decodeAskBody(dto.storedBody)!.note, 'Short of leaders');
      final gone = MessageDto.fromJson(
        messageJson(
          'm',
          kind: 'ask',
          askFast: 330,
          askSlow: 360,
          deletedAt: '2026-10-12T18:00:00.000Z',
        ),
      );
      expect(gone.storedBody, '');
    });

    test('thread ids', () {
      expect(leadersThreadId('a'), 'leaders:a');
      expect(isLeadersThread('leaders:a'), isTrue);
      expect(isLeadersThread('g1'), isFalse);
      expect(leadersSessionId('leaders:a'), 'a');
    });
  });

  group('repository', () {
    late FakeAdapter adapter;
    late MessagesRepository repo;

    setUp(() {
      adapter = FakeAdapter({
        'GET $base/messages': FakeResponse(
          200,
          messagesBody([
            messageJson(
              'm1',
              groupId: thread,
              authorRole: 'committee',
              kind: 'ask',
              askFast: 330,
              askSlow: 360,
              body: 'Short on Thursday',
            ),
            messageJson('m2', groupId: thread, body: 'I can do 9:00'),
          ]),
        ),
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

    test('reads the session thread and keeps an ask as an ask', () async {
      await repo.refresh(1, thread);

      final rows = await repo.watchThread(thread).first;
      expect(rows.map((m) => m.id), ['m1', 'm2']);
      expect(rows.first.ask!.fastSPerKm, 330);
      expect(rows.first.ask!.note, 'Short on Thursday');
      expect(rows.last.ask, isNull);
      expect(adapter.requests.first.path, '$base/messages');
    });

    test('sends, marks read and mutes against the session thread', () async {
      await seedMembership(db);
      await repo.send(1, thread, 'Hi');
      await repo.markRead(1, thread);
      await repo.setMuted(1, thread, true);

      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST $base/messages',
        'POST $base/messages/read',
        'PUT $base/thread',
      ]);
    });

    test('asking posts the pace and note and returns who was asked', () async {
      adapter.routes['POST $base/ask'] = FakeResponse(201, {
        'message': messageJson(
          'new-1',
          groupId: thread,
          memberId: 'me',
          authorRole: 'committee',
          kind: 'ask',
          askFast: 330,
          askSlow: 360,
          body: 'Thursday',
        ),
        'notified': 3,
      });

      final n = await repo.askForLeader(
        1,
        'a',
        fastSPerKm: 330,
        slowSPerKm: 360,
        note: ' Thursday ',
      );

      expect(n, 3);
      expect(adapter.requests.single.data, {
        'id': 'new-1',
        'fastSPerKm': 330,
        'slowSPerKm': 360,
        'note': 'Thursday',
      });
      expect((await repo.watchThread(thread).first).single.ask, isNotNull);
    });

    test('an ask for any pace sends no pace', () async {
      adapter.routes['POST $base/ask'] = FakeResponse(201, {
        'message': messageJson('new-1', groupId: thread, kind: 'ask'),
        'notified': 0,
      });
      expect(await repo.askForLeader(1, 'a'), 0);
      expect(adapter.requests.single.data, {'id': 'new-1'});
    });
  });

  group('thread screen', () {
    Future<FakeAdapter> pumpThread(
      WidgetTester tester, {
      List<String> roles = const [],
      List<Map<String, Object?>>? messages,
      DistUnit paceUnit = DistUnit.mi,
    }) async {
      final adapter = await prepareMember(
        tester,
        db,
        roles: roles,
        routes: {
          'GET $base/messages': FakeResponse(
            200,
            messagesBody(
              messages ??
                  [
                    messageJson(
                      'ask1',
                      groupId: thread,
                      memberId: 'cam',
                      authorName: 'Cam C.',
                      authorRole: 'committee',
                      kind: 'ask',
                      askFast: 336,
                      askSlow: 360,
                      body: 'Thursday group is short',
                    ),
                    messageJson(
                      'm2',
                      groupId: thread,
                      memberId: 'lee',
                      authorName: 'Lee L.',
                      body: 'Can do the slower end',
                    ),
                  ],
            ),
          ),
          'POST $base/messages/read': const FakeResponse(204),
        },
      );
      await tester.runAsync(() async {
        await seedSession(db, 'a', groups: [groupJson('g1')]);
        await seedUnits(db, pace: paceUnit);
      });
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const ChatScreen(sessionId: 'a', groupId: thread),
          ),
          GoRoute(
            path: '/runs/:id/groups/new',
            builder: (_, state) => Scaffold(
              body: Text('new ${state.uri.queryParameters['intent']}'),
            ),
          ),
        ],
      );
      await pumpGroupsRouter(tester, db, adapter, router);
      return adapter;
    }

    testWidgets('titled Leaders, with the ask in the viewer\'s units', (
      tester,
    ) async {
      await pumpThread(tester);

      expect(find.text('Leaders'), findsOneWidget);
      expect(find.text('Monday club run'), findsOneWidget);
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('ask-title')),
      );
      expect(title.data, startsWith('Can anyone lead '));
      expect(title.data, contains('/mi'));
      expect(find.text('Thursday group is short'), findsOneWidget);
      expect(find.text('Message the leaders'), findsOneWidget);
      // The author's role badge shows, as in any chat.
      expect(find.text('Committee'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a km viewer sees km', (tester) async {
      await pumpThread(tester, paceUnit: DistUnit.km);
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('ask-title')),
      );
      expect(title.data, contains('/km'));
      await unmount(tester);
    });

    testWidgets(
      'someone else\'s ask offers I can lead, which opens the editor',
      (tester) async {
        await pumpThread(tester);

        await tester.tap(find.byKey(const ValueKey('ask-lead')));
        await tester.pumpAndSettle();
        expect(find.text('new lead'), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets('your own ask has no button', (tester) async {
      await pumpThread(
        tester,
        roles: ['committee'],
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'me',
            authorName: 'Me',
            authorRole: 'committee',
            kind: 'ask',
            askFast: 336,
            askSlow: 360,
          ),
        ],
      );
      expect(find.byKey(const ValueKey('ask-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('ask-lead')), findsNothing);
      await unmount(tester);
    });

    testWidgets('a closed thread offers no I can lead', (tester) async {
      final adapter = await prepareMember(
        tester,
        db,
        routes: {
          'GET $base/messages': FakeResponse(
            200,
            messagesBody([
              messageJson(
                'ask1',
                groupId: thread,
                memberId: 'cam',
                authorRole: 'committee',
                kind: 'ask',
                askFast: 336,
                askSlow: 360,
              ),
            ], closed: true),
          ),
          'POST $base/messages/read': const FakeResponse(204),
        },
      );
      await tester.runAsync(() => seedSession(db, 'a'));
      await pumpGroupsApp(
        tester,
        db,
        adapter,
        const ChatScreen(sessionId: 'a', groupId: thread),
      );
      expect(find.byKey(const ValueKey('ask-lead')), findsNothing);
      expect(find.text('Chat closed'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('coverage card', () {
    Map<String, Object?> led(String id, int from) => groupJson(
      id,
      paceUnit: 'mi',
      paceFromS: from,
      paceToS: null,
      paceFromSPerKm: null,
      paceToSPerKm: null,
      leaders: [leaderJson('l$id', name: 'Jo Bloggs')],
    );

    Future<FakeAdapter> pumpDetail(
      WidgetTester tester, {
      List<String> roles = const ['committee'],
      String? coordinator,
      List<Map<String, Object?>>? groups,
    }) async {
      final adapter = await prepareMember(
        tester,
        db,
        roles: roles,
        routes: {
          'POST $base/ask': FakeResponse(201, {
            'message': messageJson(
              'ask-1',
              groupId: thread,
              memberId: 'me',
              authorRole: 'committee',
              kind: 'ask',
              askFast: 500,
              askSlow: 600,
            ),
            'notified': 2,
          }),
          'GET $base/messages': FakeResponse(200, messagesBody([])),
          'POST $base/messages/read': const FakeResponse(204),
        },
      );
      final gs = groups ?? [led('a', 480), led('b', 630)];
      await tester.runAsync(
        () => seedSession(
          db,
          'a',
          groups: gs,
          summary: summaryJson(groupCount: gs.length),
          coordinatorMemberId: coordinator,
        ),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SessionDetailScreen(sessionId: 'a'),
          ),
          GoRoute(
            path: '/runs/:id/leaders-chat',
            builder: (_, state) =>
                const Scaffold(body: Text('leaders thread page')),
          ),
        ],
      );
      await pumpGroupsRouter(tester, db, adapter, router);
      return adapter;
    }

    testWidgets('the committee can ask about a gap, with a note', (
      tester,
    ) async {
      final adapter = await pumpDetail(tester);

      await tester.tap(find.text('Ask leaders'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ask the leaders who could lead'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('ask-note')),
        'Thursday',
      );
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();

      final post = adapter.requests.firstWhere((r) => r.path == '$base/ask');
      final data = post.data! as Map;
      expect(data['note'], 'Thursday');
      // The gap between the two groups, in seconds per km.
      expect(data['fastSPerKm'], lessThan(data['slowSPerKm'] as int));
      expect(data['fastSPerKm'], inInclusiveRange(300, 400));
      // Done: told how many, and the thread opens.
      expect(find.text('leaders thread page'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the window ends have no Ask leaders button', (tester) async {
      await pumpDetail(tester, groups: [led('a', 525)]);
      expect(find.text('Covered'), findsOneWidget);
      expect(find.text('Ask leaders'), findsNothing);
      await unmount(tester);
    });

    testWidgets('an unled group can be asked about by its pace', (
      tester,
    ) async {
      final adapter = await pumpDetail(
        tester,
        groups: [
          led('a', 540),
          groupJson('x', paceFromS: 660, paceToS: null, status: 'needs_leader'),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('ask-group-x')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();
      final data =
          adapter.requests.firstWhere((r) => r.path == '$base/ask').data!
              as Map;
      expect(data['fastSPerKm'], lessThan(data['slowSPerKm'] as int));
      await unmount(tester);
    });

    testWidgets('a coordinator who is not committee cannot ask', (
      tester,
    ) async {
      await pumpDetail(tester, roles: const [], coordinator: 'me');
      expect(find.text('Group coverage'), findsOneWidget);
      expect(find.text('Ask leaders'), findsNothing);
      expect(find.byKey(const ValueKey('open-leaders-chat')), findsNothing);
      await unmount(tester);
    });

    testWidgets('the committee can open the thread', (tester) async {
      await pumpDetail(tester);
      await tester.tap(find.byKey(const ValueKey('open-leaders-chat')));
      await tester.pumpAndSettle();
      expect(find.text('leaders thread page'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a failed ask says why and keeps the sheet open', (
      tester,
    ) async {
      final adapter = await pumpDetail(tester);
      adapter.routes['POST $base/ask'] = const FakeResponse(403, {
        'error': 'forbidden',
        'message': 'Only the committee can ask for leaders.',
      });
      await tester.tap(find.text('Ask leaders'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();
      expect(
        find.text('Only the committee can ask for leaders.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ask-send')), findsOneWidget);
      await unmount(tester);
    });
  });

  testWidgets('a leader of the run gets a Leaders thread link', (tester) async {
    final adapter = await prepareMember(tester, db);
    await tester.runAsync(
      () => seedSession(
        db,
        'a',
        groups: [
          groupJson('g1', leaders: [leaderJson('me')]),
        ],
        summary: summaryJson(groupCount: 1, myStatus: 'going', myLeading: true),
      ),
    );
    await pumpGroupsApp(
      tester,
      db,
      adapter,
      const SessionDetailScreen(sessionId: 'a'),
    );
    expect(find.byKey(const ValueKey('leaders-thread-link')), findsOneWidget);
    await unmount(tester);
  });
}
