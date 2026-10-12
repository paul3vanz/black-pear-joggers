import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/messages/data/message_dtos.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase6.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late MessagesRepository repo;
  late DateTime now;

  const listKey = 'GET /app/clubs/1/groups/g1/messages';
  const postKey = 'POST /app/clubs/1/groups/g1/messages';

  setUp(() async {
    db = memoryDb();
    now = DateTime.utc(2026, 10, 12, 18);
    await seedMembership(db);
  });
  tearDown(() => db.close());

  void setup(Map<String, Object> routes) {
    adapter = FakeAdapter(routes);
    repo = MessagesRepository(
      db,
      fakeDio(adapter),
      clock: () => now,
      newId: () => 'new-1',
    );
  }

  Future<List<GroupMessage>> rows() => (db.select(
    db.groupMessages,
  )..orderBy([(m) => OrderingTerm.asc(m.createdAt)])).get();

  group('refresh', () {
    test('stores messages, closed/muted and the since cursor', () async {
      setup({
        listKey: FakeResponse(
          200,
          messagesBody(
            [
              messageJson('m1', body: 'Hi'),
              messageJson(
                'm2',
                authorRole: 'leader',
                createdAt: '2026-10-12T17:31:00.000Z',
              ),
            ],
            closed: true,
            muted: true,
          ),
        ),
      });
      await repo.refresh(1, 'g1');

      final stored = await rows();
      expect(stored.map((m) => m.id), ['m1', 'm2']);
      expect(stored.last.authorRole, 'leader');
      expect(stored.every((m) => m.sendState == 'sent'), isTrue);
      final state = await db.select(db.threadStates).getSingle();
      expect(state.closed, isTrue);
      expect(state.muted, isTrue);
      expect(state.sessionId, isNull);
      expect(adapter.requests.single.queryParameters, isEmpty);

      // The next call asks only for what changed since the saved serverTime.
      await repo.refresh(1, 'g1');
      expect(
        adapter.requests.last.queryParameters['since'],
        '2026-10-12T18:00:00.000Z',
      );
      final cursor = await (db.select(
        db.syncCursors,
      )..where((c) => c.key.equals('messages:1:g1'))).getSingle();
      expect(cursor.serverTime, '2026-10-12T18:00:00.000Z');
    });

    test('merges updates and applies tombstones to known messages', () async {
      await seedMessage(db, 'm1', body: 'Original');
      await seedMessage(db, 'm2', body: 'Keep me');
      setup({
        listKey: FakeResponse(
          200,
          messagesBody([
            messageJson('m1', deletedAt: '2026-10-12T17:45:00.000Z'),
            // A tombstone for a message this device never had is dropped.
            messageJson('m9', deletedAt: '2026-10-12T17:46:00.000Z'),
            messageJson(
              'm3',
              body: 'New',
              createdAt: '2026-10-12T17:50:00.000Z',
            ),
          ]),
        ),
      });
      await repo.refresh(1, 'g1');

      final stored = {for (final m in await rows()) m.id: m};
      expect(stored.keys, containsAll(['m1', 'm2', 'm3']));
      expect(stored.containsKey('m9'), isFalse);
      expect(stored['m1']!.isDeleted, isTrue);
      expect(stored['m1']!.body, '');
      expect(stored['m2']!.body, 'Keep me');
    });

    test('a 403 drops the local copy and rethrows', () async {
      await seedMessage(db, 'm1');
      await seedThread(db, 'g1');
      setup({
        listKey: const FakeResponse(403, {
          'error': 'not_in_group',
          'message': 'no',
        }),
      });
      await expectLater(
        repo.refresh(1, 'g1'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'not_in_group'),
        ),
      );
      expect(await rows(), isEmpty);
      expect(await db.select(db.threadStates).get(), isEmpty);
    });
  });

  group('send', () {
    test(
      'inserts pending at once, then confirms with the server row',
      () async {
        setup({
          postKey: FakeResponse(
            201,
            messageJson(
              'new-1',
              memberId: 'me',
              authorName: 'Jo B.',
              body: 'Running late',
              createdAt: '2026-10-12T18:00:01.000Z',
            ),
          ),
        });
        final result = await repo.send(1, 'g1', '  Running late  ');
        expect(result.outcome, SendOutcome.sent);

        final sentBody = adapter.requests.single.data as Map;
        expect(sentBody, {'id': 'new-1', 'body': 'Running late'});
        final row = (await rows()).single;
        expect(row.id, 'new-1');
        expect(row.sendState, 'sent');
        expect(row.authorName, 'Jo B.');
        expect(row.createdAt.toUtc(), DateTime.utc(2026, 10, 12, 18, 0, 1));
      },
    );

    test('offline keeps it pending and the next refresh re-sends it', () async {
      setup({}); // every call is a connection error
      final result = await repo.send(1, 'g1', 'Anyone there?');
      expect(result.outcome, SendOutcome.queued);
      final row = (await rows()).single;
      expect(row.sendState, 'pending');
      expect(row.memberId, 'me');

      // Back online: refresh flushes the outbox first, then pulls.
      adapter = FakeAdapter({
        postKey: FakeResponse(200, messageJson('new-1', memberId: 'me')),
        listKey: FakeResponse(200, messagesBody([])),
      });
      repo = MessagesRepository(db, fakeDio(adapter), clock: () => now);
      await repo.refresh(1, 'g1');
      expect(adapter.requests.first.method, 'POST');
      expect((await rows()).single.sendState, 'sent');
    });

    test('a server error keeps it pending', () async {
      setup({
        postKey: const FakeResponse(503, {'error': 'down'}),
      });
      final result = await repo.send(1, 'g1', 'Hi');
      expect(result.outcome, SendOutcome.queued);
      expect((await rows()).single.sendState, 'pending');
    });

    test('403, 409 and 422 mark it failed', () async {
      for (final (status, code) in [
        (403, 'not_in_group'),
        (409, 'thread_closed'),
        (422, 'validation_failed'),
      ]) {
        await db.delete(db.groupMessages).go();
        setup({
          postKey: FakeResponse(status, {'error': code, 'message': 'x'}),
        });
        final result = await repo.send(1, 'g1', 'Hi');
        expect(result.outcome, SendOutcome.failed, reason: '$status');
        expect(result.error?.code, code);
        expect((await rows()).single.sendState, 'failed');
      }
    });

    test('429 stays pending and waits before the next try', () async {
      setup({
        postKey: const FakeResponse(429, {'error': 'too_many_requests'}),
      });
      final result = await repo.send(1, 'g1', 'Hi');
      expect(result.outcome, SendOutcome.queued);
      expect((await rows()).single.sendState, 'pending');
      expect(adapter.requests, hasLength(1));

      // Too soon: the flush leaves it alone.
      await repo.retryPending(1);
      expect(adapter.requests, hasLength(1));

      now = now.add(const Duration(seconds: 21));
      await repo.retryPending(1);
      expect(adapter.requests, hasLength(2));
    });

    test('rejects empty and over-long bodies', () async {
      setup({});
      expect(() => repo.send(1, 'g1', '   '), throwsArgumentError);
      expect(
        () => repo.send(1, 'g1', 'x' * (maxMessageLength + 1)),
        throwsArgumentError,
      );
    });
  });

  group('retry and discard', () {
    test('retry re-sends a failed message and can succeed', () async {
      await seedMessage(
        db,
        'f1',
        memberId: 'me',
        body: 'Try again',
        sendState: 'failed',
      );
      setup({postKey: FakeResponse(201, messageJson('f1', memberId: 'me'))});
      final result = await repo.retry('f1');
      expect(result.outcome, SendOutcome.sent);
      expect((await rows()).single.sendState, 'sent');
      expect((adapter.requests.single.data as Map)['id'], 'f1');
    });

    test('retry that is refused again goes back to failed', () async {
      await seedMessage(db, 'f1', memberId: 'me', sendState: 'failed');
      setup({
        postKey: const FakeResponse(409, {'error': 'thread_closed'}),
      });
      expect((await repo.retry('f1')).outcome, SendOutcome.failed);
      expect((await rows()).single.sendState, 'failed');
    });

    test('discard removes only failed messages', () async {
      await seedMessage(db, 'f1', sendState: 'failed');
      await seedMessage(db, 's1');
      setup({});
      await repo.discard('f1');
      await repo.discard('s1');
      expect((await rows()).map((m) => m.id), ['s1']);
    });
  });

  group('delete', () {
    const delKey = 'DELETE /app/clubs/1/groups/g1/messages/m1';

    test('shows a tombstone at once and keeps it on success', () async {
      await seedMessage(db, 'm1', body: 'Oops');
      setup({delKey: const FakeResponse(204)});
      await repo.delete('m1');
      final row = (await rows()).single;
      expect(row.isDeleted, isTrue);
      expect(row.body, '');
    });

    test('reverts when the server refuses', () async {
      await seedMessage(db, 'm1', body: 'Oops');
      setup({
        delKey: const FakeResponse(403, {
          'error': 'forbidden',
          'message': 'no',
        }),
      });
      await expectLater(repo.delete('m1'), throwsA(isA<ApiException>()));
      final row = (await rows()).single;
      expect(row.isDeleted, isFalse);
      expect(row.body, 'Oops');
    });

    test('reverts when offline', () async {
      await seedMessage(db, 'm1', body: 'Oops');
      setup({});
      await expectLater(
        repo.delete('m1'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'network', true),
        ),
      );
      expect((await rows()).single.body, 'Oops');
    });
  });

  group('threads, read state and mute', () {
    test('refreshThreads parses threads and drops vanished ones', () async {
      await seedMessage(db, 'old', groupId: 'gone');
      await seedThread(db, 'gone', sessionId: 's0');
      setup({
        'GET /app/clubs/1/threads': FakeResponse(
          200,
          threadsBody([
            threadJson('g1', unreadCount: 3, muted: true),
            threadJson(
              'g2',
              sessionId: 's2',
              lastAt: '2026-10-12T17:00:00.000Z',
              closed: true,
            ),
          ]),
        ),
      });
      await repo.refreshThreads(1);

      final threads = await repo.watchThreads(1).first;
      expect(threads.map((t) => t.groupId), ['g1', 'g2']); // newest first
      final g1 = threads.first;
      expect(g1.unreadCount, 3);
      expect(g1.muted, isTrue);
      expect(g1.label, '9:00-9:30/mi');
      expect(g1.sessionId, 's1');
      expect(g1.localDate, '2026-10-12');
      expect(g1.lastBody, 'See you there');
      expect(g1.lastAuthor, 'Sam B.');
      expect(threads.last.closed, isTrue);
      expect(await rows(), isEmpty); // the vanished thread's messages too
    });

    test('markRead zeroes the unread count and POSTs', () async {
      await seedThread(db, 'g1', unreadCount: 4);
      setup({
        'POST /app/clubs/1/groups/g1/messages/read': const FakeResponse(204),
      });
      expect(await repo.markRead(1, 'g1'), isTrue);
      expect((await db.select(db.threadStates).getSingle()).unreadCount, 0);
    });

    test('markRead offline returns false but still clears locally', () async {
      await seedThread(db, 'g1', unreadCount: 2);
      setup({});
      expect(await repo.markRead(1, 'g1'), isFalse);
      expect((await db.select(db.threadStates).getSingle()).unreadCount, 0);
    });

    test('setMuted stores the server answer and keeps other fields', () async {
      await seedThread(db, 'g1', label: 'Fast', closed: true);
      setup({
        'PUT /app/clubs/1/groups/g1/thread': const FakeResponse(200, {
          'muted': true,
          'unreadCount': 2,
        }),
      });
      await repo.setMuted(1, 'g1', true);
      final row = await db.select(db.threadStates).getSingle();
      expect(row.muted, isTrue);
      expect(row.unreadCount, 2);
      expect(row.label, 'Fast');
      expect(row.closed, isTrue);
      expect(adapter.requests.single.data, {'muted': true});
    });

    test('setMuted offline throws and changes nothing', () async {
      setup({});
      await expectLater(
        repo.setMuted(1, 'g1', true),
        throwsA(isA<ApiException>()),
      );
      expect(await db.select(db.threadStates).get(), isEmpty);
    });
  });

  test('the info line can be dismissed and is remembered', () async {
    setup({});
    expect(await repo.isInfoDismissed(), isFalse);
    await repo.dismissInfo();
    expect(await repo.isInfoDismissed(), isTrue);
  });
}
