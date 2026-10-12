import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../../runs/data/runs_repository.dart' show localDateString;
import '../logic/recent_events.dart';
import 'event_dtos.dart';

part 'event_locations_repository.g.dart';

/// Cache-first club event locations (parkruns, races: Phase 8, D78). The UI
/// watches [watch]; [refresh] pulls the list with a `?since=` cursor (about 800
/// rows the first time, then only changes and tombstones). Writes need a
/// connection (D16/D19): they throw `ApiException` and, on success, upsert the
/// row the server returns.
class EventLocationsRepository {
  EventLocationsRepository(
    this._db,
    this._dio, {
    String Function()? newId,
    DateTime Function()? clock,
  }) : _newId = newId ?? (() => const Uuid().v4()),
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final String Function() _newId;
  final DateTime Function() _now;

  static String cursorKey(int clubId) => 'eventLocations:$clubId';

  String _path(int clubId) => '/app/clubs/$clubId/event-locations';

  // --- Reads -----------------------------------------------------------

  /// Live (not deleted) locations of the club, ordered by name.
  Stream<List<EventLocation>> watch(int clubId) =>
      (_db.select(_db.eventLocations)
            ..where((l) => l.clubId.equals(clubId) & l.deletedAt.isNull())
            ..orderBy([(l) => OrderingTerm.asc(l.name)]))
          .watch();

  /// Location ids used by the club's event groups in the cached runs of the
  /// last [weeks] weeks, most used first (the picker's "Recently used" list).
  /// Read from the cached sessions' embedded groups, so it works offline.
  Future<List<String>> recentLocationIds(
    int clubId, {
    int weeks = recentEventWeeks,
  }) async {
    final since = localDateString(_now().subtract(Duration(days: weeks * 7)));
    final sessions =
        await (_db.select(_db.sessions)..where(
              (s) =>
                  s.clubId.equals(clubId) &
                  s.localDate.isBiggerOrEqualValue(since),
            ))
            .get();
    return rankRecentLocationIds(sessions, sinceDate: since);
  }

  /// Location ids already on the event groups of [sessionId] (from the cache).
  Future<Set<String>> locationIdsOnSession(String sessionId) async =>
      locationIdsOnSessionRow(
        await (_db.select(
          _db.sessions,
        )..where((s) => s.id.equals(sessionId))).getSingleOrNull(),
      );

  // --- Sync ------------------------------------------------------------

  /// Merges the server's changes into the cache. The first call has no `since`
  /// (every live row); later calls send the saved cursor and receive changed
  /// rows plus tombstones (kept locally with `deletedAt` set).
  Future<void> refresh(int clubId) async {
    final key = cursorKey(clubId);
    final cursor = await (_db.select(
      _db.syncCursors,
    )..where((c) => c.key.equals(key))).getSingleOrNull();
    final response = await guardApi(
      () => _dio.get<Object?>(
        _path(clubId),
        queryParameters: {'since': ?cursor?.serverTime},
      ),
    );
    final body = jsonObject(response);
    final dtos = [
      for (final item in (body['items'] as List<Object?>? ?? const []))
        EventLocationDto.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
    final serverTime = body['serverTime'] as String?;
    // One transaction (and so one stream emission) for the whole list; a batch
    // keeps ~800 inserts fast.
    await _db.transaction(() async {
      await _db.batch((b) {
        for (final dto in dtos) {
          b.insert(
            _db.eventLocations,
            dto.toCompanion(clubId),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      if (serverTime != null) {
        await _db
            .into(_db.syncCursors)
            .insertOnConflictUpdate(
              SyncCursorsCompanion.insert(key: key, serverTime: serverTime),
            );
      }
    });
  }

  // --- Writes (online-only) ----------------------------------------------

  Future<EventLocation> _upsert(int clubId, Response<Object?> response) async {
    final dto = EventLocationDto.fromJson(jsonObject(response));
    await _db
        .into(_db.eventLocations)
        .insertOnConflictUpdate(dto.toCompanion(clubId));
    return (_db.select(
      _db.eventLocations,
    )..where((l) => l.id.equals(dto.id))).getSingle();
  }

  /// Adds a location. Any linked member may add `race`/`other`; `parkrun` is
  /// committee-only (403). The client UUID makes a retry idempotent. If the
  /// club already has a location with the same kind and name, the server
  /// answers 200 with that existing row (not 201); that row is cached and
  /// returned, so callers can use the result either way.
  Future<EventLocation> create(
    int clubId, {
    String kind = 'other',
    required String name,
    String? region,
    double? lat,
    double? lng,
    String? url,
    String? id,
  }) async => _upsert(
    clubId,
    await guardApi(
      () => _dio.post<Object?>(
        _path(clubId),
        data: {
          'id': id ?? _newId(),
          'kind': kind,
          'name': name,
          'region': region,
          'lat': lat,
          'lng': lng,
          'url': url,
        },
      ),
    ),
  );

  /// Committee/admin only.
  Future<EventLocation> update(
    int clubId,
    String id, {
    required String kind,
    required String name,
    String? region,
    double? lat,
    double? lng,
    String? url,
  }) async => _upsert(
    clubId,
    await guardApi(
      () => _dio.patch<Object?>(
        '${_path(clubId)}/$id',
        data: {
          'kind': kind,
          'name': name,
          'region': region,
          'lat': lat,
          'lng': lng,
          'url': url,
        },
      ),
    ),
  );

  /// Committee/admin only. Groups already using the location keep their label.
  Future<void> delete(int clubId, String id) async {
    await guardApi(() => _dio.delete<Object?>('${_path(clubId)}/$id'));
    await (_db.delete(_db.eventLocations)..where((l) => l.id.equals(id))).go();
  }
}

@Riverpod(keepAlive: true)
EventLocationsRepository eventLocationsRepository(Ref ref) =>
    EventLocationsRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(apiClientProvider),
    );
