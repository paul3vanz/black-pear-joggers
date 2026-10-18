import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/events/data/event_locations_repository.dart';
import 'package:bpj/features/groups/data/attendance_repository.dart';
import 'package:bpj/features/groups/data/groups_repository.dart';
import 'package:bpj/features/groups/data/plan_repository.dart';
import 'package:bpj/features/groups/data/run_preferences_repository.dart';
import 'package:bpj/features/inbox/data/inbox_repository.dart';
import 'package:bpj/features/members/data/member_profile_repository.dart';
import 'package:bpj/features/membership/data/membership_repository.dart';
import 'package:bpj/features/messages/data/messages_repository.dart';
import 'package:bpj/features/profile/data/profile_repository.dart';
import 'package:bpj/features/runs/data/runs_repository.dart';
import 'package:bpj/features/standards/data/standards_repository.dart';
import 'package:bpj/features/updates/data/posts_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fake_api_phase9.dart';

/// Upgrade tests against REAL on-disk databases written by the OLD code of each
/// shipped schema version (see "Upgrade testing" in mobile/README.md and
/// test/fixtures/db/generate_fixture.dart.txt). Every schema bump must add a
/// fixture here (or extend these tests), because a user who updates through
/// Google Play skips straight from whatever version they had to the new one.
///
/// `v6.sqlite` was made by `b65ca58` (Phase 6, schemaVersion 6): no commit ever
/// wrote schemaVersion 5.
const _fixtures = <String, int>{
  'v4.sqlite': 4,
  'v6.sqlite': 6,
  'v7.sqlite': 7,
  'v8.sqlite': 8,
  'v9.sqlite': 9,
  'v10.sqlite': 10,
};

const _currentVersion = 11;

/// Which tables each old schema had, so the test can check row counts survive.
const _clubId = 1;

Future<int> _userVersion(AppDatabase db) async =>
    (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
      'user_version',
    );

Future<void> _expectHealthy(AppDatabase db) async {
  expect(await _userVersion(db), _currentVersion);
  final integrity = await db.customSelect('PRAGMA integrity_check').get();
  expect(integrity.map((r) => r.data.values.first), ['ok']);
  // Selecting every column of every table fails on a missing column/table.
  for (final table in db.allTables) {
    await db.select(table).get();
  }
  // And every table Drift expects exists in the file.
  final names = {
    for (final r
        in await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get())
      r.read<String>('name'),
  };
  for (final table in db.allTables) {
    expect(names, contains(table.actualTableName));
  }
}

/// One dio that answers every route the startup repositories call with the
/// smallest valid body.
class _AnyAdapter implements HttpClientAdapter {
  final requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    final path = options.path;
    final Object body;
    if (path == '/app/me') {
      body = meJson([membershipJson()]);
    } else if (path.endsWith('/profile')) {
      body = profileJson();
    } else if (path.endsWith('/preferences')) {
      body = {'paceUnit': 'mile', 'distanceUnit': 'mile'};
    } else if (path.endsWith('/standards')) {
      body = standardsJson();
    } else if (path.endsWith('/member-profile')) {
      body = {'memberId': 'mem_8f21', 'displayName': 'Sam Taylor'};
    } else {
      body = {
        'items': <Object?>[],
        'serverTime': '2026-10-17T09:00:00+00:00',
        'unreadCount': 0,
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Starts every `watch*` stream the app opens at startup and waits for the
/// first value, then runs one `refresh()` of each repository.
Future<void> _exerciseRepositories(AppDatabase db) async {
  final adapter = _AnyAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'))
    ..httpClientAdapter = adapter;
  Future<void> first<T>(Stream<T> s) => s.first.timeout(
    const Duration(seconds: 5),
    onTimeout: () => throw TimeoutException('stream gave no value'),
  );

  final memberships = MembershipRepository(db, dio);
  final profiles = ProfileRepository(db, dio);
  final posts = PostsRepository(db, dio);
  final inbox = InboxRepository(db, dio);
  final runs = RunsRepository(db, dio);
  final groups = GroupsRepository(db, dio);
  final attendance = AttendanceRepository(db, dio);
  final plans = PlanRepository(db, dio);
  final prefs = RunPreferencesRepository(db, dio);
  final messages = MessagesRepository(db, dio);
  final members = MemberProfileRepository(db, dio);
  final events = EventLocationsRepository(db, dio);
  final standards = StandardsRepository(db, dio);

  await first(memberships.watchMemberships());
  await first(profiles.watchProfile(_clubId));
  await first(posts.watchPosts(_clubId));
  await first(posts.watchPost('post_01'));
  await first(inbox.watchInbox(_clubId));
  await first(inbox.watchUnreadCount(_clubId));
  await first(runs.watchUpcomingSessions(_clubId, since: '2000-01-01'));
  await first(runs.watchSession('ses_100'));
  await first(runs.watchVenues(_clubId));
  await first(runs.watchVenue('ven_1'));
  await first(runs.watchSeriesList(_clubId));
  await first(runs.watchSeries('ser_1'));
  await first(groups.watchGroups('ses_100'));
  await first(attendance.watchMyAttendance('ses_100'));
  await first(plans.watchPlan('ses_100'));
  await first(prefs.watch(_clubId));
  await first(messages.watchThread('grp_a'));
  await first(messages.watchThreadState('grp_a'));
  await first(messages.watchThreads(_clubId));
  await first(members.watchCard('mem_8f21'));
  await first(members.watchCards(_clubId));
  await first(members.watchProfile(_clubId, 'mem_8f21'));
  await first(members.watchMine(_clubId));
  await first(events.watch(_clubId));
  await first(standards.watch(_clubId));

  await memberships.refreshMe();
  await profiles.refreshProfile(_clubId);
  await posts.refresh(_clubId);
  await inbox.refresh(_clubId);
  await runs.refresh(_clubId);
  await prefs.refresh(_clubId);
  await messages.refreshThreads(_clubId);
  await messages.refresh(_clubId, 'grp_a');
  await members.refreshCards(_clubId);
  await events.refresh(_clubId);
  await standards.refresh(_clubId);

  expect(adapter.requests, isNotEmpty);
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('bpj_upgrade_');
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File copyFixture(String name) {
    final src = File('test/fixtures/db/$name');
    expect(src.existsSync(), isTrue, reason: 'missing fixture $name');
    return src.copySync('${tmp.path}/$name');
  }

  for (final entry in _fixtures.entries) {
    group('upgrade from ${entry.key}', () {
      test('opens, migrates to $_currentVersion, every table and repository '
          'works, and a second open is clean', () async {
        final file = copyFixture(entry.key);

        // Row counts and version as the OLD code left them, read in `setup`,
        // which runs before Drift's migration.
        final before = <String, int>{};
        var versionBefore = -1;
        var db = AppDatabase(
          NativeDatabase(
            file,
            setup: (raw) {
              versionBefore =
                  raw.select('PRAGMA user_version').first.values.first! as int;
              for (final t in raw.select(
                "SELECT name FROM sqlite_master WHERE type='table' "
                "AND name NOT LIKE 'sqlite_%'",
              )) {
                final n = t['name'] as String;
                before[n] =
                    raw.select('SELECT count(*) AS c FROM $n').first['c']!
                        as int;
              }
            },
          ),
        );
        expect(versionBefore, -1, reason: 'not opened yet');
        await db.customSelect('SELECT 1').get();
        expect(versionBefore, entry.value, reason: 'fixture version');
        expect(before, isNotEmpty);
        for (final e in before.entries) {
          expect(e.value, greaterThan(0), reason: '${e.key} fixture is empty');
        }

        await _expectHealthy(db);

        // No row of any old table was lost by the migration.
        for (final e in before.entries) {
          final n =
              (await db
                      .customSelect('SELECT count(*) AS c FROM ${e.key}')
                      .getSingle())
                  .read<int>('c');
          expect(n, e.value, reason: 'rows kept in ${e.key}');
        }

        // The rich rows are readable through the Drift row classes (types and
        // nullability), and the pre-v6 NOT NULL end time came through intact.
        final session = await (db.select(
          db.sessions,
        )..where((s) => s.id.equals('ses_100'))).getSingle();
        expect(session.localEndTime, '20:00');
        expect(session.groupsJson, isNotNull);
        expect(session.imageUrl, isNull);
        final series = await db.select(db.sessionSeries).get();
        expect(series.map((s) => s.durationMin), containsAll([75, 120]));
        // v11 (D115): run days arrive empty ("never chosen"); v10's lead days
        // survive.
        final prefs = await db.select(db.preferences).getSingle();
        expect(prefs.runDays, isNull);
        expect(prefs.leadDays, entry.value >= 10 ? '2,4' : isNull);

        await db.close();

        // Re-open the migrated file: no migration this time, same data.
        db = AppDatabase(NativeDatabase(file));
        addTearDown(db.close);
        await _expectHealthy(db);
        for (final e in before.entries) {
          final n =
              (await db
                      .customSelect('SELECT count(*) AS c FROM ${e.key}')
                      .getSingle())
                  .read<int>('c');
          expect(n, e.value, reason: 'rows kept in ${e.key} after reopen');
        }

        // Startup repositories: streams emit and one refresh each succeeds
        // (a refresh may legitimately prune or replace cached rows).
        await _exerciseRepositories(db);
      });
    });
  }

  test(
    'a brand new (user_version 0) file is created at the current schema',
    () async {
      final file = File('${tmp.path}/fresh.sqlite');
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await _expectHealthy(db);
      await _exerciseRepositories(db);
    },
  );

  test('a current-version file written by this code reopens cleanly', () async {
    final file = File('${tmp.path}/current.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db
        .into(db.syncCursors)
        .insert(SyncCursorsCompanion.insert(key: 'posts:1', serverTime: 'x'));
    await _expectHealthy(db);
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await _expectHealthy(db);
    expect(await db.select(db.syncCursors).get(), hasLength(1));
    await _exerciseRepositories(db);
  });

  test('current schema equals what the generated code declares', () async {
    // Guards the fixtures themselves: if the schema moves on, this reminds the
    // developer to add a fixture for the version that just shipped.
    final db = memoryDb();
    addTearDown(db.close);
    expect(db.schemaVersion, _currentVersion);
    expect(
      _fixtures.values.reduce((a, b) => a > b ? a : b),
      _currentVersion - 1,
      reason:
          'Schema is v${db.schemaVersion}: add test/fixtures/db/v'
          '${db.schemaVersion - 1}.sqlite (and update _currentVersion) so the '
          'previous version has an upgrade test.',
    );
  });
}
