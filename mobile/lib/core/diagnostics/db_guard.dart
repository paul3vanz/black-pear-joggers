import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../auth/accounts_controller.dart';
import '../db/app_database.dart';
import 'diagnostics.dart';
import 'redaction.dart';

/// Where the per-account database files live: the same directory drift_flutter's
/// `driftDatabase(name:)` uses. A provider so tests can point it at a temp folder.
final databaseDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => getApplicationDocumentsDirectory,
);

/// Deletes `bpj_<hash>.sqlite` and its `-wal` / `-shm` / `-journal` siblings for
/// account [sub]. The caller must have CLOSED that account's database first:
/// removing a SQLite file under an open connection is unsafe.
/// Returns how many files were removed.
Future<int> deleteAccountDatabaseFiles(
  String sub, {
  required Future<Directory> Function() directory,
}) async {
  final dir = (await directory()).path;
  final base = p.join(dir, '${databaseNameFor(sub)}.sqlite');
  var removed = 0;
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final f = File('$base$suffix');
    if (f.existsSync()) {
      await f.delete();
      removed++;
    }
  }
  return removed;
}

/// Outcome of the first database use after start (see [runDbGuard]).
enum DbGuardResult {
  /// Opened and answered a query first time.
  ok,

  /// Failed once, the files were deleted, and the retry worked.
  healed,

  /// Failed even after the files were deleted: show `/recover`.
  failed,
}

/// Self-heal for a database that won't open or migrate (D101), e.g. after an app
/// update left a half-migrated or damaged file.
///
/// 1. [probe] opens the database and runs one cheap query.
/// 2. If that throws, log it, run [resetFiles] (close + delete this account's
///    files) and try [probe] ONCE more.
/// 3. If it still throws, give up: the router shows `/recover`.
///
/// This only ever deletes the local cache. Everything in it is re-downloadable
/// except unsent outbox rows, which is the price of an unusable database.
Future<DbGuardResult> runDbGuard({
  required Future<void> Function() probe,
  required Future<void> Function() resetFiles,
  required Diagnostics diagnostics,
}) async {
  try {
    await probe();
    return DbGuardResult.ok;
  } on Object catch (e) {
    diagnostics.record(
      DiagArea.db,
      'db open failed: ${describeError(e)}',
      level: DiagLevel.error,
    );
    diagnostics.health.reportLocalError();
  }
  try {
    await resetFiles();
  } on Object catch (e) {
    diagnostics.record(
      DiagArea.db,
      'db reset failed: ${describeError(e)}',
      level: DiagLevel.error,
    );
  }
  try {
    await probe();
    diagnostics.record(
      DiagArea.db,
      'db recovered: local copy deleted and recreated',
      level: DiagLevel.warn,
    );
    return DbGuardResult.healed;
  } on Object catch (e) {
    diagnostics.record(
      DiagArea.db,
      'db still failing after reset: ${describeError(e)}',
      level: DiagLevel.error,
    );
    return DbGuardResult.failed;
  }
}

/// Closes the active account's database and deletes its files. Invalidating
/// [appDatabaseProvider] disposes the old instance (which closes it) and every
/// repository that watches it, so the next read opens a fresh file.
Future<void> closeAndDeleteDatabase(Ref ref, String sub) async {
  AppDatabase? old;
  try {
    old = ref.read(appDatabaseProvider);
  } on Object {
    // Never created, or signed out: nothing open to close.
  }
  ref.invalidate(appDatabaseProvider);
  try {
    await old?.close(); // already closing via onDispose; closing twice is fine
  } on Object {
    // A database that failed to open may fail to close too.
  }
  await deleteAccountDatabaseFiles(
    sub,
    directory: ref.read(databaseDirectoryProvider),
  );
}

/// The first-use check for the active account. The router waits for it
/// (`/splash` while loading, `/recover` when it failed), so no screen reads a
/// database that hasn't proved it can answer a query. Re-runs on account switch.
final dbGuardProvider = FutureProvider<DbGuardResult>((ref) async {
  final sub = ref.watch(activeSubProvider);
  if (sub == null) return DbGuardResult.ok;
  final diagnostics = ref.read(diagnosticsProvider);
  return runDbGuard(
    diagnostics: diagnostics,
    probe: () async {
      final db = ref.read(appDatabaseProvider);
      // Opens (and migrates) the file, then reads a real table.
      await db.customSelect('SELECT COUNT(*) FROM memberships').get();
    },
    resetFiles: () => closeAndDeleteDatabase(ref, sub),
  );
});
