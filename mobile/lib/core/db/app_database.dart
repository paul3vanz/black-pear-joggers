import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/accounts_controller.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The local SQLite database for ONE signed-in account.
///
/// Drift ≈ Drizzle + live queries: `select(...).watch()` returns a `Stream` that emits
/// again whenever the table changes, which is how the UI stays in sync offline
/// (like a `useQuery` that re-renders on cache writes).
@DriftDatabase(
  tables: [
    Memberships,
    Profiles,
    Posts,
    InboxItems,
    SyncCursors,
    Venues,
    SessionSeries,
    Sessions,
    SessionPlans,
    MyAttendance,
    Preferences,
    GroupMessages,
    ThreadStates,
    MemberCards,
    MemberProfiles,
    EventLocations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens (creating if needed) the database file for [sub]; see [databaseNameFor].
  AppDatabase.forAccount(String sub)
    : super(driftDatabase(name: databaseNameFor(sub)));

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 (Phase 2): club updates, inbox and sync cursors.
      if (from < 2) {
        await m.createTable(posts);
        await m.createTable(inboxItems);
        await m.createTable(syncCursors);
      }
      // v3 (Phase 3): club runs schedule.
      if (from < 3) {
        await m.createTable(venues);
        await m.createTable(sessionSeries);
        await m.createTable(sessions);
      }
      // v4 (Phase 4): groups, attendance, cached plan and preferences. A v<3
      // database just created `sessions` with the new columns already.
      if (from == 3) {
        await m.addColumn(sessions, sessions.groupsJson);
        await m.addColumn(sessions, sessions.summaryJson);
      }
      if (from < 4) {
        await m.createTable(sessionPlans);
        await m.createTable(myAttendance);
        await m.createTable(preferences);
      }
      // v5 (Phase 6): group chat messages and per-thread state.
      if (from < 5) {
        await m.createTable(groupMessages);
        await m.createTable(threadStates);
      }
      // v6 (D47/D49): runs may have no end time, series/runs get an image URL. SQLite
      // can't relax NOT NULL in place, so `alterTable` rebuilds the table and copies
      // the rows across (like a SQL migration that renames, recreates and INSERT…SELECTs).
      // A database older than v3 just created these tables in their v6 shape above.
      if (from >= 3 && from < 6) {
        await m.alterTable(
          TableMigration(sessionSeries, newColumns: [sessionSeries.imageUrl]),
        );
        await m.alterTable(
          TableMigration(sessions, newColumns: [sessions.imageUrl]),
        );
      }
      // v7 (Phase 6.5): member photo/bio cards. New tables only, existing rows
      // are untouched.
      if (from < 7) {
        await m.createTable(memberCards);
        await m.createTable(memberProfiles);
      }
      // v8 (Phase 8b): club event locations (parkruns, races). A new table
      // only: existing rows are untouched, the first refresh fills it.
      if (from < 8) {
        await m.createTable(eventLocations);
      }
    },
  );

  /// Deletes every cached row (e.g. on sign-out) without removing the file.
  Future<void> clearAll() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}

/// File name (without `.sqlite`) for an account's database. A hash keeps the raw
/// Auth0 `sub` (`google-oauth2|123…`) out of file names and avoids illegal characters.
String databaseNameFor(String sub) {
  final hex = sha256.convert(utf8.encode(sub)).toString();
  return 'bpj_${hex.substring(0, 16)}';
}

/// The database for the active account. Watching [activeSubProvider] means switching
/// account disposes (closes) this database and opens the other account's file, and
/// every provider that watches this one rebuilds, so users' data never mix.
///
/// Only read this while signed in; the router guarantees that for app screens.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final sub = ref.watch(activeSubProvider);
  if (sub == null) {
    throw StateError('appDatabase read while no account is signed in');
  }
  final db = AppDatabase.forAccount(sub);
  ref.onDispose(db.close);
  return db;
}
