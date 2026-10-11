import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/pace_spec.dart';
import 'session_local.dart';
import 'summary_dtos.dart';

part 'attendance_repository.g.dart';

/// The caller's per-run pace override of a [MyAttendanceRow].
extension MyAttendancePace on MyAttendanceRow {
  PaceSpec get pace =>
      PaceSpec.fromFields(unit: paceUnit, fromS: paceFromS, toS: paceToS);
}

/// How a [AttendanceRepository.setAttendance] call ended.
enum AttendanceOutcome {
  /// The server has it.
  saved,

  /// Kept locally and still to be sent (offline or a server hiccup). The row
  /// stays `pending` and [AttendanceRepository.retryPending] re-sends it.
  queued,

  /// The server refused it (for example the run was cancelled or has ended).
  /// The local change was reverted; show [AttendanceResult.error]'s message.
  rejected,
}

class AttendanceResult {
  const AttendanceResult(this.outcome, [this.error]);

  final AttendanceOutcome outcome;
  final ApiException? error;

  bool get isOffline => outcome == AttendanceOutcome.queued;
}

/// RSVPs for runs (D23): the local row and the cached session summary change
/// first, then the PUT goes out. If it can't be sent the row stays `pending`
/// and is retried on the next runs refresh or app resume. Same idea as the
/// inbox's `readPending`, like an optimistic React Query mutation with a
/// persisted retry.
class AttendanceRepository {
  AttendanceRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      _local = SessionLocalStore(_db);

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;
  final SessionLocalStore _local;

  Stream<MyAttendanceRow?> watchMyAttendance(String sessionId) => (_db.select(
    _db.myAttendance,
  )..where((a) => a.sessionId.equals(sessionId))).watchSingleOrNull();

  Future<MyAttendanceRow?> _row(String sessionId) => (_db.select(
    _db.myAttendance,
  )..where((a) => a.sessionId.equals(sessionId))).getSingleOrNull();

  /// Sets the caller's response. [status] is `going`, `maybe` or `not_going`;
  /// [groupId] only applies to going/maybe; [paceOverride] is this run only
  /// (null clears an earlier one). The session must be cached locally.
  Future<AttendanceResult> setAttendance(
    String sessionId,
    String status, {
    String? groupId,
    PaceSpec? paceOverride,
  }) async {
    final session = await _local.session(sessionId);
    if (session == null) {
      throw StateError('setAttendance: session $sessionId is not cached');
    }
    final coming = status != 'not_going';
    final pace = coming ? (paceOverride ?? const NoPace()).toFields() : null;
    final newGroup = coming ? groupId : null;
    await _db
        .into(_db.myAttendance)
        .insertOnConflictUpdate(
          MyAttendanceCompanion.insert(
            sessionId: sessionId,
            clubId: session.clubId,
            status: status,
            groupId: Value(newGroup),
            paceUnit: Value(pace?.unit),
            paceFromS: Value(pace?.fromS),
            paceToS: Value(pace?.toS),
            pending: const Value(true),
            updatedAt: _now(),
          ),
        );
    await _local.applyAttendance(sessionId, status: status, groupId: newGroup);
    final row = (await _row(sessionId))!;
    return _send(row);
  }

  /// Re-sends every unconfirmed response for [clubId], oldest first. Stops at
  /// the first offline failure; rethrows an expired session.
  /// Stores the server's attendance row when the session `summary` says the
  /// caller has responded but this device has no local row (a fresh install or
  /// new device). Without it, the next status change would resend no pace and
  /// the server would silently clear a per-run pace override held there.
  /// Does nothing when a row exists, when there is no response, or offline.
  Future<void> backfillMyAttendance(String sessionId) async {
    if (!_backfilling.add(sessionId)) return; // already on its way
    try {
      await _backfill(sessionId);
    } finally {
      _backfilling.remove(sessionId);
    }
  }

  final _backfilling = <String>{};

  Future<void> _backfill(String sessionId) async {
    if (await _row(sessionId) != null) return;
    final session = await _local.session(sessionId);
    if (session == null ||
        decodeSummary(session.summaryJson)?.myStatus == null) {
      return;
    }
    try {
      final response = await guardApi(
        () => _dio.get<Object?>(
          '/app/clubs/${session.clubId}/sessions/$sessionId/attendance',
        ),
      );
      final data = response.data;
      if (data is! Map) return;
      final dto = AttendanceDto.fromJson(Map<String, Object?>.from(data));
      // A response made while the GET was in flight wins.
      if (await _row(sessionId) != null) return;
      await _storeServerRow(
        session.clubId,
        AttendanceDto(
          sessionId: sessionId,
          status: dto.status,
          groupId: dto.groupId,
          paceUnit: dto.paceUnit,
          paceFromS: dto.paceFromS,
          paceToS: dto.paceToS,
          updatedAt: dto.updatedAt,
        ),
      );
    } on ApiException {
      // Offline or a server error: try again next time the run is opened.
    }
  }

  Future<void> retryPending(int clubId) async {
    final rows =
        await (_db.select(_db.myAttendance)
              ..where((a) => a.clubId.equals(clubId) & a.pending.equals(true))
              ..orderBy([(a) => OrderingTerm.asc(a.updatedAt)]))
            .get();
    for (final row in rows) {
      final result = await _send(row);
      if (result.outcome == AttendanceOutcome.queued) return;
    }
  }

  Future<AttendanceResult> _send(MyAttendanceRow row) async {
    final coming = row.status != 'not_going';
    try {
      final response = await guardApi(
        () => _dio.put<Object?>(
          '/app/clubs/${row.clubId}/sessions/${row.sessionId}/attendance',
          data: {
            'status': row.status,
            if (coming && row.groupId != null) 'groupId': row.groupId,
            if (coming && row.paceUnit != null) 'paceUnit': row.paceUnit,
            if (coming && row.paceFromS != null) 'paceFromS': row.paceFromS,
            if (coming && row.paceToS != null) 'paceToS': row.paceToS,
          },
        ),
      );
      await _confirm(row, AttendanceDto.fromJson(jsonObject(response)));
      return const AttendanceResult(AttendanceOutcome.saved);
    } on ApiException catch (e) {
      if (e.isSessionExpired) rethrow; // stays pending
      final status = e.statusCode;
      final transient =
          e.isNetworkError ||
          status == null ||
          status >= 500 ||
          status == 408 ||
          status == 429;
      if (transient) return AttendanceResult(AttendanceOutcome.queued, e);
      await _revert(row);
      return AttendanceResult(AttendanceOutcome.rejected, e);
    }
  }

  /// Stores the server's row. If the user changed their mind while the PUT was
  /// in flight, the newer local row stays pending and is sent next.
  Future<void> _confirm(MyAttendanceRow sent, AttendanceDto dto) async {
    final current = await _row(sent.sessionId);
    final unchanged =
        current != null &&
        current.status == sent.status &&
        current.groupId == sent.groupId &&
        current.paceUnit == sent.paceUnit &&
        current.paceFromS == sent.paceFromS &&
        current.paceToS == sent.paceToS;
    if (!unchanged) return;
    await _storeServerRow(sent.clubId, dto);
    await _local.applyAttendance(
      dto.sessionId.isEmpty ? sent.sessionId : dto.sessionId,
      status: dto.status,
      groupId: dto.groupId,
    );
  }

  Future<void> _storeServerRow(int clubId, AttendanceDto dto) => _db
      .into(_db.myAttendance)
      .insertOnConflictUpdate(
        MyAttendanceCompanion.insert(
          sessionId: dto.sessionId,
          clubId: clubId,
          status: dto.status,
          groupId: Value(dto.groupId),
          paceUnit: Value(dto.paceUnit),
          paceFromS: Value(dto.paceFromS),
          paceToS: Value(dto.paceToS),
          pending: const Value(false),
          updatedAt: dto.updatedAt ?? _now(),
        ),
      );

  /// Drops a refused pending row and puts the session back to what the server
  /// says (GET attendance). If that can't be fetched the next sessions refresh
  /// restores the summary.
  Future<void> _revert(MyAttendanceRow row) async {
    await (_db.delete(
      _db.myAttendance,
    )..where((a) => a.sessionId.equals(row.sessionId))).go();
    try {
      final response = await guardApi(
        () => _dio.get<Object?>(
          '/app/clubs/${row.clubId}/sessions/${row.sessionId}/attendance',
        ),
      );
      final data = response.data;
      if (data is Map) {
        final dto = AttendanceDto.fromJson(Map<String, Object?>.from(data));
        await _storeServerRow(
          row.clubId,
          AttendanceDto(
            sessionId: row.sessionId,
            status: dto.status,
            groupId: dto.groupId,
            paceUnit: dto.paceUnit,
            paceFromS: dto.paceFromS,
            paceToS: dto.paceToS,
            updatedAt: dto.updatedAt,
          ),
        );
        await _local.applyAttendance(
          row.sessionId,
          status: dto.status,
          groupId: dto.groupId,
        );
      } else {
        await _local.applyAttendance(row.sessionId, status: null);
      }
    } on ApiException {
      // Offline: leave the summary; the next refresh is authoritative.
    }
  }
}

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) => AttendanceRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
