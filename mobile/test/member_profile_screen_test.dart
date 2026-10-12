import 'dart:typed_data';

import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/members/data/member_profile_repository.dart';
import 'package:bpj/features/members/ui/member_avatar.dart';
import 'package:bpj/features/members/ui/member_profile_screen.dart';
import 'package:bpj/features/members/ui/member_providers.dart';
import 'package:bpj/features/membership/ui/membership_providers.dart';
import 'package:bpj/features/updates/ui/updates_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase65.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;

  setUp(() {
    db = memoryDb();
    adapter = FakeAdapter({});
  });
  tearDown(() => db.close());

  const profileKey = 'GET /app/clubs/1/members/sam/profile';

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  /// Opens `/members/<memberId>` with a stub for the card editor route.
  Future<GoRouter> pump(
    WidgetTester tester, {
    String memberId = 'sam',
    bool committee = false,
  }) async {
    final dio = fakeDio(adapter);
    final router = GoRouter(
      initialLocation: '/members/$memberId',
      routes: [
        GoRoute(
          path: '/members/:memberId',
          builder: (_, state) =>
              MemberProfileScreen(memberId: state.pathParameters['memberId']!),
        ),
        GoRoute(
          path: '/profile/card',
          builder: (_, _) => const Scaffold(body: Text('Card editor')),
        ),
        GoRoute(path: '/runs', builder: (_, _) => const Text('Runs')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberProfileRepositoryProvider.overrideWithValue(
            MemberProfileRepository(db, dio),
          ),
          activeClubIdProvider.overrideWithValue(1),
          activeSubProvider.overrideWithValue('test|sub'),
          ownMemberIdProvider.overrideWithValue('me'),
          canPostProvider.overrideWithValue(committee),
          avatarImageFactoryProvider.overrideWithValue(
            (url) => MemoryImage(Uint8List(0)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
    return router;
  }

  testWidgets('shows name, role badges and bio; goals are hidden', (
    tester,
  ) async {
    adapter.routes[profileKey] = FakeResponse(
      200,
      memberProfileJson('sam', roles: ['leader', 'committee']),
    );
    await pump(tester);
    expect(find.text('Sam B.'), findsOneWidget);
    expect(find.text('Leader'), findsOneWidget);
    expect(find.text('Committee'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Love a hilly run.'), findsOneWidget);
    expect(find.text('Goals'), findsNothing);
    expect(find.text('Edit my profile card'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    // Opened directly (nothing to go back to): a Home button instead.
    expect(find.byTooltip('Home'), findsOneWidget);
    // The large avatar is 120 px.
    expect(tester.getSize(find.byType(AvatarCircle)), const Size(120, 120));
    await unmount(tester);
  });

  testWidgets('shows the Goals section only when the API returned goals', (
    tester,
  ) async {
    adapter.routes[profileKey] = FakeResponse(
      200,
      memberProfileJson('sam', goals: 'Break 20 minutes for 5k'),
    );
    await pump(tester);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Break 20 minutes for 5k'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a member with no bio or goals gets a friendly line', (
    tester,
  ) async {
    adapter.routes[profileKey] = FakeResponse(
      200,
      memberProfileJson('sam', bio: null),
    );
    await pump(tester);
    expect(find.textContaining("hasn't added anything"), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('404 shows "This member isn\'t available"', (tester) async {
    adapter.routes[profileKey] = const FakeResponse(404, {
      'error': 'not_found',
      'message': 'No such member',
    });
    await pump(tester);
    expect(find.text("This member isn't available"), findsOneWidget);
    expect(find.text('Sam B.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('offline with a cached copy shows it with a banner', (
    tester,
  ) async {
    adapter.routes[profileKey] = FakeResponse(200, memberProfileJson('sam'));
    final dio = fakeDio(adapter);
    await tester.runAsync(
      () => MemberProfileRepository(db, dio).fetchProfile(1, 'sam'),
    );
    adapter.routes.remove(profileKey);
    await pump(tester);
    expect(find.text('Sam B.'), findsOneWidget);
    expect(find.text('Love a hilly run.'), findsOneWidget);
    expect(
      find.textContaining('Offline: showing a saved copy'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('offline with nothing cached says so and can retry', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text("You're offline"), findsOneWidget);
    adapter.routes[profileKey] = FakeResponse(200, memberProfileJson('sam'));
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('Sam B.'), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
    await unmount(tester);
  });

  testWidgets('your own profile has the note and an edit button', (
    tester,
  ) async {
    adapter.routes['GET /app/clubs/1/members/me/profile'] = FakeResponse(
      200,
      memberProfileJson(
        'me',
        displayName: 'Jo B.',
        isYou: true,
        goals: 'Run more',
      ),
    );
    await pump(tester, memberId: 'me', committee: true);
    expect(
      find.text('This is how you appear to other members.'),
      findsOneWidget,
    );
    expect(find.text('Run more'), findsOneWidget);
    // No moderation menu on yourself, even for the committee.
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    await tester.tap(find.text('Edit my profile card'));
    await tester.pumpAndSettle();
    expect(find.text('Card editor'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('committee can remove photo and bio after confirming', (
    tester,
  ) async {
    adapter.routes
      ..[profileKey] = FakeResponse(
        200,
        memberProfileJson('sam', photoPath: photoPathJson),
      )
      ..['DELETE /app/clubs/1/members/sam/profile'] = const FakeResponse(204)
      ..['GET /app/clubs/1/member-cards'] = FakeResponse(
        200,
        memberCardsBody([]),
      );
    await pump(tester, committee: true);
    expect(find.text('Love a hilly run.'), findsOneWidget);

    // After the clear, the server returns an empty profile.
    adapter.routes[profileKey] = FakeResponse(
      200,
      memberProfileJson('sam', bio: null),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo and bio'));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo and bio?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await settle(tester);

    expect(
      adapter.requests.map((r) => '${r.method} ${r.path}'),
      contains('DELETE /app/clubs/1/members/sam/profile'),
    );
    expect(find.text('Photo, bio and goals removed'), findsOneWidget);
    expect(find.text('Love a hilly run.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('cancelling the confirmation does nothing', (tester) async {
    adapter.routes[profileKey] = FakeResponse(200, memberProfileJson('sam'));
    await pump(tester, committee: true);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo and bio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
    await unmount(tester);
  });

  testWidgets('a failed clear shows the error and keeps the page', (
    tester,
  ) async {
    adapter.routes
      ..[profileKey] = FakeResponse(200, memberProfileJson('sam'))
      ..['DELETE /app/clubs/1/members/sam/profile'] = const FakeResponse(403, {
        'error': 'forbidden',
        'message': 'no',
      });
    await pump(tester, committee: true);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo and bio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await settle(tester);
    expect(find.text('Only the committee can do that.'), findsOneWidget);
    expect(find.text('Love a hilly run.'), findsOneWidget);
    await unmount(tester);
  });
}
