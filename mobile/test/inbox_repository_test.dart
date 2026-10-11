import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/inbox/data/inbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase2.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late InboxRepository repo;

  setUp(() {
    db = memoryDb();
    adapter = FakeAdapter({
      'GET /app/clubs/1/notifications': FakeResponse(200, {
        'items': [
          inboxJson('n1', createdAt: '2026-10-05T10:00:00.000Z'),
          inboxJson('n2', createdAt: '2026-10-06T10:00:00.000Z'),
          inboxJson(
            'n3',
            createdAt: '2026-10-04T10:00:00.000Z',
            readAt: '2026-10-04T11:00:00.000Z',
          ),
        ],
        'serverTime': '2026-10-07T12:00:00.000Z',
        'unreadCount': 2,
      }),
    });
    repo = InboxRepository(db, fakeDio(adapter));
  });
  tearDown(() => db.close());

  test('refresh caches the inbox newest first and counts unread', () async {
    await repo.refresh(1);
    final items = await repo.watchInbox(1).first;
    expect(items.map((i) => i.id), ['n2', 'n1', 'n3']);
    expect(await repo.watchUnreadCount(1).first, 2);
    expect(routeOf(items.first), '/updates/p1');
  });

  test('markAllRead updates locally and POSTs {all: true}', () async {
    await repo.refresh(1);
    adapter.routes['POST /app/clubs/1/notifications/read'] = const FakeResponse(
      204,
    );
    await repo.markAllRead(1);
    expect(await repo.watchUnreadCount(1).first, 0);
    final post = adapter.requests.last;
    expect(post.method, 'POST');
    expect(post.data, {'all': true});
    final rows = await db.select(db.inboxItems).get();
    expect(rows.every((r) => !r.readPending), isTrue);
  });

  test(
    'a failed read POST keeps the local read; the next refresh retries it',
    () async {
      await repo.refresh(1);
      // No POST route -> connection error -> swallowed, the read stays pending.
      await repo.markRead(1, ['n1']);
      expect(await repo.watchUnreadCount(1).first, 1);

      final serverUnread = FakeResponse(200, {
        'items': [inboxJson('n1', createdAt: '2026-10-05T10:00:00.000Z')],
        'serverTime': '2026-10-07T12:10:00.000Z',
      });
      adapter.routes['GET /app/clubs/1/notifications'] = serverUnread;
      await repo.refresh(1); // still offline for POST
      // The server's copy of n1 is unread, but the pending local read wins.
      expect(await repo.watchUnreadCount(1).first, 1);

      adapter.routes['POST /app/clubs/1/notifications/read'] =
          const FakeResponse(204);
      adapter.routes['GET /app/clubs/1/notifications'] = FakeResponse(200, {
        'items': [
          inboxJson(
            'n1',
            createdAt: '2026-10-05T10:00:00.000Z',
            readAt: '2026-10-07T12:11:00.000Z',
          ),
        ],
        'serverTime': '2026-10-07T12:12:00.000Z',
      });
      await repo.refresh(1);
      final retry = adapter.requests.where((r) => r.method == 'POST').last;
      expect(retry.data, {
        'ids': ['n1'],
      });
      expect(await repo.watchUnreadCount(1).first, 1);
      final rows = await db.select(db.inboxItems).get();
      expect(rows.firstWhere((r) => r.id == 'n1').readPending, isFalse);
    },
  );
}
