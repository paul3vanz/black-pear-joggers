import 'dart:io';

import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/diagnostics/db_guard.dart';
import 'package:bpj/core/diagnostics/diagnostics.dart';
import 'package:bpj/core/ui/health_banner.dart';
import 'package:bpj/core/util/image_cache_clearer.dart';
import 'package:bpj/features/profile/ui/about_screen.dart';
import 'package:bpj/features/profile/ui/diagnostics_screen.dart';
import 'package:bpj/features/profile/ui/profile_providers.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/clipboard_mock.dart';
import 'support/fake_api.dart';
import 'support/memory_account_store.dart';

const _alice = Account(sub: 'auth0|alice', email: 'alice@example.com');

void main() {
  late AppDatabase db;
  late MemoryAccountStore store;
  late Diagnostics diag;
  late GoRouter router;
  late int imageCacheClears;
  late ClipboardMock clipboard;
  late Directory dir;

  setUp(() {
    db = memoryDb();
    store = MemoryAccountStore([_alice]);
    diag = Diagnostics();
    imageCacheClears = 0;
    dir = Directory.systemTemp.createTempSync('bpj_diag_screen_');
  });
  tearDown(() {
    db.close();
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // harmless
    }
  });

  /// About + Diagnostics under a tiny router that behaves like the real one
  /// for this purpose: nobody signed in -> `/sign-in`.
  Future<void> pump(WidgetTester tester) async {
    clipboard = ClipboardMock(tester.binding);
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final refresh = ValueNotifier<int>(0);
    late ProviderContainer container;
    router = GoRouter(
      initialLocation: '/home',
      refreshListenable: refresh,
      redirect: (context, state) {
        final accounts = container.read(accountsControllerProvider).value;
        if (accounts != null && accounts.activeSub == null) return '/sign-in';
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, _) => '/home'),
        GoRoute(path: '/home', builder: (_, _) => const Text('Profile tab')),
        GoRoute(
          path: '/profile/about',
          builder: (_, _) => const AboutScreen(),
          routes: [
            GoRoute(
              path: 'diagnostics',
              builder: (_, _) => const DiagnosticsScreen(),
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
          appDatabaseProvider.overrideWithValue(db),
          diagnosticsProvider.overrideWithValue(diag),
          databaseDirectoryProvider.overrideWithValue(() async => dir),
          appVersionProvider.overrideWith((ref) async => '2.3.4 (56)'),
          imageCacheClearerProvider.overrideWithValue(() async {
            imageCacheClears++;
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
    await tester.pumpAndSettle();
  }

  Future<void> openDiagnostics(WidgetTester tester) async {
    router.go('/profile/about');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('diagnostics-tile')));
    await tester.pumpAndSettle();
  }

  String reportText(WidgetTester tester) => tester
      .widget<SelectableText>(
        find.descendant(
          of: find.byKey(const ValueKey('diagnostics-report')),
          matching: find.byType(SelectableText),
        ),
      )
      .data!;

  testWidgets(
    'About has a Diagnostics row that opens the screen; Back returns',
    (tester) async {
      await pump(tester);
      router.go('/profile/about');
      await tester.pumpAndSettle();

      expect(find.text('Diagnostics'), findsOneWidget);
      expect(find.text('Help us fix problems'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('diagnostics-tile')));
      await tester.pumpAndSettle();
      expect(find.byType(DiagnosticsScreen), findsOneWidget);
      expect(router.state.uri.path, '/profile/about/diagnostics');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
    },
  );

  testWidgets('the report shows the facts and entries, and no secrets', (
    tester,
  ) async {
    diag
      ..record(DiagArea.startup, 'cold start, version 2.3.4+56')
      ..record(
        DiagArea.api,
        'GET failed: server error for alice@example.com Bearer tok-abc123',
        level: DiagLevel.error,
        status: 500,
        path: '/app/me?email=alice@example.com&token=tok-abc123',
      );
    await pump(tester);
    await openDiagnostics(tester);

    final text = reportText(tester);
    expect(text, contains('App version: 2.3.4 (56)'));
    expect(text, contains('Database schema: 11'));
    expect(text, contains('Signed in: yes'));
    expect(text, contains('/app/me -> 500'));
    expect(text, contains('cold start'));
    for (final secret in ['alice@example.com', 'tok-abc123', 'auth0|alice']) {
      expect(text, isNot(contains(secret)), reason: secret);
    }
    expect(find.textContaining('No personal data is included'), findsOneWidget);
  });

  testWidgets('Copy report writes the report to the clipboard', (tester) async {
    diag.record(DiagArea.ui, 'something odd', level: DiagLevel.warn);
    await pump(tester);
    await openDiagnostics(tester);

    await tester.tap(find.byKey(const ValueKey('copy-report')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(clipboard.copied, hasLength(1));
    expect(clipboard.copied.single, contains('something odd'));
    expect(
      find.text('Copied. Paste it into an email to webmaster@bpj.org.uk'),
      findsOneWidget,
    );
  });

  testWidgets('Clear log empties the log and the report', (tester) async {
    diag.record(DiagArea.ui, 'something odd');
    await pump(tester);
    await openDiagnostics(tester);
    expect(reportText(tester), contains('something odd'));

    await tester.tap(find.byKey(const ValueKey('clear-log')));
    await tester.pumpAndSettle();

    expect(diag.entries, isEmpty);
    expect(reportText(tester), isNot(contains('something odd')));
  });

  testWidgets('Reset local data asks first, then resets and goes home', (
    tester,
  ) async {
    await pump(tester);
    await openDiagnostics(tester);

    await tester.tap(find.byKey(const ValueKey('reset-local')));
    await tester.pumpAndSettle();
    expect(find.text('Reset local data?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(imageCacheClears, 0, reason: 'cancel changes nothing');

    await tester.tap(find.byKey(const ValueKey('reset-local')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(imageCacheClears, 1);
    expect(find.text('Profile tab'), findsOneWidget);
    expect(store.credentials, contains(_alice.sub), reason: 'still signed in');
    expect(
      diag.entries.map((e) => e.message),
      contains('reset local data done'),
    );
  });

  testWidgets('Full reset signs out locally and lands on sign-in', (
    tester,
  ) async {
    await pump(tester);
    await openDiagnostics(tester);

    await tester.tap(find.byKey(const ValueKey('full-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out and clear'));
    await tester.pumpAndSettle();

    expect(store.accounts, isEmpty);
    expect(store.credentials, isEmpty);
    expect(find.text('Sign in'), findsOneWidget);
    expect(imageCacheClears, 1);
  });

  group('health banner', () {
    Future<void> pumpBanner(WidgetTester tester) async {
      final r = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: HealthBannerScope(child: Center(child: Text('content'))),
            ),
          ),
          GoRoute(
            path: '/profile/about/diagnostics',
            builder: (_, _) => const Text('Diagnostics page'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [diagnosticsProvider.overrideWithValue(diag)],
          child: MaterialApp.router(routerConfig: r),
        ),
      );
    }

    testWidgets('hidden normally, shown after four same-class failures', (
      tester,
    ) async {
      await pumpBanner(tester);
      expect(find.byKey(const ValueKey('health-banner')), findsNothing);

      for (var i = 0; i < 3; i++) {
        diag.health.reportApiFailure('5xx');
      }
      await tester.pump();
      expect(find.byKey(const ValueKey('health-banner')), findsNothing);

      diag.health.reportApiFailure('5xx');
      await tester.pump();
      expect(find.text("Something's not working. Tap to fix"), findsOneWidget);
      expect(find.text('content'), findsOneWidget);

      diag.health.reportApiSuccess();
      await tester.pump();
      expect(find.byKey(const ValueKey('health-banner')), findsNothing);
    });

    testWidgets('tap opens diagnostics; the close button hides it', (
      tester,
    ) async {
      await pumpBanner(tester);
      for (var i = 0; i < 4; i++) {
        diag.health.reportApiFailure('5xx');
      }
      await tester.pump();

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(find.byKey(const ValueKey('health-banner')), findsNothing);

      for (var i = 0; i < 4; i++) {
        diag.health.reportApiFailure('5xx');
      }
      await tester.pump();
      await tester.tap(find.text("Something's not working. Tap to fix"));
      await tester.pumpAndSettle();
      expect(find.text('Diagnostics page'), findsOneWidget);
    });
  });
}
