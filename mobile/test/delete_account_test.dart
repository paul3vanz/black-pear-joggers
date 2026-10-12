import 'dart:async';
import 'dart:typed_data';

import 'package:bpj/core/api/api_exception.dart';
import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/notifications/push_service.dart';
import 'package:bpj/core/util/image_cache_clearer.dart';
import 'package:bpj/core/util/open_link.dart';
import 'package:bpj/features/profile/data/account_repository.dart';
import 'package:bpj/features/profile/ui/about_screen.dart';
import 'package:bpj/features/profile/ui/delete_account_screen.dart';
import 'package:bpj/features/profile/ui/profile_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_api.dart';

/// In-memory keystore with the same observable behaviour as [AccountStore].
class _MemoryAccountStore implements AccountStore {
  _MemoryAccountStore(this.accounts) : active = accounts.first.sub;

  List<Account> accounts;
  String? active;

  @override
  Future<List<Account>> readAccounts() async => [...accounts];
  @override
  Future<String?> readActiveSub() async => active;
  @override
  Future<void> writeActiveSub(String? sub) async => active = sub;
  @override
  Future<int?> readActiveClubId(String sub) async => null;
  @override
  Future<void> removeAccount(String sub) async {
    accounts = accounts.where((a) => a.sub != sub).toList();
    if (active == sub) active = accounts.isEmpty ? null : accounts.first.sub;
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

class _FakePush implements PushService {
  final unregistered = <String>[];

  @override
  Future<void> unregisterDevice(String sub) async => unregistered.add(sub);

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// A [FakeAdapter] whose responses wait until [release] is called, so a test can
/// act while a request is in flight.
class _GatedAdapter extends FakeAdapter {
  _GatedAdapter(super.routes);

  final _gate = Completer<void>();
  void release() => _gate.complete();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await _gate.future;
    return super.fetch(options, null, cancelFuture);
  }
}

const _alice = Account(sub: 'auth0|alice', email: 'alice@example.com');
const _bob = Account(sub: 'auth0|bob', email: 'bob@example.com');

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late _MemoryAccountStore store;
  late _FakePush push;
  late GoRouter router;
  late List<String> events;
  final opened = <Uri>[];

  const deleted = FakeResponse(204);
  const lastAdmin = FakeResponse(409, {
    'error': 'last_admin',
    'message': 'Make someone else an admin first.',
  });

  setUp(() {
    opened.clear();
    events = [];
    db = memoryDb();
    store = _MemoryAccountStore([_alice]);
    push = _FakePush();
    adapter = FakeAdapter({'DELETE /app/account': deleted});
  });
  tearDown(() => db.close());

  /// Mounts About + Delete under a tiny router that behaves like the real one
  /// for this purpose: nobody signed in -> `/sign-in`.
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    FakeAdapter? useAdapter,
    List<Account>? accounts,
  }) async {
    if (accounts != null) store = _MemoryAccountStore(accounts);
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final refresh = ValueNotifier<int>(0);
    late ProviderContainer container;
    router = GoRouter(
      initialLocation: '/home',
      refreshListenable: refresh,
      redirect: (context, state) {
        final active = container.read(accountsControllerProvider).value;
        if (active != null && active.activeSub == null) return '/sign-in';
        return null;
      },
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('Profile tab')),
        GoRoute(
          path: '/profile/about',
          builder: (_, _) => const AboutScreen(),
          routes: [
            GoRoute(
              path: 'delete',
              builder: (_, _) => const DeleteAccountScreen(),
            ),
          ],
        ),
        GoRoute(path: '/sign-in', builder: (_, _) => const Text('Sign in')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStoreProvider.overrideWithValue(store),
          pushServiceProvider.overrideWithValue(push),
          appDatabaseProvider.overrideWithValue(db),
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(fakeDio(useAdapter ?? adapter)),
          ),
          appVersionProvider.overrideWith((ref) async => '2.3.4 (56)'),
          imageCacheClearerProvider.overrideWithValue(
            () async => events.add('image cache cleared'),
          ),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            ref.listen(accountsControllerProvider, (_, _) => refresh.value++);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  Future<void> openAbout(WidgetTester tester) async {
    unawaited(router.push('/profile/about'));
    await settle(tester);
  }

  Future<void> openDelete(WidgetTester tester) async {
    await openAbout(tester);
    await tester.tap(find.byKey(const ValueKey('delete-account-tile')));
    await settle(tester);
  }

  FilledButton confirmButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const ValueKey('delete-confirm')));

  Future<void> typeConfirm(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('confirm-field')), text);
    await tester.pump();
  }

  group('AccountRepository', () {
    test('DELETEs /app/account with the confirm word', () async {
      await AccountRepository(fakeDio(adapter)).deleteAccount();

      final req = adapter.requests.single;
      expect(req.method, 'DELETE');
      expect(req.path, '/app/account');
      expect(req.data, {'confirm': 'DELETE'});
    });

    test('maps 409 last_admin to an ApiException with the message', () async {
      adapter.routes['DELETE /app/account'] = lastAdmin;
      await expectLater(
        AccountRepository(fakeDio(adapter)).deleteAccount(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.code, 'code', 'last_admin')
              .having(
                (e) => e.message,
                'message',
                'Make someone else an admin first.',
              ),
        ),
      );
    });
  });

  group('About screen', () {
    testWidgets('shows name, version, links and the delete tile', (
      tester,
    ) async {
      await pump(tester);
      await openAbout(tester);

      expect(find.text('Black Pear Joggers'), findsOneWidget);
      expect(find.text('Version 2.3.4 (56)'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Danger zone'), findsOneWidget);
      expect(find.text('Delete my account'), findsOneWidget);

      await tester.tap(find.text('Privacy policy'));
      await tester.pump();
      await tester.tap(find.text('Club website'));
      await tester.pump();
      await tester.tap(find.text('Contact the committee'));
      await tester.pump();
      expect(opened, [
        Uri.parse('https://bpj.org.uk/privacy-policy'),
        Uri.parse('https://bpj.org.uk'),
        Uri.parse('https://bpj.org.uk/contact?reason=website'),
      ]);
    });

    testWidgets('Back returns to where it was opened from', (tester) async {
      await pump(tester);
      await openAbout(tester);
      await tester.pageBack();
      await settle(tester);
      expect(find.text('Profile tab'), findsOneWidget);
    });

    testWidgets('the delete tile opens the explanation screen', (tester) async {
      await pump(tester);
      await openDelete(tester);

      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Your chat messages'), findsOneWidget);
      expect(
        find.text('Your Black Pear Joggers website login'),
        findsOneWidget,
      );
      expect(find.textContaining('contact the club'), findsOneWidget);
    });
  });

  group('Delete screen', () {
    testWidgets('the button needs exactly DELETE (case-sensitive)', (
      tester,
    ) async {
      await pump(tester);
      await openDelete(tester);

      expect(confirmButton(tester).onPressed, isNull);
      for (final wrong in ['delete', 'Delete', 'DELET', 'DELETE ', ' DELETE']) {
        await typeConfirm(tester, wrong);
        expect(confirmButton(tester).onPressed, isNull, reason: wrong);
      }
      await typeConfirm(tester, 'DELETE');
      expect(confirmButton(tester).onPressed, isNotNull);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('success wipes local data, signs out and shows sign-in', (
      tester,
    ) async {
      await db
          .into(db.syncCursors)
          .insert(SyncCursorsCompanion.insert(key: 'k', serverTime: 'v'));
      final container = await pump(tester);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);

      final req = adapter.requests.single;
      expect(req.method, 'DELETE');
      expect(req.data, {'confirm': 'DELETE'});
      // Local rows gone, credentials gone, push token deregistered.
      expect(await db.select(db.syncCursors).get(), isEmpty);
      expect(events, ['image cache cleared']);
      expect(store.accounts, isEmpty);
      expect(push.unregistered, [_alice.sub]);
      expect(container.read(activeSubProvider), isNull);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('with a second account signed in, switches to it', (
      tester,
    ) async {
      final container = await pump(tester, accounts: [_alice, _bob]);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);

      expect(store.accounts.map((a) => a.sub), [_bob.sub]);
      expect(container.read(activeSubProvider), _bob.sub);
      expect(find.text('Sign in'), findsNothing);
    });

    testWidgets('409 last_admin shows the server message and stays signed in', (
      tester,
    ) async {
      adapter.routes['DELETE /app/account'] = lastAdmin;
      await db
          .into(db.syncCursors)
          .insert(SyncCursorsCompanion.insert(key: 'k', serverTime: 'v'));
      final container = await pump(tester);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);

      expect(find.text('Make someone else an admin first.'), findsOneWidget);
      expect(container.read(activeSubProvider), _alice.sub);
      expect(store.accounts, [_alice]);
      expect(push.unregistered, isEmpty);
      expect(events, isEmpty);
      expect(await db.select(db.syncCursors).get(), hasLength(1));
      expect(find.text('Sign in'), findsNothing);
      // The member can try again.
      expect(confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('offline says a connection is needed and keeps everything', (
      tester,
    ) async {
      adapter.routes.clear(); // no route = connection error
      final container = await pump(tester);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);

      expect(
        find.text('You need a connection to delete your account.'),
        findsOneWidget,
      );
      expect(container.read(activeSubProvider), _alice.sub);
      expect(store.accounts, [_alice]);
      expect(events, isEmpty);
    });

    testWidgets('other server errors show a message with a retry button', (
      tester,
    ) async {
      adapter.routes['DELETE /app/account'] = const FakeResponse(500, {
        'error': 'server_error',
        'message': 'Boom.',
      });
      await pump(tester);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);

      expect(find.textContaining('Boom.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // Retry succeeds this time.
      adapter.routes['DELETE /app/account'] = deleted;
      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);
      expect(adapter.requests, hasLength(2));
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('an expired session uses the normal session-expiry handling', (
      tester,
    ) async {
      adapter.routes['DELETE /app/account'] = const FakeResponse(401, {
        'error': 'session_expired',
        'message': 'Expired.',
      });
      final container = await pump(tester);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(tester);

      expect(container.read(activeSubProvider), isNull);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.textContaining('Expired.'), findsNothing);
    });

    testWidgets('a double tap sends one request and blocks Back', (
      tester,
    ) async {
      final gated = _GatedAdapter({'DELETE /app/account': deleted});
      await pump(tester, useAdapter: gated);
      await openDelete(tester);
      await typeConfirm(tester, 'DELETE');

      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await tester.pump();
      // In flight: spinner shown, button disabled, a second tap does nothing.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey('delete-confirm')),
        warnIfMissed: false,
      );
      await tester.pump();
      // System Back is blocked while the request runs.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const ValueKey('delete-confirm')), findsOneWidget);

      gated.release();
      await settle(tester);

      expect(gated.requests, hasLength(1));
      expect(find.text('Sign in'), findsOneWidget);
    });
  });
}

/// Real time for I/O (Drift, dio), then pumps for fake-async timers and the
/// router, the same trick as `settle` in profile_screen_test.dart.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}
