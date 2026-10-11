import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import 'plan_dtos.dart';

part 'plan_repository.g.dart';

/// The per-session plan (pace spread, names for those allowed). Online-only
/// data (D22): the last response is cached so the screen still has something
/// to show offline.
class PlanRepository {
  PlanRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// The cached plan for [sessionId], null until one was fetched.
  Stream<SessionPlan?> watchPlan(String sessionId) =>
      (_db.select(_db.sessionPlans)
            ..where((p) => p.sessionId.equals(sessionId)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : SessionPlan.decode(row.json));

  /// When the cached plan was fetched, or null.
  Future<DateTime?> cachedAt(String sessionId) async => (await (_db.select(
    _db.sessionPlans,
  )..where((p) => p.sessionId.equals(sessionId))).getSingleOrNull())?.fetchedAt;

  /// Fetches the plan and caches it. When offline it returns the cached plan
  /// instead (null if there is none yet). Other failures (403, 404...) throw
  /// `ApiException`.
  Future<SessionPlan?> fetchPlan(String sessionId) async =>
      (await refreshPlan(sessionId)).plan;

  /// Like [fetchPlan], but also says whether the plan is the cached copy
  /// because the network was unreachable. Other errors are thrown.
  Future<({SessionPlan? plan, bool offline})> refreshPlan(
    String sessionId,
  ) async {
    final session = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      throw StateError('Session $sessionId is not cached');
    }
    try {
      final response = await guardApi(
        () => _dio.get<Object?>(
          '/app/clubs/${session.clubId}/sessions/$sessionId/plan',
        ),
      );
      final body = jsonObject(response);
      await _db
          .into(_db.sessionPlans)
          .insertOnConflictUpdate(
            SessionPlansCompanion.insert(
              sessionId: sessionId,
              clubId: session.clubId,
              json: jsonEncode(body),
              fetchedAt: _now(),
            ),
          );
      return (plan: SessionPlan.fromJson(body), offline: false);
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      final cached = await (_db.select(
        _db.sessionPlans,
      )..where((p) => p.sessionId.equals(sessionId))).getSingleOrNull();
      return (
        plan: cached == null ? null : SessionPlan.decode(cached.json),
        offline: true,
      );
    }
  }
}

@Riverpod(keepAlive: true)
PlanRepository planRepository(Ref ref) => PlanRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
