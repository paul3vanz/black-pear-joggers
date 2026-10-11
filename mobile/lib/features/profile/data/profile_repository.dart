import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';

part 'profile_repository.g.dart';

/// Wire shape of `GET /app/clubs/{clubId}/profile`.
class ProfileDto {
  const ProfileDto({
    required this.memberId,
    required this.status,
    required this.roles,
    required this.athlete,
    this.membership,
    required this.links,
  });

  final String memberId;
  final String status;
  final List<String> roles;
  final Map<String, Object?> athlete;

  /// Null when there is no EA sync row for the athlete.
  final Map<String, Object?>? membership;
  final Map<String, Object?> links;

  factory ProfileDto.fromJson(Map<String, Object?> json) => ProfileDto(
    memberId: json['memberId']! as String,
    status: json['status']! as String,
    roles: [
      for (final r in (json['roles'] as List<Object?>? ?? const []))
        r! as String,
    ],
    athlete: json['athlete']! as Map<String, Object?>,
    membership: json['membership'] as Map<String, Object?>?,
    links: (json['links'] as Map<String, Object?>?) ?? const {},
  );

  ProfilesCompanion toCompanion(int clubId, DateTime now) =>
      ProfilesCompanion.insert(
        memberId: memberId,
        clubId: clubId,
        status: status,
        rolesJson: Value(jsonEncode(roles)),
        athleteRowId: Value(athlete['id'] as int?),
        athleteId: Value(athlete['athleteId'] as int?),
        po10Guid: Value(athlete['po10Guid'] as String?),
        firstName: Value(athlete['firstName'] as String?),
        lastName: Value(athlete['lastName'] as String?),
        gender: Value(athlete['gender'] as String?),
        category: Value(athlete['category'] as String?),
        active: Value(athlete['active'] as bool? ?? false),
        affiliated: Value(athlete['affiliated'] as bool? ?? false),
        competitiveRegStatus: Value(
          membership?['competitiveRegStatus'] as String?,
        ),
        firstClaimClubName: Value(membership?['firstClaimClubName'] as String?),
        resultsUrl: Value(links['results'] as String?),
        powerOf10Url: Value(links['powerOf10'] as String?),
        claimAwardUrl: Value(links['claimAward'] as String?),
        updatedAt: now,
      );
}

/// What [ProfileRepository.refreshProfile] found out.
enum ProfileRefresh {
  /// Profile fetched and cached.
  updated,

  /// The server says this login isn't linked to the club (403 `not_a_member`).
  /// Local membership and profile rows for the club were deleted, so the router
  /// will send the user to the link flow.
  notAMember,
}

/// Cache-first access to the member's own profile, same pattern as
/// `MembershipRepository`. Failures are thrown as [ApiException].
class ProfileRepository {
  ProfileRepository(this._db, this._dio, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Dio _dio;
  final DateTime Function() _now;

  /// The cached profile for [clubId] (null until the first refresh succeeds).
  Stream<Profile?> watchProfile(int clubId) => (_db.select(
    _db.profiles,
  )..where((p) => p.clubId.equals(clubId))).watchSingleOrNull();

  Future<ProfileRefresh> refreshProfile(int clubId) async {
    final Response<Object?> response;
    try {
      response = await guardApi(
        () => _dio.get<Object?>('/app/clubs/$clubId/profile'),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403 && e.code == 'not_a_member') {
        await _forgetClub(clubId);
        return ProfileRefresh.notAMember;
      }
      rethrow;
    }
    final dto = ProfileDto.fromJson(jsonObject(response));
    final now = _now();
    await _db.transaction(() async {
      // A different member id for this club means the link moved: drop the old row.
      await (_db.delete(_db.profiles)..where(
            (p) =>
                p.clubId.equals(clubId) & p.memberId.equals(dto.memberId).not(),
          ))
          .go();
      await _db
          .into(_db.profiles)
          .insertOnConflictUpdate(dto.toCompanion(clubId, now));
      // The server recalculates status on every call: keep the membership row in step.
      await (_db.update(
        _db.memberships,
      )..where((m) => m.memberId.equals(dto.memberId))).write(
        MembershipsCompanion(
          status: Value(dto.status),
          rolesJson: Value(jsonEncode(dto.roles)),
        ),
      );
    });
    return ProfileRefresh.updated;
  }

  Future<void> _forgetClub(int clubId) => _db.transaction(() async {
    await (_db.delete(
      _db.memberships,
    )..where((m) => m.clubId.equals(clubId))).go();
    await (_db.delete(
      _db.profiles,
    )..where((p) => p.clubId.equals(clubId))).go();
  });
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => ProfileRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
