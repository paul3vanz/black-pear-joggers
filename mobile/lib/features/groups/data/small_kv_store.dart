import '../../../core/db/app_database.dart';

/// Tiny per-account string settings, kept in the database's small key/value
/// table (`sync_cursors`), like the last-group store (D27). It is the app's
/// "localStorage": per account because there is one Drift DB per account. Used
/// for "already asked" flags and a few remembered filters, so no schema change.
class SmallKvStore {
  SmallKvStore(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async => (await (_db.select(
    _db.syncCursors,
  )..where((c) => c.key.equals(key))).getSingleOrNull())?.serverTime;

  Future<void> set(String key, String value) => _db
      .into(_db.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(key: key, serverTime: value),
      );

  Future<void> remove(String key) =>
      (_db.delete(_db.syncCursors)..where((c) => c.key.equals(key))).go();

  /// `pickGroupPrompted:<club>:<session>`: the "pick your pace group" sheet
  /// has been shown for this run on this device (D55).
  static String pickGroupKey(int clubId, String sessionId) =>
      'pickGroupPrompted:$clubId:$sessionId';

  /// `leadRosterDays:<club>`: the weekdays chosen on the Lead a run page,
  /// stored as `1,3` (Dart's `DateTime.weekday`, Monday is 1).
  static String leadDaysKey(int clubId) => 'leadRosterDays:$clubId';
}
