import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/membership/ui/membership_providers.dart';
import '../auth/account.dart';
import '../auth/accounts_controller.dart';
import '../db/app_database.dart';
import '../util/image_cache_clearer.dart';
import 'db_guard.dart';
import 'diagnostics.dart';
import 'redaction.dart';

/// The two "fix it yourself" actions of the diagnostics screen (D101). Both are
/// local only: they never call the server.
///
/// Why a class on a provider and not code in the screen: a full reset signs the
/// user out, the router then tears the screen down, and a disposed widget's `ref`
/// can no longer be read. A keep-alive provider's `ref` outlives the screen.
class Recovery {
  Recovery(this._ref);

  final Ref _ref;

  Diagnostics get _diag => _ref.read(diagnosticsProvider);

  /// Reset local data: empties this account's cache (rows, sync cursors and the
  /// database file itself) and the image cache, keeps the stored credentials, then
  /// re-bootstraps so everything is fetched again.
  /// [clearRows] is false from `/recover`, which must not touch the broken
  /// database at all.
  Future<void> resetLocalData({bool clearRows = true}) async {
    final sub = _ref.read(activeSubProvider);
    _diag.record(DiagArea.db, 'reset local data requested');
    if (sub != null) {
      if (clearRows) await _tryClearRows();
      await _wipeActiveDatabase(sub);
    }
    await _clearImages();
    _rebootstrap();
    _diag.record(DiagArea.db, 'reset local data done');
  }

  /// Full reset: everything above for EVERY account on the phone, then a local
  /// sign-out of each. Uses `sessionExpired`, the local-only removal (no push
  /// token call, no Auth0 browser sheet), because the app may be unable to reach
  /// either; the user signs in again afterwards.
  Future<void> fullReset() async {
    _diag.record(DiagArea.auth, 'full reset requested');
    final accounts = _ref.read(accountsControllerProvider).value;
    final subs = [for (final a in accounts?.accounts ?? <Account>[]) a.sub];
    final active = accounts?.activeSub;
    final directory = _ref.read(databaseDirectoryProvider);
    if (active != null) {
      await _tryClearRows();
      await _wipeActiveDatabase(active);
    }
    for (final sub in subs) {
      if (sub == active) continue;
      try {
        await deleteAccountDatabaseFiles(sub, directory: directory);
      } on Object catch (e) {
        _diag.record(
          DiagArea.db,
          'delete database failed: ${describeError(e)}',
          level: DiagLevel.error,
        );
      }
    }
    await _clearImages();
    final controller = _ref.read(accountsControllerProvider.notifier);
    for (final sub in subs) {
      await controller.sessionExpired(sub);
    }
    _diag.health.reset();
    _diag.record(
      DiagArea.auth,
      'full reset done: signed out of ${subs.length}',
    );
  }

  /// Rows first, while the connection is open: if the file turns out to be
  /// undeletable, the cache is still empty. A broken database throws; ignored.
  Future<void> _tryClearRows() async {
    try {
      await _ref.read(appDatabaseProvider).clearAll();
    } on Object {
      // Unusable database: the file deletion below is the real fix.
    }
  }

  Future<void> _wipeActiveDatabase(String sub) async {
    try {
      await closeAndDeleteDatabase(_ref, sub);
    } on Object catch (e) {
      _diag.record(
        DiagArea.db,
        'delete database failed: ${describeError(e)}',
        level: DiagLevel.error,
      );
    }
  }

  Future<void> _clearImages() async {
    try {
      await _ref.read(imageCacheClearerProvider)();
    } on Object catch (e) {
      _diag.record(
        DiagArea.ui,
        'clear image cache failed: ${describeError(e)}',
        level: DiagLevel.warn,
      );
    }
  }

  /// Start over from the first screen: the guard re-checks the (new) database,
  /// and the `/app/me` refresh runs again so the app refetches everything.
  void _rebootstrap() {
    _diag.health.reset();
    _ref
      ..invalidate(dbGuardProvider)
      ..invalidate(meSyncProvider);
  }
}

final recoveryProvider = Provider<Recovery>(Recovery.new);
