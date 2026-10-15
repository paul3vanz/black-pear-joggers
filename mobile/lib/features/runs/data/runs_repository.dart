import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../../../core/util/clock.dart' show localDateString;
import '../../groups/data/attendance_repository.dart';
import '../../groups/data/session_local.dart';
import 'run_dtos.dart';

// Moved to the shared clock (D87); re-exported so existing imports keep working.
export '../../../core/util/clock.dart' show localDateString;

part 'runs_repository.g.dart';

/// Cache-first club runs schedule. The UI watches the `watch*` streams; [refresh]
/// pulls venues, series and sessions (default window first, then `?since`
/// cursors) and upserts by id. Committee writes are online-only: they throw
/// `ApiException` and, on success, upsert the object the server returns.
class RunsRepository {
  RunsRepository(
    this._db,
    this._dio, {
    DateTime Function()? clock,
    String Function()? newId,
    this.flushPending,
  }) : _now = clock ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  /// Re-sends unconfirmed attendance responses before each refresh (D23).
  final Future<void> Function(int clubId)? flushPending;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Local sessions older than this many days are pruned after each refresh.
  static const pruneAfterDays = 14;

  static String sessionsCursorKey(int clubId) => 'sessions:$clubId';
  static String venuesCursorKey(int clubId) => 'venues:$clubId';
  static String seriesCursorKey(int clubId) => 'series:$clubId';

  // --- Reads -----------------------------------------------------------

  /// Sessions from [since] (a club-local `yyyy-MM-dd`, default today) onward,
  /// ordered by date then start time. The Runs providers pass the shared
  /// `clubTodayProvider` date so the filter moves on at midnight (D87).
  Stream<List<Session>> watchUpcomingSessions(int clubId, {String? since}) =>
      (_db.select(_db.sessions)
            ..where(
              (s) =>
                  s.clubId.equals(clubId) &
                  s.localDate.isBiggerOrEqualValue(
                    since ?? localDateString(_now()),
                  ),
            )
            ..orderBy([
              (s) => OrderingTerm.asc(s.localDate),
              (s) => OrderingTerm.asc(s.localStartTime),
            ]))
          .watch();

  Stream<Session?> watchSession(String id) => (_db.select(
    _db.sessions,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  Stream<Venue?> watchVenue(String id) => (_db.select(
    _db.venues,
  )..where((v) => v.id.equals(id))).watchSingleOrNull();

  Stream<List<Venue>> watchVenues(int clubId) =>
      (_db.select(_db.venues)
            ..where((v) => v.clubId.equals(clubId))
            ..orderBy([(v) => OrderingTerm.asc(v.name)]))
          .watch();

  Stream<List<RunSeries>> watchSeriesList(int clubId) =>
      (_db.select(_db.sessionSeries)
            ..where((s) => s.clubId.equals(clubId))
            ..orderBy([
              (s) => OrderingTerm.asc(s.weekday),
              (s) => OrderingTerm.asc(s.startTime),
            ]))
          .watch();

  Stream<RunSeries?> watchSeries(String id) => (_db.select(
    _db.sessionSeries,
  )..where((s) => s.id.equals(id))).watchSingleOrNull();

  // --- Sync ------------------------------------------------------------

  /// Refreshes sessions, venues and series (any linked member may read all
  /// three). Throws the first `ApiException`.
  Future<void> refresh(int clubId) async {
    try {
      await flushPending?.call(clubId);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow; // other failures: retry next time
    }
    await refreshSessions(clubId);
    await _refreshVenues(clubId);
    await _refreshSeries(clubId);
  }

  Future<String?> _cursor(String key) async => (await (_db.select(
    _db.syncCursors,
  )..where((c) => c.key.equals(key))).getSingleOrNull())?.serverTime;

  Future<void> _saveCursor(String key, String? serverTime) async {
    if (serverTime == null) return;
    await _db
        .into(_db.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(key: key, serverTime: serverTime),
        );
  }

  Future<Map<String, Object?>> _getList(String path, String? since) async {
    final response = await guardApi(
      () => _dio.get<Object?>(path, queryParameters: {'since': ?since}),
    );
    return jsonObject(response);
  }

  List<Map<String, Object?>> _items(Map<String, Object?> body) => [
    for (final item in (body['items'] as List<Object?>? ?? const []))
      Map<String, Object?>.from(item! as Map),
  ];

  /// Sessions: the first call has no `since` (the server's default window),
  /// later calls use the saved cursor. Prunes old rows afterwards.
  Future<void> refreshSessions(int clubId) async {
    final key = sessionsCursorKey(clubId);
    final body = await _getList(
      '/app/clubs/$clubId/sessions',
      await _cursor(key),
    );
    final dtos = _items(body).map(SessionDto.fromJson);
    await _db.transaction(() async {
      for (final dto in dtos) {
        if (dto.isDeleted) {
          await (_db.delete(
            _db.sessions,
          )..where((s) => s.id.equals(dto.id))).go();
        } else {
          await _db
              .into(_db.sessions)
              .insertOnConflictUpdate(dto.toCompanion(clubId));
        }
      }
      await _saveCursor(key, body['serverTime'] as String?);
      await _pruneOld(clubId);
      await _reapplyPendingAttendance(clubId);
    });
  }

  /// A response the server hasn't confirmed yet wins over the server's
  /// `summary.myStatus`, so the refresh doesn't flicker it back (D23).
  Future<void> _reapplyPendingAttendance(int clubId) async {
    final pending = await (_db.select(
      _db.myAttendance,
    )..where((a) => a.clubId.equals(clubId) & a.pending.equals(true))).get();
    final store = SessionLocalStore(_db);
    for (final row in pending) {
      await store.applyAttendance(
        row.sessionId,
        status: row.status,
        groupId: row.groupId,
      );
    }
  }

  Future<void> _pruneOld(int clubId) {
    final cutoff = localDateString(
      _now().subtract(const Duration(days: pruneAfterDays)),
    );
    return (_db.delete(_db.sessions)..where(
          (s) =>
              s.clubId.equals(clubId) & s.localDate.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  Future<void> _refreshVenues(int clubId) async {
    final key = venuesCursorKey(clubId);
    final body = await _getList(
      '/app/clubs/$clubId/venues',
      await _cursor(key),
    );
    final dtos = _items(body).map(VenueDto.fromJson);
    await _db.transaction(() async {
      for (final dto in dtos) {
        if (dto.isDeleted) {
          await (_db.delete(
            _db.venues,
          )..where((v) => v.id.equals(dto.id))).go();
        } else {
          await _db
              .into(_db.venues)
              .insertOnConflictUpdate(dto.toCompanion(clubId));
        }
      }
      await _saveCursor(key, body['serverTime'] as String?);
    });
  }

  Future<void> _refreshSeries(int clubId) async {
    final key = seriesCursorKey(clubId);
    final body = await _getList(
      '/app/clubs/$clubId/series',
      await _cursor(key),
    );
    final dtos = _items(body).map(SeriesDto.fromJson);
    await _db.transaction(() async {
      for (final dto in dtos) {
        if (dto.isDeleted) {
          await (_db.delete(
            _db.sessionSeries,
          )..where((s) => s.id.equals(dto.id))).go();
        } else {
          await _db
              .into(_db.sessionSeries)
              .insertOnConflictUpdate(dto.toCompanion(clubId));
        }
      }
      await _saveCursor(key, body['serverTime'] as String?);
    });
  }

  // --- Committee writes (online-only) -------------------------------------

  Future<Session> _upsertSession(int clubId, Response<Object?> response) async {
    final dto = SessionDto.fromJson(jsonObject(response));
    await _db
        .into(_db.sessions)
        .insertOnConflictUpdate(dto.toCompanion(clubId));
    return (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(dto.id))).getSingle();
  }

  /// Adds a one-off run (no series). The client UUID makes a retry idempotent.
  Future<Session> createAdHocSession(
    int clubId, {
    required String title,
    required String localDate,
    required String startTime,
    required int? durationMin, // null = no end time (D47)
    required String groupMode,
    String? venueId,
    String? notes,
    String? id,
  }) async => _upsertSession(
    clubId,
    await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/sessions',
        data: {
          'id': id ?? _newId(),
          'title': title,
          'localDate': localDate,
          'startTime': startTime,
          'durationMin': durationMin,
          'groupMode': groupMode,
          'venueId': venueId,
          'notes': notes,
        },
      ),
    ),
  );

  /// Edits this occurrence only (detaches it from its series). [localDate] is
  /// only accepted by the server for ad-hoc runs. With [setCoordinator] the
  /// coordinator is sent too: a member id, or null to clear it.
  Future<Session> updateSession(
    int clubId,
    String id, {
    required String title,
    required String startTime,
    required int? durationMin, // null = no end time (D47)
    String? venueId,
    String? notes,
    String? localDate,
    bool setCoordinator = false,
    String? coordinatorMemberId,
  }) async => _upsertSession(
    clubId,
    await guardApi(
      () => _dio.patch<Object?>(
        '/app/clubs/$clubId/sessions/$id',
        data: {
          'title': title,
          'startTime': startTime,
          'durationMin': durationMin,
          'venueId': venueId,
          'notes': notes,
          'localDate': ?localDate,
          if (setCoordinator) 'coordinatorMemberId': coordinatorMemberId,
        },
      ),
    ),
  );

  Future<Session> cancelSession(int clubId, String id, String reason) async =>
      _upsertSession(
        clubId,
        await guardApi(
          () => _dio.post<Object?>(
            '/app/clubs/$clubId/sessions/$id/cancel',
            data: {'reason': reason},
          ),
        ),
      );

  Future<Session> restoreSession(int clubId, String id) async => _upsertSession(
    clubId,
    await guardApi(
      () => _dio.post<Object?>('/app/clubs/$clubId/sessions/$id/restore'),
    ),
  );

  /// Ad-hoc runs only; the server answers 409 `series_session` otherwise.
  Future<void> deleteAdHocSession(int clubId, String id) async {
    await guardApi(
      () => _dio.delete<Object?>('/app/clubs/$clubId/sessions/$id'),
    );
    await (_db.delete(_db.sessions)..where((s) => s.id.equals(id))).go();
  }

  Future<Venue> _upsertVenue(int clubId, Response<Object?> response) async {
    final dto = VenueDto.fromJson(jsonObject(response));
    await _db.into(_db.venues).insertOnConflictUpdate(dto.toCompanion(clubId));
    return (_db.select(
      _db.venues,
    )..where((v) => v.id.equals(dto.id))).getSingle();
  }

  Map<String, Object?> _venueBody({
    required String name,
    String? address,
    double? lat,
    double? lng,
    String? notes,
  }) => {
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'notes': notes,
  };

  Future<Venue> createVenue(
    int clubId, {
    required String name,
    String? address,
    double? lat,
    double? lng,
    String? notes,
    String? id,
  }) async => _upsertVenue(
    clubId,
    await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/venues',
        data: {
          'id': id ?? _newId(),
          ..._venueBody(
            name: name,
            address: address,
            lat: lat,
            lng: lng,
            notes: notes,
          ),
        },
      ),
    ),
  );

  Future<Venue> updateVenue(
    int clubId,
    String id, {
    required String name,
    String? address,
    double? lat,
    double? lng,
    String? notes,
  }) async => _upsertVenue(
    clubId,
    await guardApi(
      () => _dio.patch<Object?>(
        '/app/clubs/$clubId/venues/$id',
        data: _venueBody(
          name: name,
          address: address,
          lat: lat,
          lng: lng,
          notes: notes,
        ),
      ),
    ),
  );

  /// 409 `in_use` if an active series or future session uses the venue.
  Future<void> deleteVenue(int clubId, String id) async {
    await guardApi(() => _dio.delete<Object?>('/app/clubs/$clubId/venues/$id'));
    await (_db.delete(_db.venues)..where((v) => v.id.equals(id))).go();
  }

  Future<RunSeries> _upsertSeries(
    int clubId,
    Response<Object?> response,
  ) async {
    final dto = SeriesDto.fromJson(jsonObject(response));
    await _db
        .into(_db.sessionSeries)
        .insertOnConflictUpdate(dto.toCompanion(clubId));
    final row = await (_db.select(
      _db.sessionSeries,
    )..where((s) => s.id.equals(dto.id))).getSingle();
    await _refreshSessionsQuietly(clubId);
    return row;
  }

  /// The server regenerates a series' sessions on every series write; pull them
  /// in. A failure here is ignored: the write itself succeeded and the next
  /// refresh picks the sessions up.
  Future<void> _refreshSessionsQuietly(int clubId) async {
    try {
      await refreshSessions(clubId);
    } on Object {
      // Offline right after a write: the Runs tab refreshes later.
    }
  }

  Map<String, Object?> _seriesBody({
    required String title,
    String? description,
    String? venueId,
    required int weekday,
    required String startTime,
    required int? durationMin, // null = no end time (D47)
    required int intervalWeeks,
    required String validFrom,
    String? validUntil,
    required String groupMode,
    String? cmsSlug,
    String? imageUrl, // null clears the series image (D49)
  }) => {
    'title': title,
    'description': description,
    'venueId': venueId,
    'weekday': weekday,
    'startTime': startTime,
    'durationMin': durationMin,
    'intervalWeeks': intervalWeeks,
    'validFrom': validFrom,
    'validUntil': validUntil,
    'groupMode': groupMode,
    'cmsSlug': cmsSlug,
    'imageUrl': imageUrl,
  };

  Future<RunSeries> createSeries(
    int clubId, {
    required String title,
    String? description,
    String? venueId,
    required int weekday,
    required String startTime,
    required int? durationMin, // null = no end time (D47)
    required int intervalWeeks,
    required String validFrom,
    String? validUntil,
    required String groupMode,
    String? cmsSlug,
    String? imageUrl, // null clears the series image (D49)
    String? id,
  }) async => _upsertSeries(
    clubId,
    await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/series',
        data: {
          'id': id ?? _newId(),
          ..._seriesBody(
            title: title,
            description: description,
            venueId: venueId,
            weekday: weekday,
            startTime: startTime,
            durationMin: durationMin,
            intervalWeeks: intervalWeeks,
            validFrom: validFrom,
            validUntil: validUntil,
            groupMode: groupMode,
            cmsSlug: cmsSlug,
            imageUrl: imageUrl,
          ),
        },
      ),
    ),
  );

  Future<RunSeries> updateSeries(
    int clubId,
    String id, {
    required String title,
    String? description,
    String? venueId,
    required int weekday,
    required String startTime,
    required int? durationMin, // null = no end time (D47)
    required int intervalWeeks,
    required String validFrom,
    String? validUntil,
    required String groupMode,
    String? cmsSlug,
    String? imageUrl, // null clears the series image (D49)
  }) async => _upsertSeries(
    clubId,
    await guardApi(
      () => _dio.patch<Object?>(
        '/app/clubs/$clubId/series/$id',
        data: _seriesBody(
          title: title,
          description: description,
          venueId: venueId,
          weekday: weekday,
          startTime: startTime,
          durationMin: durationMin,
          intervalWeeks: intervalWeeks,
          validFrom: validFrom,
          validUntil: validUntil,
          groupMode: groupMode,
          cmsSlug: cmsSlug,
          imageUrl: imageUrl,
        ),
      ),
    ),
  );

  Future<void> deleteSeries(int clubId, String id) async {
    await guardApi(() => _dio.delete<Object?>('/app/clubs/$clubId/series/$id'));
    await (_db.delete(_db.sessionSeries)..where((s) => s.id.equals(id))).go();
    await _refreshSessionsQuietly(clubId);
  }
}

@Riverpod(keepAlive: true)
RunsRepository runsRepository(Ref ref) {
  final attendance = ref.watch(attendanceRepositoryProvider);
  return RunsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
    flushPending: attendance.retryPending,
  );
}
