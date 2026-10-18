import 'dart:async';
import 'dart:io';

import 'package:bpj/app/router.dart';
import 'package:bpj/core/api/api_client.dart';
import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/diagnostics/db_guard.dart';
import 'package:bpj/core/diagnostics/diagnostics.dart';
import 'package:bpj/core/util/image_cache_clearer.dart';
import 'package:bpj/features/profile/ui/profile_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/clipboard_mock.dart';
import 'support/fake_api.dart';
import 'support/memory_account_store.dart';

const _alice = Account(sub: 'auth0|alice', email: 'alice@example.com');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases =
      true; // resets reopen a file
  late Directory dir;
  late MemoryAccountStore store;
  late bool failing;
  late ProviderContainer container;

  File dbFile() =>
      File(p.join(dir.path, '${databaseNameFor(_alice.sub)}.sqlite'));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bpj_guard_');
    store = MemoryAccountStore([_alice]);
    failing = false;
    container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        databaseDirectoryProvider.overrideWithValue(() async => dir),
        imageCacheClearerProvider.overrideWithValue(() async {}),
        appVersionProvider.overrideWith((ref) async => '9.9.9 (99)'),
        // Real SQLite file in the temp dir, or one that can never open.
        appDatabaseProvider.overrideWith((ref) {
          final sub = ref.watch(activeSubProvider)!;
          final db = failing
              ? AppDatabase(
                  LazyDatabase(() async => throw StateError('disk I/O error')),
                )
              : AppDatabase(
                  NativeDatabase(
                    File(p.join(dir.path, '${databaseNameFor(sub)}.sqlite')),
                  ),
                );
          ref.onDispose(
            () => unawaited(db.close().then((_) {}, onError: (Object _) {})),
          );
          return db;
        }),
        // Keeps `/app/me` off the network when the real router runs.
        apiClientProvider.overrideWith((ref) => fakeDio(FakeAdapter({}))),
      ],
    );
    addTearDown(() async {
      container.dispose();
      // Windows keeps a file locked until the connection has really closed.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // A leftover temp folder is harmless.
      }
    });
  });

  Future<void> signedIn() => container.read(accountsControllerProvider.future);

  List<String> log() => [
    for (final e in container.read(diagnosticsProvider).entries) e.message,
  ];

  test('a healthy database passes the first check untouched', () async {
    await signedIn();
    expect(await container.read(dbGuardProvider.future), DbGuardResult.ok);
    expect(log().where((m) => m.contains('failed')), isEmpty);
  });

  test('nobody signed in: nothing to check', () async {
    store.active = null;
    await signedIn();
    expect(await container.read(dbGuardProvider.future), DbGuardResult.ok);
  });

  test('a damaged file is deleted and the retry works', () async {
    // 300 bytes of text: SQLite says "file is not a database".
    dbFile().writeAsStringSync('this is not sqlite ' * 16);
    await signedIn();

    expect(await container.read(dbGuardProvider.future), DbGuardResult.healed);

    final db = container.read(appDatabaseProvider);
    expect(await db.select(db.memberships).get(), isEmpty);
    expect(
      dbFile().readAsBytesSync().take(15).toList(),
      'SQLite format 3'.codeUnits,
      reason: 'the damaged file was replaced by a fresh database',
    );
    expect(log(), contains(startsWith('db open failed')));
    expect(log(), contains(startsWith('db recovered')));
  });

  test('the files of other accounts are not touched', () async {
    final other = File(
      p.join(dir.path, '${databaseNameFor('auth0|bob')}.sqlite'),
    )..writeAsStringSync('bob data');
    dbFile().writeAsStringSync('garbage ' * 50);
    await signedIn();
    await container.read(dbGuardProvider.future);
    expect(other.readAsStringSync(), 'bob data');
  });

  test(
    'deleteAccountDatabaseFiles removes the sqlite file and siblings',
    () async {
      final base = dbFile().path;
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        File('$base$suffix').writeAsStringSync('x');
      }
      final removed = await deleteAccountDatabaseFiles(
        _alice.sub,
        directory: () async => dir,
      );
      expect(removed, 4);
      expect(dir.listSync(), isEmpty);
    },
  );

  test('failing twice gives up', () async {
    failing = true;
    await signedIn();
    expect(await container.read(dbGuardProvider.future), DbGuardResult.failed);
    expect(log(), contains(startsWith('db still failing')));
  });

  group('router', () {
    Future<void> pumpApp(WidgetTester tester) async {
      await signedIn();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) =>
                MaterialApp.router(routerConfig: ref.watch(routerProvider)),
          ),
        ),
      );
      // Let the guard (two probes and a delete) finish; the app never settles
      // because later screens animate, so pump instead of pumpAndSettle.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('failing twice shows /recover with the two actions', (
      tester,
    ) async {
      failing = true;
      final clipboard = ClipboardMock(tester.binding);
      await pumpApp(tester);

      expect(find.text("The app couldn't load its saved data"), findsOneWidget);
      expect(find.text('Reset and try again'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('copy-diagnostics')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(clipboard.copied, hasLength(1));
      expect(clipboard.copied.single, contains('db still failing'));
      expect(clipboard.copied.single, contains('App version: 9.9.9 (99)'));
      expect(clipboard.copied.single, isNot(contains('example.com')));
    });

    testWidgets('Reset and try again leaves /recover once the database opens', (
      tester,
    ) async {
      failing = true;
      await pumpApp(tester);
      expect(find.text("The app couldn't load its saved data"), findsOneWidget);

      failing = false; // what deleting the files achieves on a real phone
      await tester.tap(find.byKey(const ValueKey('reset-and-retry')));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text("The app couldn't load its saved data"), findsNothing);
      expect(await container.read(dbGuardProvider.future), DbGuardResult.ok);
      expect(
        store.credentials,
        contains(_alice.sub),
        reason: 'still signed in',
      );
    });
  });
}
