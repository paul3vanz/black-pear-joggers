import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../logic/follow_resolver.dart';
import '../logic/run_feed.dart';

/// "Runs I follow" (D117): the caller's follow / auto / hide per series.
///
/// Reads come from the Drift cache (`series_follows`), so My runs renders
/// offline. Writes are online-only like the other settings, but optimistic:
/// the cache changes at once (so every screen watching it updates in place,
/// like a React Query `onMutate`), then the PUT runs, and a failure puts the
/// old rows back and rethrows so the screen can say the change didn't save.
class FollowsRepository {
  FollowsRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// The club's series in week order (weekday, time, title).
  Stream<List<SeriesFollow>> watch(int clubId) =>
      (_db.select(_db.seriesFollows)
            ..where((f) => f.clubId.equals(clubId))
            ..orderBy([
              (f) => OrderingTerm(expression: f.weekday),
              (f) => OrderingTerm(expression: f.localStartTime),
              (f) => OrderingTerm(expression: f.title),
            ]))
          .watch()
          .map((rows) => [for (final r in rows) _fromRow(r)]);

  static SeriesFollow _fromRow(SeriesFollowRow r) => SeriesFollow(
    seriesId: r.seriesId,
    title: r.title,
    weekday: r.weekday,
    localStartTime: r.localStartTime,
    groupMode: r.groupMode,
    mode: FollowMode.parse(r.mode),
    usuallyComes: r.usuallyComes,
  );

  SeriesFollowsCompanion _toRow(int clubId, SeriesFollow f) =>
      SeriesFollowsCompanion.insert(
        seriesId: f.seriesId,
        clubId: clubId,
        title: f.title,
        weekday: f.weekday,
        localStartTime: f.localStartTime,
        groupMode: f.groupMode,
        mode: f.mode.name,
        usuallyComes: Value(f.usuallyComes),
        fetchedAt: _now(),
      );

  /// Replaces the club's cached rows with [series] (a full list).
  Future<void> _replaceAll(int clubId, List<SeriesFollow> series) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.seriesFollows,
        )..where((f) => f.clubId.equals(clubId))).go();
        await _db.batch(
          (b) => b.insertAll(_db.seriesFollows, [
            for (final f in series) _toRow(clubId, f),
          ]),
        );
      });

  static List<SeriesFollow> _list(Object? json) => [
    for (final s in (json as List<Object?>? ?? const []))
      SeriesFollow.fromJson(Map<String, Object?>.from(s! as Map)),
  ];

  /// `GET /follows` into the cache. Throws `ApiException`.
  Future<List<SeriesFollow>> refresh(int clubId) async {
    final response = await guardApi(
      () => _dio.get<Object?>('/app/clubs/$clubId/follows'),
    );
    final series = _list(jsonObject(response)['series']);
    await _replaceAll(clubId, series);
    return series;
  }

  Future<Map<String, SeriesFollowRow>> _rows(
    int clubId,
    Iterable<String> ids,
  ) async => {
    for (final r in await (_db.select(
      _db.seriesFollows,
    )..where((f) => f.clubId.equals(clubId) & f.seriesId.isIn(ids))).get())
      r.seriesId: r,
  };

  /// Writes [modes] to the cache now and returns what was there, to put back.
  Future<Map<String, SeriesFollowRow>> _apply(
    int clubId,
    Map<String, FollowMode> modes,
  ) async {
    final before = await _rows(clubId, modes.keys);
    await _db.batch((b) {
      for (final e in modes.entries) {
        b.update(
          _db.seriesFollows,
          SeriesFollowsCompanion(mode: Value(e.value.name)),
          where: (f) => f.seriesId.equals(e.key),
        );
      }
    });
    return before;
  }

  Future<void> _revert(Map<String, SeriesFollowRow> before) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_db.seriesFollows, before.values),
  );

  /// Runs the optimistic write: cache first, then [send]; puts the old rows
  /// back and rethrows when [send] fails.
  Future<T> _optimistic<T>(
    int clubId,
    Map<String, FollowMode> modes,
    Future<T> Function() send,
  ) async {
    final before = await _apply(clubId, modes);
    try {
      return await send();
    } on Object {
      await _revert(before);
      rethrow;
    }
  }

  /// `PUT /follows/{seriesId}`: the three-way control and the inline Follow
  /// button.
  Future<void> setMode(int clubId, String seriesId, FollowMode mode) =>
      _optimistic(clubId, {seriesId: mode}, () async {
        final response = await guardApi(
          () => _dio.put<Object?>(
            '/app/clubs/$clubId/follows/$seriesId',
            data: {'mode': mode.name},
          ),
        );
        final row = SeriesFollow.fromJson(jsonObject(response));
        await _db
            .into(_db.seriesFollows)
            .insertOnConflictUpdate(_toRow(clubId, row));
      });

  /// `PUT /follows` with `{seriesIds, mode}`: Follow all (one day) and Follow
  /// everything. Returns the previous modes, for Undo ([restore]).
  Future<Map<String, FollowMode>> setMany(
    int clubId,
    List<String> seriesIds,
    FollowMode mode,
  ) => _bulk(
    clubId,
    {for (final id in seriesIds) id: mode},
    {'seriesIds': seriesIds, 'mode': mode.name},
  );

  /// `PUT /follows` with `{modes}`: Undo puts every series back exactly.
  Future<void> restore(int clubId, Map<String, FollowMode> modes) =>
      _bulk(clubId, modes, {
        'modes': {for (final e in modes.entries) e.key: e.value.name},
      });

  Future<Map<String, FollowMode>> _bulk(
    int clubId,
    Map<String, FollowMode> modes,
    Map<String, Object?> body,
  ) => _optimistic(clubId, modes, () async {
    final response = await guardApi(
      () => _dio.put<Object?>('/app/clubs/$clubId/follows', data: body),
    );
    final json = jsonObject(response);
    await _replaceAll(clubId, _list(json['series']));
    final previous = json['previous'];
    return {
      if (previous is Map)
        for (final e in previous.entries)
          e.key as String: FollowMode.parse(e.value as String?),
    };
  });
}

final followsRepositoryProvider = Provider<FollowsRepository>(
  (ref) => FollowsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
  ),
);

/// The cached series follows of a club, in week order.
final seriesFollowsProvider = StreamProvider.family<List<SeriesFollow>, int>(
  (ref, clubId) => ref.watch(followsRepositoryProvider).watch(clubId),
);
