import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// Wire shapes for `GET /app/me` and `POST /app/clubs/{id}/link`
/// (see docs/api-contract.md). Hand-written `fromJson`: these are small and the
/// server shape is stable, so codegen isn't worth it. TS equivalent: a zod schema
/// without the runtime validation.
class ClubDto {
  const ClubDto({
    required this.id,
    required this.name,
    required this.slug,
    this.joinUrl,
  });

  final int id;
  final String name;
  final String slug;
  final String? joinUrl;

  factory ClubDto.fromJson(Map<String, Object?> json) => ClubDto(
    id: json['id']! as int,
    name: json['name']! as String,
    slug: json['slug']! as String,
    joinUrl: json['joinUrl'] as String?,
  );
}

class AthleteSummaryDto {
  const AthleteSummaryDto({
    required this.id,
    this.firstName,
    this.lastName,
    this.gender,
    this.category,
  });

  final int id;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? category;

  factory AthleteSummaryDto.fromJson(Map<String, Object?> json) =>
      AthleteSummaryDto(
        id: json['id']! as int,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        gender: json['gender'] as String?,
        category: json['category'] as String?,
      );
}

class MembershipDto {
  const MembershipDto({
    required this.memberId,
    required this.club,
    required this.status,
    required this.roles,
    this.athlete,
  });

  final String memberId;
  final ClubDto club;
  final String status;
  final List<String> roles;
  final AthleteSummaryDto? athlete;

  factory MembershipDto.fromJson(Map<String, Object?> json) => MembershipDto(
    memberId: json['memberId']! as String,
    club: ClubDto.fromJson(json['club']! as Map<String, Object?>),
    status: json['status']! as String,
    roles: [
      for (final r in (json['roles'] as List<Object?>? ?? const []))
        r! as String,
    ],
    athlete: json['athlete'] == null
        ? null
        : AthleteSummaryDto.fromJson(json['athlete']! as Map<String, Object?>),
  );

  /// Row to write to the `memberships` table.
  MembershipsCompanion toCompanion(DateTime now) => MembershipsCompanion.insert(
    memberId: memberId,
    clubId: club.id,
    clubName: club.name,
    clubSlug: club.slug,
    joinUrl: Value(club.joinUrl),
    status: status,
    rolesJson: Value(jsonEncode(roles)),
    athleteId: Value(athlete?.id),
    firstName: Value(athlete?.firstName),
    lastName: Value(athlete?.lastName),
    gender: Value(athlete?.gender),
    category: Value(athlete?.category),
    updatedAt: now,
  );
}

/// Whole `GET /app/me` response. `clubs` (clubs the user could link to) isn't used
/// yet: the app is single-club for now.
class MeResponse {
  const MeResponse({required this.userId, required this.memberships});

  final String userId;
  final List<MembershipDto> memberships;

  factory MeResponse.fromJson(Map<String, Object?> json) => MeResponse(
    userId: json['userId']! as String,
    memberships: [
      for (final m in (json['memberships'] as List<Object?>? ?? const []))
        MembershipDto.fromJson(m! as Map<String, Object?>),
    ],
  );
}

/// Decodes the JSON array stored in `rolesJson` columns.
List<String> decodeRoles(String rolesJson) => [
  for (final r in jsonDecode(rolesJson) as List<Object?>) r! as String,
];
