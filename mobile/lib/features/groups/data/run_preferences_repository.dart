import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';
import '../../runs/logic/my_days.dart';
import 'member_dtos.dart';

part 'run_preferences_repository.g.dart';

/// The caller's running preferences for a club: pace unit, distance unit, an
/// optional usual pace range and the days they run and may lead. (Not the notification preferences, which live
/// in `features/settings`.) Reads come from the cache and default to `mi` /
/// `mi` with no range; saving is online-only.
class RunPreferencesRepository {
  RunPreferencesRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// Cached preferences, or the defaults when nothing is stored.
  Stream<PreferencesDto> watch(int clubId) =>
      (_db.select(_db.preferences)..where((p) => p.clubId.equals(clubId)))
          .watchSingleOrNull()
          .map((row) => row == null ? PreferencesDto.defaults : _toDto(row));

  PreferencesDto _toDto(RunPreferences row) => PreferencesDto(
    paceUnit: DistUnit.fromCode(row.paceUnit) ?? DistUnit.mi,
    distanceUnit: DistUnit.fromCode(row.distanceUnit) ?? DistUnit.mi,
    paceFromS: row.paceFromS,
    paceToS: row.paceToS,
    leadDays: _decodeDays(row.leadDays),
    runDays: _decodeDays(row.runDays),
    updatedAt: row.updatedAt,
  );

  /// Stored as null = never chosen, '' = none, '2,4' = Tue and Thu (D111).
  static List<int>? _decodeDays(String? stored) => stored == null
      ? null
      : ([
          for (final part in stored.split(','))
            if (int.tryParse(part.trim()) case final d? when d >= 1 && d <= 7)
              d,
        ]..sort());

  static String? _encodeDays(List<int>? days) => days?.join(',');

  Future<PreferencesDto> _store(int clubId, Response<Object?> response) async {
    final dto = PreferencesDto.fromJson(jsonObject(response));
    await _db
        .into(_db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(
            clubId: Value(clubId),
            paceUnit: dto.paceUnit.code,
            distanceUnit: dto.distanceUnit.code,
            paceFromS: Value(dto.paceFromS),
            paceToS: Value(dto.paceToS),
            leadDays: Value(_encodeDays(dto.leadDays)),
            runDays: Value(_encodeDays(dto.runDays)),
            updatedAt: Value(dto.updatedAt ?? _now()),
          ),
        );
    return dto;
  }

  /// Pulls the server's copy into the cache. Throws `ApiException`.
  Future<PreferencesDto> refresh(int clubId) async => _store(
    clubId,
    await guardApi(() => _dio.get<Object?>('/app/clubs/$clubId/preferences')),
  );

  /// Saves the preferences (PUT, online-only) and caches what the server
  /// returns. [usualPace] is in [paceUnit]; [NoPace] clears the range. The
  /// server also clears a stored range when only the unit changes, which is why
  /// the range is always sent.
  Future<PreferencesDto> save(
    int clubId, {
    required DistUnit paceUnit,
    required DistUnit distanceUnit,
    PaceSpec usualPace = const NoPace(),
  }) async {
    final f = usualPace.toFields();
    return _store(
      clubId,
      await guardApi(
        () => _dio.put<Object?>(
          '/app/clubs/$clubId/preferences',
          data: {
            'paceUnit': paceUnit.code,
            'distanceUnit': distanceUnit.code,
            'paceFromS': f.fromS,
            'paceToS': f.toS,
          },
        ),
      ),
    );
  }

  /// Saves "days I run" or "days I may lead" (D107, D115) on its own: the body
  /// is only `{runDays: [...]}` or `{leadDays: [...]}`, so the server leaves the
  /// rest alone (an omitted key means unchanged). [days] are ISO weekdays; `[]`
  /// means "none" and `null` resets to "never chosen". The server keeps lead
  /// days inside run days, so the response (which is cached) can change the
  /// other list too. Online-only.
  Future<PreferencesDto> saveDays(
    int clubId,
    DayKind kind,
    List<int>? days,
  ) async => _store(
    clubId,
    await guardApi(
      () => _dio.put<Object?>(
        '/app/clubs/$clubId/preferences',
        data: {
          kind.field: days == null ? null : ([...days]..sort()),
        },
      ),
    ),
  );
}

@Riverpod(keepAlive: true)
RunPreferencesRepository runPreferencesRepository(Ref ref) =>
    RunPreferencesRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(apiClientProvider),
    );
