import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/updates/data/posts_repository.dart';
import 'package:bpj/features/members/ui/member_providers.dart';
import 'package:bpj/features/updates/ui/post_detail_screen.dart';
import 'package:bpj/features/updates/ui/updates_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase2.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  Future<void> pumpUpdates(
    WidgetTester tester, {
    required List<String> roles,
  }) async {
    adapter = FakeAdapter({
      'POST /app/clubs/1/link': FakeResponse(200, membershipJson(roles: roles)),
      'GET /app/clubs/1/posts': FakeResponse(200, {
        'items': [
          postJson('p1', title: 'Parkrun moved', priority: 'important'),
          postJson(
            'p2',
            title: 'Social night',
            pinnedUntil: '2999-01-01T00:00:00.000Z',
          ),
        ],
        'serverTime': '2026-10-07T12:00:00.000Z',
      }),
    });
    final dio = fakeDio(adapter);
    await tester.runAsync(
      () => MembershipRepository(
        db,
        dio,
      ).link(1, urn: 1, dob: DateTime(1990, 1, 1)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(
            MembershipRepository(db, dio),
          ),
          postsRepositoryProvider.overrideWithValue(PostsRepository(db, dio)),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
        ],
        child: const MaterialApp(home: UpdatesScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('post detail: author avatar + tappable name, then the time', (
    tester,
  ) async {
    await pumpUpdates(tester, roles: ['committee']);
    await unmount(tester); // a fresh ProviderScope for the detail page
    final dio = fakeDio(adapter);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const PostDetailScreen(postId: 'p1'),
        ),
        GoRoute(
          path: '/members/:memberId',
          builder: (_, state) => Scaffold(
            appBar: AppBar(),
            body: Text('Profile ${state.pathParameters['memberId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membershipRepositoryProvider.overrideWithValue(
            MembershipRepository(db, dio),
          ),
          postsRepositoryProvider.overrideWithValue(PostsRepository(db, dio)),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          memberCardsProvider.overrideWith(
            (ref) => Stream.value(const <String, MemberCard>{}),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sam Chair'), findsOneWidget);
    expect(find.text('SC'), findsOneWidget);
    await tester.tap(find.text('Sam Chair'));
    await tester.pumpAndSettle();
    expect(find.text('Profile member-9'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Sam Chair'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('committee members see the compose button', (tester) async {
    await pumpUpdates(tester, roles: ['committee']);
    expect(find.text('Parkrun moved'), findsOneWidget);
    expect(find.text('Important'), findsOneWidget);
    expect(find.text('Pinned'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('admins see it too, plain members and leaders do not', (
    tester,
  ) async {
    await pumpUpdates(tester, roles: ['admin']);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await unmount(tester);

    await db.clearAll();
    await pumpUpdates(tester, roles: ['leader']);
    expect(find.text('Parkrun moved'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await unmount(tester);
  });
}
