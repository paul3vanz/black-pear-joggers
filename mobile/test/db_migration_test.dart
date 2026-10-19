import 'package:bpj/core/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `session_series` table as v3-v5 had it (duration NOT NULL, no image).
const _oldSeriesSql =
    'CREATE TABLE session_series (id TEXT NOT NULL PRIMARY KEY, '
    'club_id INTEGER NOT NULL, title TEXT NOT NULL, description TEXT, '
    'venue_id TEXT, weekday INTEGER NOT NULL, start_time TEXT NOT NULL, '
    'duration_min INTEGER NOT NULL, '
    'interval_weeks INTEGER NOT NULL DEFAULT 1, valid_from TEXT NOT NULL, '
    'valid_until TEXT, group_mode TEXT NOT NULL, cms_slug TEXT, '
    'updated_at INTEGER NOT NULL)';

/// The `sessions` table as v4-v5 had it (end time NOT NULL, no image).
const _oldSessionsSql =
    'CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, '
    'club_id INTEGER NOT NULL, series_id TEXT, occurrence_date TEXT, '
    'title TEXT NOT NULL, venue_id TEXT, notes TEXT, '
    'starts_at INTEGER NOT NULL, ends_at INTEGER NOT NULL, '
    'local_date TEXT NOT NULL, local_start_time TEXT NOT NULL, '
    'local_end_time TEXT NOT NULL, group_mode TEXT NOT NULL, '
    "status TEXT NOT NULL DEFAULT 'scheduled', cancel_reason TEXT, "
    'coordinator_member_id TEXT, coordinator_name TEXT, '
    'is_detached INTEGER NOT NULL DEFAULT 0, original_json TEXT, '
    'groups_json TEXT, summary_json TEXT, updated_at INTEGER NOT NULL)';

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
            ..execute(_oldSeriesSql)
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

  test('v4 -> v5 adds the chat tables and keeps existing data', () async {
    // A Phase 5 database: a sync cursor and a cached run, user_version 4.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE sync_cursors (key TEXT NOT NULL PRIMARY KEY, '
              'server_time TEXT NOT NULL)',
            )
            ..execute("INSERT INTO sync_cursors VALUES ('sessions:1', 'x')")
            ..execute(_oldSeriesSql)
            ..execute(_oldSessionsSql)
            ..execute('PRAGMA user_version = 4');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();
    expect(await db.select(db.syncCursors).get(), hasLength(1));
    expect(await db.select(db.groupMessages).get(), isEmpty);
    expect(await db.select(db.threadStates).get(), isEmpty);

    await db
        .into(db.groupMessages)
        .insert(
          GroupMessagesCompanion.insert(
            id: 'm1',
            clubId: 1,
            groupId: 'g1',
            memberId: 'me',
            authorName: 'Jo B.',
            body: 'Hi',
            createdAt: DateTime.utc(2026, 10, 12),
          ),
        );
    final row = await db.select(db.groupMessages).getSingle();
    expect(row.sendState, 'sent');
    expect(row.authorRole, 'member');
    await db
        .into(db.threadStates)
        .insert(ThreadStatesCompanion.insert(groupId: 'g1', clubId: 1));
    final thread = await db.select(db.threadStates).getSingle();
    expect(thread.unreadCount, 0);
    expect(thread.muted, isFalse);
    expect(thread.closed, isFalse);
  });

  test('v5 -> v6 keeps runs, allows no end time and adds image URLs', () async {
    // A v5 database: one series and one run with an end time, as the app stored them.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(_oldSeriesSql)
            ..execute(_oldSessionsSql)
            ..execute(
              'INSERT INTO session_series (id, club_id, title, weekday, '
              'start_time, duration_min, valid_from, group_mode, updated_at) '
              "VALUES ('s1', 1, 'Monday run', 1, '19:00', 90, '2026-01-01', "
              "'paced', 1)",
            )
            ..execute(
              'INSERT INTO sessions (id, club_id, series_id, title, '
              'starts_at, ends_at, local_date, local_start_time, '
              'local_end_time, group_mode, groups_json, updated_at) '
              "VALUES ('r1', 1, 's1', 'Monday run', 1, 2, '2026-10-12', "
              "'19:00', '20:30', 'paced', '[]', 1)",
            )
            ..execute('PRAGMA user_version = 5');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    // Existing rows survive with their values; the new columns start null.
    final series = await db.select(db.sessionSeries).getSingle();
    expect(series.title, 'Monday run');
    expect(series.durationMin, 90);
    expect(series.imageUrl, isNull);
    final run = await db.select(db.sessions).getSingle();
    expect(run.localEndTime, '20:30');
    expect(run.groupsJson, '[]');
    expect(run.imageUrl, isNull);

    // The relaxed columns now accept null and the image columns accept a URL.
    await (db.update(db.sessionSeries)).write(
      const SessionSeriesCompanion(
        durationMin: Value(null),
        imageUrl: Value('https://bpj.org.uk/a.jpg'),
      ),
    );
    await (db.update(db.sessions)).write(
      const SessionsCompanion(
        localEndTime: Value(null),
        imageUrl: Value('https://bpj.org.uk/a.jpg'),
      ),
    );
    expect((await db.select(db.sessionSeries).getSingle()).durationMin, isNull);
    final updated = await db.select(db.sessions).getSingle();
    expect(updated.localEndTime, isNull);
    expect(updated.imageUrl, 'https://bpj.org.uk/a.jpg');
  });

  test(
    'v6 -> v7 adds the member card tables and keeps existing data',
    () async {
      // A v6 database: a chat message and a membership, as Phase 6 left them.
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw
              ..execute(
                'CREATE TABLE group_messages (id TEXT NOT NULL PRIMARY KEY, '
                'club_id INTEGER NOT NULL, group_id TEXT NOT NULL, '
                'member_id TEXT NOT NULL, author_name TEXT NOT NULL, '
                "author_role TEXT NOT NULL DEFAULT 'member', "
                'body TEXT NOT NULL, created_at INTEGER NOT NULL, '
                'deleted_at INTEGER, '
                "send_state TEXT NOT NULL DEFAULT 'sent')",
              )
              ..execute(
                'INSERT INTO group_messages (id, club_id, group_id, member_id, '
                "author_name, body, created_at) VALUES ('m1', 1, 'g1', 'sam', "
                "'Sam B.', 'Hello', 1)",
              )
              ..execute('PRAGMA user_version = 6');
          },
        ),
      );
      addTearDown(db.close);

      await db.customSelect('SELECT 1').get();

      // Existing data survives.
      expect((await db.select(db.groupMessages).getSingle()).body, 'Hello');

      // The new tables exist and work.
      expect(await db.select(db.memberCards).get(), isEmpty);
      expect(await db.select(db.memberProfiles).get(), isEmpty);
      await db
          .into(db.memberCards)
          .insert(
            MemberCardsCompanion.insert(
              memberId: 'sam',
              clubId: 1,
              displayName: 'Sam B.',
            ),
          );
      await db
          .into(db.memberProfiles)
          .insert(
            MemberProfilesCompanion.insert(
              memberId: 'sam',
              clubId: 1,
              json: '{}',
              fetchedAt: DateTime.utc(2026, 10, 12),
            ),
          );
      final card = await db.select(db.memberCards).getSingle();
      expect(card.rolesCsv, '');
      expect(card.hasBio, isFalse);
      expect(card.photoPath, isNull);
      expect(await db.select(db.memberProfiles).get(), hasLength(1));
    },
  );

  test('v7 -> v8 adds event locations and keeps existing data', () async {
    // A v7 database: a cached venue and a sync cursor, as Phase 6.5 left them.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE venues (id TEXT NOT NULL PRIMARY KEY, '
              'club_id INTEGER NOT NULL, name TEXT NOT NULL, address TEXT, '
              'lat REAL, lng REAL, notes TEXT, updated_at INTEGER NOT NULL)',
            )
            ..execute(
              "INSERT INTO venues VALUES ('v1', 1, 'OECC', NULL, NULL, NULL, NULL, 1)",
            )
            ..execute(
              'CREATE TABLE sync_cursors (key TEXT NOT NULL PRIMARY KEY, '
              'server_time TEXT NOT NULL)',
            )
            ..execute("INSERT INTO sync_cursors VALUES ('venues:1', 'x')")
            ..execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    // Existing data survives.
    expect((await db.select(db.venues).getSingle()).name, 'OECC');
    expect(await db.select(db.syncCursors).get(), hasLength(1));

    // The new table exists, accepts a row and applies its defaults.
    expect(await db.select(db.eventLocations).get(), isEmpty);
    await db
        .into(db.eventLocations)
        .insert(
          EventLocationsCompanion.insert(
            id: 'e1',
            clubId: 1,
            kind: 'parkrun',
            name: 'Worcester parkrun',
            updatedAt: DateTime.utc(2026, 10, 13),
          ),
        );
    final row = await db.select(db.eventLocations).getSingle();
    expect(row.source, 'manual');
    expect(row.slug, isNull);
    expect(row.deletedAt, isNull);
  });

  test('v8 -> v9 adds the standards cache and keeps existing data', () async {
    // A v8 database: an event location and a sync cursor, as Phase 8b left them.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE event_locations (id TEXT NOT NULL PRIMARY KEY, '
              'club_id INTEGER NOT NULL, kind TEXT NOT NULL, '
              'name TEXT NOT NULL, slug TEXT, country TEXT, region TEXT, '
              'lat REAL, lng REAL, url TEXT, '
              "source TEXT NOT NULL DEFAULT 'manual', "
              'updated_at INTEGER NOT NULL, deleted_at INTEGER)',
            )
            ..execute(
              'INSERT INTO event_locations (id, club_id, kind, name, updated_at) '
              "VALUES ('e1', 1, 'parkrun', 'Worcester parkrun', 1)",
            )
            ..execute(
              'CREATE TABLE sync_cursors (key TEXT NOT NULL PRIMARY KEY, '
              'server_time TEXT NOT NULL)',
            )
            ..execute(
              "INSERT INTO sync_cursors VALUES ('eventLocations:1', 'x')",
            )
            ..execute('PRAGMA user_version = 8');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    // Existing data survives.
    expect(
      (await db.select(db.eventLocations).getSingle()).name,
      'Worcester parkrun',
    );
    expect(await db.select(db.syncCursors).get(), hasLength(1));

    // The new table exists, is empty and accepts a row.
    expect(await db.select(db.standardsCache).get(), isEmpty);
    await db
        .into(db.standardsCache)
        .insert(
          StandardsCacheCompanion.insert(
            clubId: const Value(1),
            bodyJson: '{}',
            fetchedAt: DateTime.utc(2026, 10, 15),
          ),
        );
    final row = await db.select(db.standardsCache).getSingle();
    expect(row.etag, isNull);
    expect(row.bodyJson, '{}');
  });

  test('v9 -> v10 adds preferences.lead_days and keeps existing data', () async {
    // A v9 database: the preferences row as the last release stored it.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE preferences (club_id INTEGER NOT NULL PRIMARY KEY, '
              'pace_unit TEXT NOT NULL, distance_unit TEXT NOT NULL, '
              'pace_from_s INTEGER, pace_to_s INTEGER, updated_at INTEGER)',
            )
            ..execute(
              'INSERT INTO preferences (club_id, pace_unit, distance_unit, '
              "pace_from_s, pace_to_s, updated_at) VALUES (1, 'km', 'mi', 330, 360, 1)",
            )
            ..execute('PRAGMA user_version = 9');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    // The row survives; lead_days is null = "never chosen".
    final row = await db.select(db.preferences).getSingle();
    expect(row.paceUnit, 'km');
    expect(row.paceFromS, 330);
    expect(row.leadDays, isNull);

    // The column accepts "none" ('') and a list.
    await (db.update(db.preferences)..where((p) => p.clubId.equals(1))).write(
      const PreferencesCompanion(leadDays: Value('')),
    );
    expect((await db.select(db.preferences).getSingle()).leadDays, '');
    await (db.update(db.preferences)..where((p) => p.clubId.equals(1))).write(
      const PreferencesCompanion(leadDays: Value('2,4')),
    );
    expect((await db.select(db.preferences).getSingle()).leadDays, '2,4');
  });

  test('v10 -> v11 adds preferences.run_days and keeps lead_days', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE preferences (club_id INTEGER NOT NULL PRIMARY KEY, '
              'pace_unit TEXT NOT NULL, distance_unit TEXT NOT NULL, '
              'pace_from_s INTEGER, pace_to_s INTEGER, lead_days TEXT, '
              'updated_at INTEGER)',
            )
            ..execute(
              'INSERT INTO preferences (club_id, pace_unit, distance_unit, '
              "lead_days, updated_at) VALUES (1, 'mi', 'mi', '1', 1)",
            )
            ..execute('PRAGMA user_version = 10');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    final row = await db.select(db.preferences).getSingle();
    expect(row.leadDays, '1');
    expect(row.runDays, isNull);
    await (db.update(db.preferences)..where((p) => p.clubId.equals(1))).write(
      const PreferencesCompanion(runDays: Value('1,3')),
    );
    expect((await db.select(db.preferences).getSingle()).runDays, '1,3');
  });

  test('v11 -> v12 adds series_follows and keeps the preferences', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE preferences (club_id INTEGER NOT NULL PRIMARY KEY, '
              'pace_unit TEXT NOT NULL, distance_unit TEXT NOT NULL, '
              'pace_from_s INTEGER, pace_to_s INTEGER, lead_days TEXT, '
              'run_days TEXT, updated_at INTEGER)',
            )
            ..execute(
              'INSERT INTO preferences (club_id, pace_unit, distance_unit, '
              "lead_days, run_days, updated_at) VALUES (1, 'mi', 'mi', '1', "
              "'1,3', 1)",
            )
            ..execute('PRAGMA user_version = 11');
        },
      ),
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    expect((await db.select(db.preferences).getSingle()).runDays, '1,3');
    expect(await db.select(db.seriesFollows).get(), isEmpty);
    await db
        .into(db.seriesFollows)
        .insert(
          SeriesFollowsCompanion.insert(
            seriesId: 's1',
            clubId: 1,
            title: 'Monday club run',
            weekday: 1,
            localStartTime: '19:00',
            groupMode: 'paced',
            mode: 'hide',
            fetchedAt: DateTime(2026, 10, 19),
          ),
        );
    final row = await db.select(db.seriesFollows).getSingle();
    expect((row.mode, row.usuallyComes), ('hide', false));
  });

  test('a fresh database is created at schema v12', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 12);
    await db.customSelect('SELECT 1').get();
    expect(await db.select(db.sessions).get(), isEmpty);
    expect(await db.select(db.seriesFollows).get(), isEmpty);
  });
}
