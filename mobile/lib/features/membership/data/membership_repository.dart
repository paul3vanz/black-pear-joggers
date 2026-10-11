import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import 'membership_dtos.dart';

part 'membership_repository.g.dart';

/// Offline-first access to the caller's club memberships (docs/architecture.md):
/// the UI watches [watchMemberships] (a Drift stream, so cached rows show
/// immediately), and [refreshMe] / [link] / [unlink] talk to the API and write the
/// outcome into the database, which pushes new rows to the stream.
///
/// All failures are thrown as `ApiException`.
class MembershipRepository {
  MembershipRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// Every membership cached for this account. Re-emits whenever the table changes.
  Stream<List<Membership>> watchMemberships() =>
      _db.select(_db.memberships).watch();

  /// `GET /app/me`, replacing this account's membership rows in one transaction.
  /// Cached profiles that no longer belong to a membership are dropped too.
  Future<void> refreshMe() async {
    final response = await guardApi(() => _dio.get<Object?>('/app/me'));
    final me = MeResponse.fromJson(jsonObject(response));
    final now = _now();
    await _db.transaction(() async {
      await _db.delete(_db.memberships).go();
      for (final m in me.memberships) {
        await _db.into(_db.memberships).insert(m.toCompanion(now));
      }
      final keep = [for (final m in me.memberships) m.memberId];
      await (_db.delete(
        _db.profiles,
      )..where((p) => p.memberId.isNotIn(keep))).go();
    });
  }

  /// `POST /app/clubs/{clubId}/link`. On success the API has already linked this
  /// login, so we just store the returned membership. Throws `ApiException` with code
  /// `not_found` (no athlete matches), `too_many_attempts` (429) or
  /// `validation_failed` (422).
  Future<Membership> link(
    int clubId, {
    required int urn,
    required DateTime dob,
  }) async {
    final response = await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/link',
        data: {'urn': urn, 'dob': DateFormat('yyyy-MM-dd').format(dob)},
      ),
    );
    final dto = MembershipDto.fromJson(jsonObject(response));
    await _db.transaction(() async {
      // If the link moved to a different member of this club, drop the old rows.
      await (_db.delete(_db.memberships)..where(
            (m) =>
                m.clubId.equals(dto.club.id) &
                m.memberId.equals(dto.memberId).not(),
          ))
          .go();
      await (_db.delete(_db.profiles)..where(
            (p) =>
                p.clubId.equals(dto.club.id) &
                p.memberId.equals(dto.memberId).not(),
          ))
          .go();
      await _db
          .into(_db.memberships)
          .insertOnConflictUpdate(dto.toCompanion(_now()));
    });
    return (_db.select(
      _db.memberships,
    )..where((m) => m.memberId.equals(dto.memberId))).getSingle();
  }

  /// `DELETE /app/clubs/{clubId}/link`, then forget the club locally (membership row
  /// and cached profile). Local rows are only removed once the server agrees.
  Future<void> unlink(int clubId) async {
    await guardApi(() => _dio.delete<Object?>('/app/clubs/$clubId/link'));
    await _db.transaction(() async {
      await (_db.delete(
        _db.memberships,
      )..where((m) => m.clubId.equals(clubId))).go();
      await (_db.delete(
        _db.profiles,
      )..where((p) => p.clubId.equals(clubId))).go();
    });
  }
}

@Riverpod(keepAlive: true)
MembershipRepository membershipRepository(Ref ref) => MembershipRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
