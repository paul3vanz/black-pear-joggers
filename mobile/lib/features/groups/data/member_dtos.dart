import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';

/// The caller's running preferences (`GET`/`PUT …/preferences`). Defaults
/// when never saved: `mi` / `mi`, no range.
class PreferencesDto {
  const PreferencesDto({
    this.paceUnit = DistUnit.mi,
    this.distanceUnit = DistUnit.mi,
    this.paceFromS,
    this.paceToS,
    this.updatedAt,
  });

  static const defaults = PreferencesDto();

  final DistUnit paceUnit;
  final DistUnit distanceUnit;
  final int? paceFromS;
  final int? paceToS;
  final DateTime? updatedAt;

  factory PreferencesDto.fromJson(Map<String, Object?> json) => PreferencesDto(
    paceUnit: DistUnit.fromCode(json['paceUnit']) ?? DistUnit.mi,
    distanceUnit: DistUnit.fromCode(json['distanceUnit']) ?? DistUnit.mi,
    paceFromS: (json['paceFromS'] as num?)?.toInt(),
    paceToS: (json['paceToS'] as num?)?.toInt(),
    updatedAt: json['updatedAt'] is String
        ? DateTime.tryParse(json['updatedAt']! as String)
        : null,
  );

  /// The usual pace range (or single pace) in [paceUnit]; none when unset.
  PaceSpec get usualPace =>
      PaceSpec.fromFields(unit: paceUnit.code, fromS: paceFromS, toS: paceToS);
}

/// One item of `GET …/members` (committee tools).
class MemberItem {
  const MemberItem({
    required this.memberId,
    required this.displayName,
    this.status = 'active',
    this.roles = const [],
  });

  final String memberId;
  final String displayName;
  final String status;
  final List<String> roles;

  factory MemberItem.fromJson(Map<String, Object?> json) => MemberItem(
    memberId: json['memberId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    status: json['status'] as String? ?? 'active',
    roles: [
      if (json['roles'] is List)
        for (final r in json['roles']! as List)
          if (r is String) r,
    ],
  );

  bool get isLeader => roles.contains('leader');
}
