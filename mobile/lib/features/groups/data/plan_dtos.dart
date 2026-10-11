import 'dart:convert';

import '../../../core/units/pace_spec.dart';

List<Map<String, Object?>> _maps(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, Object?>.from(e),
];

/// One anonymous pace of the plan: the effective pace of a member who is going
/// or maybe, in seconds per km. `toSPerKm` is null for a single pace.
class PlanPace {
  const PlanPace({required this.fromSPerKm, this.toSPerKm});

  final int fromSPerKm;
  final int? toSPerKm;

  factory PlanPace.fromJson(Map<String, Object?> json) => PlanPace(
    fromSPerKm: (json['fromSPerKm'] as num?)?.toInt() ?? 0,
    toSPerKm: (json['toSPerKm'] as num?)?.toInt(),
  );

  /// As a km pace spec, handy for matching against a group's pace.
  PaceSpec get spec => PaceSpec.fromFields(
    unit: 'km',
    fromS: fromSPerKm == 0 ? null : fromSPerKm,
    toS: toSPerKm,
  );
}

/// A named attendee (only sent to leaders, the coordinator and committee).
class PlanAttendee {
  const PlanAttendee({
    required this.memberId,
    required this.displayName,
    required this.status,
    this.paceUnit,
    this.paceFromS,
    this.paceToS,
  });

  final String memberId;
  final String displayName;
  final String status;
  final String? paceUnit;
  final int? paceFromS;
  final int? paceToS;

  factory PlanAttendee.fromJson(Map<String, Object?> json) => PlanAttendee(
    memberId: json['memberId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    status: json['status'] as String? ?? 'going',
    paceUnit: json['paceUnit'] as String?,
    paceFromS: (json['paceFromS'] as num?)?.toInt(),
    paceToS: (json['paceToS'] as num?)?.toInt(),
  );

  PaceSpec get pace =>
      PaceSpec.fromFields(unit: paceUnit, fromS: paceFromS, toS: paceToS);
}

/// The plan for one group: the anonymous pace spread, and the names when the
/// caller may see them ([attendees] is null when the key was omitted).
class GroupPlan {
  const GroupPlan({
    required this.groupId,
    this.paces = const [],
    this.attendees,
  });

  final String groupId;
  final List<PlanPace> paces;
  final List<PlanAttendee>? attendees;

  factory GroupPlan.fromJson(Map<String, Object?> json) => GroupPlan(
    groupId: json['groupId'] as String? ?? '',
    paces: _maps(json['paces']).map(PlanPace.fromJson).toList(),
    attendees: json.containsKey('attendees')
        ? _maps(json['attendees']).map(PlanAttendee.fromJson).toList()
        : null,
  );
}

/// Members coming without a group. [members] (names) is null unless the caller
/// is committee, admin or the session coordinator.
class UnassignedPlan {
  const UnassignedPlan({
    this.goingCount = 0,
    this.maybeCount = 0,
    this.paces = const [],
    this.members,
  });

  final int goingCount;
  final int maybeCount;
  final List<PlanPace> paces;
  final List<PlanAttendee>? members;

  factory UnassignedPlan.fromJson(Map<String, Object?> json) => UnassignedPlan(
    goingCount: (json['goingCount'] as num?)?.toInt() ?? 0,
    maybeCount: (json['maybeCount'] as num?)?.toInt() ?? 0,
    paces: _maps(json['paces']).map(PlanPace.fromJson).toList(),
    members: json.containsKey('members')
        ? _maps(json['members']).map(PlanAttendee.fromJson).toList()
        : null,
  );
}

/// `GET …/sessions/{id}/plan`.
class SessionPlan {
  const SessionPlan({
    required this.sessionId,
    this.groups = const [],
    this.unassigned = const UnassignedPlan(),
  });

  final String sessionId;
  final List<GroupPlan> groups;
  final UnassignedPlan unassigned;

  factory SessionPlan.fromJson(Map<String, Object?> json) {
    final un = json['unassigned'];
    return SessionPlan(
      sessionId: json['sessionId'] as String? ?? '',
      groups: _maps(json['groups']).map(GroupPlan.fromJson).toList(),
      unassigned: un is Map
          ? UnassignedPlan.fromJson(Map<String, Object?>.from(un))
          : const UnassignedPlan(),
    );
  }

  /// Decodes a cached plan; null when malformed.
  static SessionPlan? decode(String json) {
    try {
      final map = jsonDecode(json);
      return map is Map
          ? SessionPlan.fromJson(Map<String, Object?>.from(map))
          : null;
    } on Object {
      return null;
    }
  }

  /// The plan for [groupId], or null if it has none.
  GroupPlan? forGroup(String groupId) {
    for (final g in groups) {
      if (g.groupId == groupId) return g;
    }
    return null;
  }
}
