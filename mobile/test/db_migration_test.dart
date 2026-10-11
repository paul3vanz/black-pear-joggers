import 'package:bpj/core/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1 -> v2 adds the Phase 2 tables and keeps old rows', () async {
    // A database as Phase 1 left it: user_version 1 and only the old tables.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE memberships (member_id TEXT NOT NULL PRIMARY KEY)',
            )
            ..execute("INSERT INTO memberships VALUES ('m1')")
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(db.close);

    // The first query runs the migration.
    await db.customSelect('SELECT 1').get();
    final old = await db
        .customSelect('SELECT member_id FROM memberships')
        .get();
    expect(old, hasLength(1));

    await db
        .into(db.syncCursors)
        .insert(SyncCursorsCompanion.insert(key: 'posts:1', serverTime: 'x'));
    expect(await db.select(db.syncCursors).get(), hasLength(1));
    expect(await db.select(db.posts).get(), isEmpty);
    expect(await db.select(db.inboxItems).get(), isEmpty);
  });

  test('v2 -> v3 adds the Phase 3 tables and keeps old rows', () async {
    // A Phase 2 database: user_version 2 with an existing sync cursor.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE sync_cursors (key TEXT NOT NULL PRIMARY KEY, '
              'server_time TEXT NOT NULL)',
            )
            ..execute("INSERT INTO sync_cursors VALUES ('posts:1', 'x')")
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();
    expect(await db.select(db.syncCursors).get(), hasLength(1));
    expect(await db.select(db.venues).get(), isEmpty);
    expect(await db.select(db.sessionSeries).get(), isEmpty);
    expect(await db.select(db.sessions).get(), isEmpty);

    await db
        .into(db.venues)
        .insert(
          VenuesCompanion.insert(
            id: 'v1',
            clubId: 1,
            name: 'OECC',
            updatedAt: DateTime.utc(2026, 10, 7),
          ),
        );
    expect(await db.select(db.venues).get(), hasLength(1));
  });

  test('v3 -> v4 adds groups columns and the Phase 4 tables', () async {
    // A Phase 3 database: a sessions table without the new columns and a row.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, '
              'club_id INTEGER NOT NULL, title TEXT NOT NULL, '
              'starts_at INTEGER NOT NULL, ends_at INTEGER NOT NULL, '
              'local_date TEXT NOT NULL, local_start_time TEXT NOT NULL, '
              'local_end_time TEXT NOT NULL, group_mode TEXT NOT NULL, '
              "status TEXT NOT NULL DEFAULT 'scheduled', "
              'is_detached INTEGER NOT NULL DEFAULT 0, '
              'updated_at INTEGER NOT NULL, series_id TEXT, '
              'occurrence_date TEXT, venue_id TEXT, notes TEXT, '
              'cancel_reason TEXT, coordinator_member_id TEXT, '
              'coordinator_name TEXT, original_json TEXT)',
            )
            ..execute(
              'INSERT INTO sessions (id, club_id, title, starts_at, ends_at, '
              'local_date, local_start_time, local_end_time, group_mode, '
              "updated_at) VALUES ('s1', 1, 'Run', 1, 2, '2026-10-12', "
              "'19:00', '20:30', 'paced', 1)",
            )
            ..execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();
    final rows = await db.select(db.sessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, 'Run');
    expect(rows.single.groupsJson, isNull);
    expect(rows.single.summaryJson, isNull);
    expect(await db.select(db.sessionPlans).get(), isEmpty);
    expect(await db.select(db.myAttendance).get(), isEmpty);
    expect(await db.select(db.preferences).get(), isEmpty);

    await db
        .into(db.myAttendance)
        .insert(
          MyAttendanceCompanion.insert(
            sessionId: 's1',
            clubId: 1,
            status: 'going',
            updatedAt: DateTime.utc(2026, 10, 7),
          ),
        );
    final mine = await db.select(db.myAttendance).getSingle();
    expect(mine.pending, isFalse);
    await db
        .into(db.preferences)
        .insert(
          PreferencesCompanion.insert(
            clubId: const Value(1),
            paceUnit: 'mi',
            distanceUnit: 'km',
          ),
        );
    expect((await db.select(db.preferences).getSingle()).distanceUnit, 'km');
  });

  test('v2 -> v4 goes through v3 and ends with the same schema', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE sync_cursors (key TEXT NOT NULL PRIMARY KEY, '
              'server_time TEXT NOT NULL)',
            )
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    expect(await db.select(db.sessions).get(), isEmpty);
    expect(await db.select(db.sessionPlans).get(), isEmpty);
  });
}
