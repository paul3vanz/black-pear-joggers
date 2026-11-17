import 'package:bpj/core/api/api_exception.dart';
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

    test('a jog/walk ask and the names an ask went to survive storage', () {
      final ask = decodeAskBody(
        encodeAskBody(
          const AskBody(
            jogWalk: true,
            askedNames: ['Anna H.', 'Ben C.'],
            note: 'a␞b',
          ),
        ),
      )!;
      expect(ask.jogWalk, isTrue);
      expect(ask.askedNames, ['Anna H.', 'Ben C.']);
      expect(ask.note, 'a␞b');
      expect(ask.hasPace, isFalse);
    });

    test('a named ask with a pace stretch round-trips', () {
      final ask = decodeAskBody(
        encodeAskBody(
          const AskBody(
            fastSPerKm: 354,
            slowSPerKm: 382,
            askedNames: ['Anna H.'],
          ),
        ),
      )!;
      expect((ask.fastSPerKm, ask.slowSPerKm), (354, 382));
      expect(ask.askedNames, ['Anna H.']);
      expect(ask.jogWalk, isFalse);
      expect(ask.note, '');
    });

    test('only an ask with a kind or names is written in the new form', () {
      expect(
        encodeAskBody(const AskBody(fastSPerKm: 1, slowSPerKm: 2, note: 'n')),
        startsWith('␞ask␞'),
      );
      expect(
        encodeAskBody(const AskBody(askedNames: ['A'])),
        startsWith('␞ask2␞'),
      );
      // Rows stored by the older app still read.
      final old = decodeAskBody('␞ask␞330␞360␞Thursday')!;
      expect(old.fastSPerKm, 330);
      expect(old.askedNames, isEmpty);
      expect(old.jogWalk, isFalse);
      expect(old.note, 'Thursday');
    });

    test('the server message carries kind and names', () {
      final dto = MessageDto.fromJson(
        messageJson(
          'm',
          kind: 'ask',
          askFast: 354,
          askSlow: 382,
          askedNames: ['Anna H.', 'Ben C.'],
        ),
      );
      expect(decodeAskBody(dto.storedBody)!.askedNames, ['Anna H.', 'Ben C.']);
      final walk = MessageDto.fromJson(
        messageJson(
          'm',
          kind: 'ask',
          askKind: 'jog_walk',
          askedNames: ['Cara'],
        ),
      );
      expect(decodeAskBody(walk.storedBody)!.jogWalk, isTrue);
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

    test('asking named people posts the stretch and who was asked', () async {
      adapter.routes['POST $base/ask'] = FakeResponse(201, {
        'message': messageJson(
          'new-1',
          groupId: thread,
          memberId: 'me',
          authorRole: 'committee',
          kind: 'ask',
          askFast: 354,
          askSlow: 382,
          askedNames: ['Anna H.'],
          body: 'Thursday',
        ),
        'notified': 1,
        'skipped': [
          {'memberId': 'ben', 'reason': 'leading'},
        ],
      });

      final result = await repo.askForLeader(
        1,
        'a',
        fastSPerKm: 354,
        slowSPerKm: 382,
        memberIds: ['anna', 'ben'],
        note: ' Thursday ',
      );

      expect(result.notified, 1);
      expect(result.skipped.single.memberId, 'ben');
      expect(result.skipped.single.reason, 'leading');
      expect(adapter.requests.single.data, {
        'id': 'new-1',
        'fastSPerKm': 354,
        'slowSPerKm': 382,
        'memberIds': ['anna', 'ben'],
        'note': 'Thursday',
      });
      final stored = (await repo.watchThread(thread).first).single.ask!;
      expect(stored.askedNames, ['Anna H.']);
    });

    test('a jog/walk ask sends the kind and no pace', () async {
      adapter.routes['POST $base/ask'] = FakeResponse(201, {
        'message': messageJson(
          'new-1',
          groupId: thread,
          kind: 'ask',
          askKind: 'jog_walk',
          askedNames: ['Cara'],
        ),
        'notified': 1,
      });

      final result = await repo.askForLeader(
        1,
        'a',
        fastSPerKm: 300,
        slowSPerKm: 350,
        memberIds: ['cara'],
        jogWalk: true,
      );

      expect(result.notified, 1);
      expect(result.skipped, isEmpty);
      expect(adapter.requests.single.data, {
        'id': 'new-1',
        'memberIds': ['cara'],
        'kind': 'jog_walk',
      });
      expect(
        (await repo.watchThread(thread).first).single.ask!.jogWalk,
        isTrue,
      );
    });

    test(
      'an ask for any pace and nobody in particular sends neither',
      () async {
        adapter.routes['POST $base/ask'] = FakeResponse(201, {
          'message': messageJson('new-1', groupId: thread, kind: 'ask'),
          'notified': 0,
        });
        expect((await repo.askForLeader(1, 'a')).notified, 0);
        expect(adapter.requests.single.data, {'id': 'new-1'});
      },
    );

    test(
      'reads the pool for a stretch, with how often and at what pace',
      () async {
        adapter.routes['GET $base/pool'] = FakeResponse(200, {
          'items': [
            poolJson(
              'anna',
              fitsRange: true,
              lastLed: const {
                'kind': 'run',
                'paceUnit': 'mi',
                'paceFromS': 540,
                'paceToS': 555,
              },
            ),
            poolJson(
              'cara',
              name: 'Cara D.',
              ledCount: 0,
              lastLedOn: null,
              lastLed: const {'kind': 'jog_walk'},
              leadingThisRun: true,
            ),
            poolJson(
              'dee',
              name: 'Dee E.',
              reason: 'chose_day',
              ledCount: 0,
              lastLedOn: null,
              lastLed: null,
              askedRecently: true,
            ),
          ],
        });

        final pool = await repo.leaderPool(
          1,
          'a',
          fastSPerKm: 354,
          slowSPerKm: 382,
        );

        expect(adapter.requests.single.queryParameters, {
          'fastSPerKm': 354,
          'slowSPerKm': 382,
        });
        expect(pool.map((m) => m.memberId), ['anna', 'cara', 'dee']);
        final anna = pool.first;
        expect(
          (anna.ledCount, anna.fitsRange, anna.canBeAsked),
          (3, true, true),
        );
        expect(anna.lastLedOn, DateTime.parse('2026-10-14'));
        expect(anna.lastLed!.pace.display(DistUnit.mi), '9:00-9:15/mi');
        expect(pool[1].lastLed!.isJogWalk, isTrue);
        expect(pool[1].blockedReason, 'Already leading');
        expect(pool[2].lastLed, isNull);
        expect(pool[2].blockedReason, 'Asked recently');
      },
    );

    test('the pool for a jog/walk group asks by kind', () async {
      adapter.routes['GET $base/pool'] = const FakeResponse(200, {
        'items': <Object?>[],
      });
      expect(await repo.leaderPool(1, 'a', jogWalk: true), isEmpty);
      expect(adapter.requests.single.queryParameters, {'kind': 'jog_walk'});
    });

    test('the pool says why it failed', () async {
      adapter.routes['GET $base/pool'] = const FakeResponse(403, {
        'error': 'forbidden',
        'message': 'Only the committee can see who could lead.',
      });
      await expectLater(
        repo.leaderPool(1, 'a'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
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
              body: Column(
                children: [
                  Text('new ${state.uri.queryParameters['intent']}'),
                  Text('query ${state.uri.query}'),
                ],
              ),
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

    testWidgets('the committee can ask people from inside the thread', (
      tester,
    ) async {
      final adapter = await pumpThread(tester, roles: const ['committee']);
      adapter.routes['GET $base/pool'] = FakeResponse(200, {
        'items': [poolJson('m1')],
      });
      adapter.routes['POST $base/ask'] = FakeResponse(201, {
        'message': messageJson(
          'ask-2',
          groupId: thread,
          memberId: 'me',
          authorRole: 'committee',
          kind: 'ask',
        ),
        'notified': 1,
        'skipped': <Object?>[],
      });

      await tester.tap(find.byKey(const ValueKey('ask-people')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ask for leaders'),
        findsOneWidget,
      ); // no stretch in mind
      await tester.tap(find.byKey(const ValueKey('pool-m1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();

      final data =
          adapter.requests.firstWhere((r) => r.path == '$base/ask').data!
              as Map;
      expect(data['memberIds'], ['m1']);
      expect(data.containsKey('fastSPerKm'), isFalse);
      expect(find.text('Asked 1 leader'), findsOneWidget);
      // Already in the thread, so it is not opened a second time.
      expect(find.byType(ChatScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a leader who is not committee has no Ask people button', (
      tester,
    ) async {
      await pumpThread(tester);
      expect(find.byKey(const ValueKey('ask-people')), findsNothing);
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

    testWidgets('an ask that named people shows who and the stretch in words', (
      tester,
    ) async {
      await pumpThread(
        tester,
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'cam',
            authorRole: 'committee',
            kind: 'ask',
            askFast: 354,
            askSlow: 382,
            askedNames: ['Anna H.', 'Ben C.'],
            body: 'Back to the usual?',
          ),
        ],
      );

      final title = tester.widget<Text>(
        find.byKey(const ValueKey('ask-title')),
      );
      expect(title.data, 'Can anyone lead a group between 9:30 and 10:15/mi?');
      expect(find.text('@Anna'), findsOneWidget);
      expect(find.text('@Ben'), findsOneWidget);
      expect(find.text('Back to the usual?'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('more than three names shows how many more', (tester) async {
      await pumpThread(
        tester,
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'cam',
            kind: 'ask',
            askFast: 354,
            askSlow: 382,
            askedNames: ['Anna H.', 'Ben C.', 'Cara D.', 'Dee E.', 'Eli F.'],
          ),
        ],
      );
      expect(find.text('@Anna'), findsOneWidget);
      expect(find.text('@Cara'), findsOneWidget);
      expect(find.text('@Dee'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('open ended asks read as faster than and slower than', (
      tester,
    ) async {
      await pumpThread(
        tester,
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'cam',
            kind: 'ask',
            askFast: 150,
            askSlow: 317,
            askedNames: ['Anna H.'],
          ),
          messageJson(
            'ask2',
            groupId: thread,
            memberId: 'cam',
            kind: 'ask',
            askFast: 429,
            askSlow: 900,
            askedNames: ['Ben C.'],
          ),
        ],
      );
      final titles = [
        for (final t in tester.widgetList<Text>(
          find.byKey(const ValueKey('ask-title')),
        ))
          t.data,
      ];
      expect(
        titles,
        containsAll([
          'Can anyone lead a group faster than 8:30/mi?',
          'Can anyone lead a group slower than 11:30/mi?',
        ]),
      );
      await unmount(tester);
    });

    testWidgets('a km viewer sees the stretch in km', (tester) async {
      await pumpThread(
        tester,
        paceUnit: DistUnit.km,
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'cam',
            kind: 'ask',
            askFast: 354,
            askSlow: 382,
            askedNames: ['Anna H.'],
          ),
        ],
      );
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('ask-title')),
      );
      expect(title.data, 'Can anyone lead a group between 5:55 and 6:20/km?');
      await unmount(tester);
    });

    testWidgets('a jog/walk ask says so, and I can lead carries the kind', (
      tester,
    ) async {
      await pumpThread(
        tester,
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'cam',
            kind: 'ask',
            askKind: 'jog_walk',
            askedNames: ['Cara D.'],
          ),
        ],
      );
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('ask-title')),
      );
      expect(title.data, 'Can anyone lead a jog/walk group?');

      await tester.tap(find.byKey(const ValueKey('ask-lead')));
      await tester.pumpAndSettle();
      expect(find.text('query intent=lead&kind=jog_walk'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('I can lead on a stretch carries it to the editor', (
      tester,
    ) async {
      await pumpThread(
        tester,
        messages: [
          messageJson(
            'ask1',
            groupId: thread,
            memberId: 'cam',
            kind: 'ask',
            askFast: 354,
            askSlow: 382,
            askedNames: ['Anna H.'],
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('ask-lead')));
      await tester.pumpAndSettle();
      expect(find.text('query intent=lead&fast=354&slow=382'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('an older ask keeps its plain wording and no chips', (
      tester,
    ) async {
      await pumpThread(tester);
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('ask-title')),
      );
      expect(title.data, startsWith('Can anyone lead '));
      expect(title.data, isNot(contains('a group')));
      expect(find.byKey(const ValueKey('ask-chips')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ask-lead')));
      await tester.pumpAndSettle();
      expect(find.text('query intent=lead&fast=336&slow=360'), findsOneWidget);
      await unmount(tester);
    });

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
          'GET $base/pool': FakeResponse(200, {
            'items': [
              poolJson('m1'),
              poolJson('m2', name: 'Ben C.', ledCount: 1),
            ],
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

    Map<Object?, Object?> askBody(FakeAdapter adapter) =>
        adapter.requests.firstWhere((r) => r.path == '$base/ask').data!
            as Map<Object?, Object?>;

    testWidgets('the committee can ask people about a gap, with a note', (
      tester,
    ) async {
      final adapter = await pumpDetail(tester);

      // 8:00 and 10:30 leave 8:30 to 10:00 uncovered (30 s/mi inside each edge).
      await tester.tap(find.byKey(const ValueKey('ask-gap-510')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ask for a group between 8:30 and 10:00/mi'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('pool-m1')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('ask-note')),
        'Thursday',
      );
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();

      final data = askBody(adapter);
      expect(data['note'], 'Thursday');
      expect(data['memberIds'], ['m1']); // only the person ticked
      // The stretch, in seconds per km: 8:30 to 10:00/mi.
      expect(data['fastSPerKm'], 317);
      expect(data['slowSPerKm'], 373);
      // Done: told how many, and the thread opens.
      expect(find.text('leaders thread page'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the open ends and jog/walk can be asked about too', (
      tester,
    ) async {
      final adapter = await pumpDetail(tester, groups: [led('a', 525)]);
      expect(find.text('Covered'), findsNothing);
      expect(find.byKey(const ValueKey('ask-faster-end')), findsOneWidget);
      expect(find.byKey(const ValueKey('ask-jog-walk')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ask-slower-end')));
      await tester.pumpAndSettle();
      expect(find.text('Ask for a group slower than 9:15/mi'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pool-m2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();

      final data = askBody(adapter);
      expect(data['memberIds'], ['m2']);
      expect(data['fastSPerKm'], 345); // 9:15/mi
      expect(data['slowSPerKm'], 900); // open ended
      await unmount(tester);
    });

    testWidgets('a jog/walk ask names no pace', (tester) async {
      final adapter = await pumpDetail(tester, groups: [led('a', 525)]);
      await tester.tap(find.byKey(const ValueKey('ask-jog-walk')));
      await tester.pumpAndSettle();
      expect(find.text('Ask for a jog/walk group'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pool-m1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();

      final data = askBody(adapter);
      expect(data['kind'], 'jog_walk');
      expect(data['memberIds'], ['m1']);
      expect(data.containsKey('fastSPerKm'), isFalse);
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
      await tester.tap(find.byKey(const ValueKey('pool-m1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('ask-send')));
      await tester.pumpAndSettle();
      final data = askBody(adapter);
      expect(data['memberIds'], ['m1']);
      expect(data['fastSPerKm'], lessThan(data['slowSPerKm'] as int));
      await unmount(tester);
    });

    testWidgets('a coordinator who is not committee cannot ask', (
      tester,
    ) async {
      await pumpDetail(tester, roles: const [], coordinator: 'me');
      expect(find.text('Group coverage'), findsOneWidget);
      expect(find.byKey(const ValueKey('ask-gap-510')), findsNothing);
      expect(
        find.text('Need groups between 8:30/mi and 10:00/mi'),
        findsOneWidget,
      );
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
      await tester.tap(find.byKey(const ValueKey('ask-gap-510')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pool-m1')));
      await tester.pump();
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
