import 'dart:io';

import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';
import 'package:bpj/core/auth/accounts_controller.dart';
import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/diagnostics/db_guard.dart';
import 'package:bpj/core/diagnostics/diagnostics.dart';
import 'package:bpj/core/diagnostics/recovery.dart';
import 'package:bpj/core/util/image_cache_clearer.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/memory_account_store.dart';

const _alice = Account(sub: 'auth0|alice');
const _bob = Account(sub: 'auth0|bob');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory dir;
  late MemoryAccountStore store;
  late ProviderContainer container;
  late int imageCacheClears;

  File fileFor(String sub) =>
      File(p.join(dir.path, '${databaseNameFor(sub)}.sqlite'));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bpj_recovery_');
    store = MemoryAccountStore([_alice, _bob]);
    imageCacheClears = 0;
    container = ProviderContainer(
      overrides: [
        accountStoreProvider.overrideWithValue(store),
        databaseDirectoryProvider.overrideWithValue(() async => dir),
        imageCacheClearerProvider.overrideWithValue(() async {
          imageCacheClears++;
        }),
        appDatabaseProvider.overrideWith((ref) {
          final sub = ref.watch(activeSubProvider)!;
          final db = AppDatabase(NativeDatabase(fileFor(sub)));
          ref.onDispose(() => db.close().then((_) {}, onError: (Object _) {}));
          return db;
        }),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // A leftover temp folder is harmless.
      }
    });
  });

  Future<void> putCursor(AppDatabase db, String key) => db
      .into(db.syncCursors)
      .insert(
        SyncCursorsCompanion.insert(
          key: key,
          serverTime: '2026-10-01T10:00:00Z',
        ),
      );

  Future<int> cursorCount() async {
    final db = container.read(appDatabaseProvider);
    return (await db.select(db.syncCursors).get()).length;
  }

  List<String> log() => [
    for (final e in container.read(diagnosticsProvider).entries) e.message,
  ];

  test(
    'reset local data empties the cache, keeps credentials, re-bootstraps',
    () async {
      await container.read(accountsControllerProvider.future);
      await container.read(dbGuardProvider.future);
      await putCursor(container.read(appDatabaseProvider), 'posts');
      expect(await cursorCount(), 1);
      final guardBefore = container.read(dbGuardProvider);

      await container.read(recoveryProvider).resetLocalData();

      expect(await cursorCount(), 0, reason: 'rows are gone');
      expect(imageCacheClears, 1);
      // Still signed in, credentials untouched.
      expect(store.accounts.map((a) => a.sub), ['auth0|alice', 'auth0|bob']);
      expect(store.credentials, contains('auth0|alice'));
      expect(container.read(activeSubProvider), 'auth0|alice');
      // The first-use check ran again on the fresh file.
      await container.read(dbGuardProvider.future);
      expect(container.read(dbGuardProvider), isNot(same(guardBefore)));
      expect(log(), contains('reset local data done'));
    },
  );

  test('reset local data deletes the account file, not the others', () async {
    await container.read(accountsControllerProvider.future);
    await container.read(dbGuardProvider.future);
    fileFor(_bob.sub).writeAsStringSync('bob data');
    final aliceBefore = fileFor(_alice.sub).lengthSync();
    expect(aliceBefore, greaterThan(0));

    await container.read(recoveryProvider).resetLocalData(clearRows: false);

    expect(fileFor(_bob.sub).readAsStringSync(), 'bob data');
    // Alice's file was removed; the re-run guard created a fresh one.
    await container.read(dbGuardProvider.future);
    expect(container.read(dbGuardProvider).value, DbGuardResult.ok);
  });

  test(
    'full reset wipes every account on the phone and signs out locally',
    () async {
      await container.read(accountsControllerProvider.future);
      await container.read(dbGuardProvider.future);
      await putCursor(container.read(appDatabaseProvider), 'posts');
      fileFor(_bob.sub).writeAsStringSync('bob data');

      // No push or Auth0 overrides: if this tried to call the server through
      // the normal sign-out it would fail here.
      await container.read(recoveryProvider).fullReset();

      expect(store.accounts, isEmpty);
      expect(store.credentials, isEmpty);
      expect(store.active, isNull);
      expect(container.read(activeSubProvider), isNull);
      expect(fileFor(_alice.sub).existsSync(), isFalse);
      expect(fileFor(_bob.sub).existsSync(), isFalse);
      expect(imageCacheClears, 1);
      expect(log(), contains('full reset done: signed out of 2'));
    },
  );
}
