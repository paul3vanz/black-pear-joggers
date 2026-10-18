import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';
import '../../runs/logic/my_days.dart';

/// The caller's running preferences (`GET`/`PUT …/preferences`). Defaults
/// when never saved: `mi` / `mi`, no range, no days chosen.
class PreferencesDto {
  const PreferencesDto({
    this.paceUnit = DistUnit.mi,
    this.distanceUnit = DistUnit.mi,
    this.paceFromS,
    this.paceToS,
    this.leadDays,
    this.runDays,
    this.updatedAt,
  });

  static const defaults = PreferencesDto();

  final DistUnit paceUnit;
  final DistUnit distanceUnit;
  final int? paceFromS;
  final int? paceToS;

  /// "Days I may lead" as ISO weekdays (1 = Monday ... 7 = Sunday), sorted.
  /// `null` = never chosen, `[]` = chose none (D107).
  final List<int>? leadDays;

  /// "Days I run" (D115), same encoding. The server keeps [leadDays] inside it
  /// when both are set.
  final List<int>? runDays;
  final DateTime? updatedAt;

  factory PreferencesDto.fromJson(Map<String, Object?> json) => PreferencesDto(
    paceUnit: DistUnit.fromCode(json['paceUnit']) ?? DistUnit.mi,
    distanceUnit: DistUnit.fromCode(json['distanceUnit']) ?? DistUnit.mi,
    paceFromS: (json['paceFromS'] as num?)?.toInt(),
    paceToS: (json['paceToS'] as num?)?.toInt(),
    leadDays: _days(json['leadDays']),
    runDays: _days(json['runDays']),
    updatedAt: json['updatedAt'] is String
        ? DateTime.tryParse(json['updatedAt']! as String)
        : null,
  );

  static List<int>? _days(Object? raw) => raw is List
      ? ([
          for (final d in raw)
            if (d is num && d >= 1 && d <= 7) d.toInt(),
        ]..sort())
      : null;

  /// The saved days of one kind (null = never chosen).
  List<int>? daysOf(DayKind kind) => switch (kind) {
    DayKind.run => runDays,
    DayKind.lead => leadDays,
  };

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
