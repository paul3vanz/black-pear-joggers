import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/groups/data/small_kv_store.dart';
import 'package:bpj/features/updates/data/post_receipts_repository.dart';
import 'package:bpj/features/updates/data/posts_repository.dart';
import 'package:bpj/features/updates/ui/post_detail_screen.dart';
import 'package:bpj/features/updates/ui/post_receipts_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase2.dart';
import 'support/groups_test_support.dart';

/// Delivered / read receipts for club updates (D123).
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  const receiptsPath = '/app/clubs/1/posts/receipts';
  final now = DateTime.utc(2026, 10, 21, 12);

  Map<String, Object?> mine(String id) => {
    ...postJson(id),
    'author': {'memberId': 'me', 'displayName': 'Me'},
  };

  Future<(FakeAdapter, PostReceiptsRepository)> repoWith(
    List<Map<String, Object?>> posts,
  ) async {
    final adapter = FakeAdapter({
      'GET /app/clubs/1/posts': FakeResponse(200, {
        'items': posts,
        'serverTime': '2026-10-21T12:00:00.000Z',
      }),
      'POST $receiptsPath': const FakeResponse(204),
    });
    final dio = fakeDio(adapter);
    await PostsRepository(db, dio).refresh(1);
    return (adapter, PostReceiptsRepository(db, dio, clock: () => now));
  }

  List<Map<String, Object?>> sentItems(FakeAdapter a, int call) =>
      ((a.requests.where((r) => r.method == 'POST').toList()[call].data!
                  as Map)['items']!
              as List)
          .cast<Map<String, Object?>>();

  group('repository', () {
    test('reports every cached update as delivered once', () async {
      final (adapter, repo) = await repoWith([postJson('a'), postJson('b')]);

      await repo.sync(1, myMemberId: 'me');
      expect(
        sentItems(adapter, 0).map((i) => [i['postId'], i['state']]).toList(),
        [
          ['a', 'delivered'],
          ['b', 'delivered'],
        ],
      );

      // Remembered: a second sync sends nothing.
      await repo.sync(1, myMemberId: 'me');
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    });

    test('skips your own updates', () async {
      final (adapter, repo) = await repoWith([mine('a'), postJson('b')]);
      await repo.sync(1, myMemberId: 'me');
      expect(sentItems(adapter, 0).map((i) => i['postId']).toList(), ['b']);
    });

    test('a read update is sent as read with the time it was read', () async {
      final (adapter, repo) = await repoWith([postJson('a')]);
      await repo.sync(1); // delivered
      await repo.markRead(1, 'a');
      await repo.sync(1);

      final read = sentItems(adapter, 1).single;
      expect(read['state'], 'read');
      expect(read['at'], now.toIso8601String());

      await repo.sync(1);
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(2));
    });

    test('offline: nothing is marked sent, so the next sync retries', () async {
      final (adapter, repo) = await repoWith([postJson('a')]);
      adapter.routes.remove('POST $receiptsPath'); // no route = offline
      await repo.sync(1);
      expect(
        await SmallKvStore(db).get(PostReceiptsRepository.sentKey(1, 'a')),
        isNull,
      );

      adapter.routes['POST $receiptsPath'] = const FakeResponse(204);
      await repo.sync(1);
      expect(
        await SmallKvStore(db).get(PostReceiptsRepository.sentKey(1, 'a')),
        'd',
      );
    });

    test('parses the committee view', () async {
      final (adapter, repo) = await repoWith([postJson('a')]);
      adapter.routes['GET /app/clubs/1/posts/a/receipts'] = const FakeResponse(
        200,
        {
          'postId': 'a',
          'audienceCount': 3,
          'deliveredCount': 2,
          'readCount': 1,
          'members': [
            {'memberId': 'm1', 'displayName': 'Abi L.', 'state': 'read'},
            {'memberId': 'm2', 'displayName': 'Ben M.', 'state': 'delivered'},
            {'memberId': 'm3', 'displayName': 'Cy N.', 'state': 'none'},
          ],
        },
      );
      final r = await repo.fetch(1, 'a');
      expect((r.audienceCount, r.deliveredCount, r.readCount), (3, 2, 1));
      expect(r.members.map((m) => m.state).toList(), [
        ReceiptState.read,
        ReceiptState.delivered,
        ReceiptState.none,
      ]);
    });
  });

  group('post screen', () {
    Future<FakeAdapter> pumpPost(
      WidgetTester tester, {
      required Map<String, Object?> post,
      List<String> roles = const [],
    }) async {
      final adapter = await prepareMember(
        tester,
        db,
        roles: roles,
        routes: {
          'GET /app/clubs/1/posts': FakeResponse(200, {
            'items': [post],
            'serverTime': '2026-10-21T12:00:00.000Z',
          }),
          'POST $receiptsPath': const FakeResponse(204),
          'GET /app/clubs/1/posts/p1/receipts': const FakeResponse(200, {
            'postId': 'p1',
            'audienceCount': 4,
            'deliveredCount': 3,
            'readCount': 1,
            'members': [
              {'memberId': 'm1', 'displayName': 'Abi L.', 'state': 'read'},
              {'memberId': 'm2', 'displayName': 'Ben M.', 'state': 'delivered'},
              {'memberId': 'm4', 'displayName': 'Dee P.', 'state': 'delivered'},
              {'memberId': 'm3', 'displayName': 'Cy N.', 'state': 'none'},
            ],
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
        const PostDetailScreen(postId: 'p1'),
      );
      return adapter;
    }

    Future<void> realDelay(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    Future<void> dwell(WidgetTester tester) async {
      await tester.pump(
        PostDetailScreen.readDwell + const Duration(seconds: 1),
      );
      await realDelay(tester);
    }

    List<Object?> reads(FakeAdapter a) => [
      for (final r in a.requests.where((r) => r.path == receiptsPath))
        for (final i in ((r.data! as Map)['items']! as List))
          if ((i as Map)['state'] == 'read') i['postId'],
    ];

    testWidgets('a short update is read once it has been open a moment', (
      tester,
    ) async {
      final adapter = await pumpPost(tester, post: postJson('p1'));
      expect(reads(adapter), isEmpty);
      await dwell(tester);
      expect(reads(adapter), ['p1']);
      await unmount(tester);
    });

    testWidgets('a long update is only read once scrolled to the end', (
      tester,
    ) async {
      final long = {
        ...postJson('p1'),
        'bodyMd': List.filled(120, 'Line').join('\n\n'),
      };
      final adapter = await pumpPost(tester, post: long);
      await dwell(tester);
      expect(reads(adapter), isEmpty);

      await tester.drag(find.byType(ListView).first, const Offset(0, -20000));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await realDelay(tester);
      expect(reads(adapter), ['p1']);
      await unmount(tester);
    });

    testWidgets('your own update is never reported', (tester) async {
      final adapter = await pumpPost(tester, post: mine('p1'));
      await dwell(tester);
      expect(reads(adapter), isEmpty);
      await unmount(tester);
    });

    testWidgets('members do not see who has read it', (tester) async {
      await pumpPost(tester, post: postJson('p1'));
      expect(find.text('Seen by'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the committee sees counts and names', (tester) async {
      await pumpPost(tester, post: postJson('p1'), roles: ['committee']);
      await realDelay(tester);
      await tester.pumpAndSettle();
      expect(find.text('Seen by'), findsOneWidget);
      expect(find.text('1 read'), findsOneWidget);
      expect(find.text('2 delivered'), findsOneWidget);
      expect(find.text('1 not yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('receiptsNames')));
      await tester.pumpAndSettle();
      expect(find.text('Not yet (1)'), findsOneWidget);
      expect(find.text('Cy N.'), findsOneWidget);
      await unmount(tester);
    });
  });

  testWidgets('ticks: one for delivered, two for read', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            ReceiptTick(ReceiptState.delivered),
            ReceiptTick(ReceiptState.read),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
  });
}
