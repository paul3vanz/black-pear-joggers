import 'dart:convert';

import '../../../core/units/pace_spec.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// The `status` values of an attendance row.
const attendanceStatuses = ['going', 'maybe', 'not_going'];

/// The contract's session `summary` block, computed server-side for the caller.
class SessionSummary {
  const SessionSummary({
    this.groupCount = 0,
    this.leaderCount = 0,
    this.goingCount = 0,
    this.maybeCount = 0,
    this.myStatus,
    this.myGroupId,
    this.myLeading = false,
  });

  final int groupCount;
  final int leaderCount;
  final int goingCount;
  final int maybeCount;

  /// `going` | `maybe` | `not_going`, or null for no response yet.
  final String? myStatus;
  final String? myGroupId;
  final bool myLeading;

  factory SessionSummary.fromJson(Map<String, Object?> json) => SessionSummary(
    groupCount: (json['groupCount'] as num?)?.toInt() ?? 0,
    leaderCount: (json['leaderCount'] as num?)?.toInt() ?? 0,
    goingCount: (json['goingCount'] as num?)?.toInt() ?? 0,
    maybeCount: (json['maybeCount'] as num?)?.toInt() ?? 0,
    myStatus: _str(json['myStatus']),
    myGroupId: _str(json['myGroupId']),
    myLeading: json['myLeading'] as bool? ?? false,
  );

  Map<String, Object?> toJson() => {
    'groupCount': groupCount,
    'leaderCount': leaderCount,
    'goingCount': goingCount,
    'maybeCount': maybeCount,
    'myStatus': myStatus,
    'myGroupId': myGroupId,
    'myLeading': myLeading,
  };

  /// Copy with new values. Pass `clearMyStatus` / `clearMyGroup` to null them.
  SessionSummary copyWith({
    int? groupCount,
    int? leaderCount,
    int? goingCount,
    int? maybeCount,
    String? myStatus,
    bool clearMyStatus = false,
    String? myGroupId,
    bool clearMyGroup = false,
    bool? myLeading,
  }) => SessionSummary(
    groupCount: groupCount ?? this.groupCount,
    leaderCount: leaderCount ?? this.leaderCount,
    goingCount: goingCount ?? this.goingCount,
    maybeCount: maybeCount ?? this.maybeCount,
    myStatus: clearMyStatus ? null : (myStatus ?? this.myStatus),
    myGroupId: clearMyGroup ? null : (myGroupId ?? this.myGroupId),
    myLeading: myLeading ?? this.myLeading,
  );
}

/// Decodes a stored `summaryJson`; null when absent or malformed.
SessionSummary? decodeSummary(String? json) {
  if (json == null || json.isEmpty) return null;
  try {
    final map = jsonDecode(json);
    return map is Map
        ? SessionSummary.fromJson(Map<String, Object?>.from(map))
        : null;
  } on Object {
    return null;
  }
}

String encodeSummary(SessionSummary s) => jsonEncode(s.toJson());

/// The caller's own response (`GET`/`PUT …/sessions/{id}/attendance`).
class AttendanceDto {
  const AttendanceDto({
    required this.sessionId,
    required this.status,
    this.groupId,
    this.paceUnit,
    this.paceFromS,
    this.paceToS,
    this.updatedAt,
  });

  final String sessionId;
  final String status;
  final String? groupId;
  final String? paceUnit;
  final int? paceFromS;
  final int? paceToS;
  final DateTime? updatedAt;

  factory AttendanceDto.fromJson(Map<String, Object?> json) => AttendanceDto(
    sessionId: json['sessionId'] as String? ?? '',
    status: _str(json['status']) ?? 'going',
    groupId: _str(json['groupId']),
    paceUnit: _str(json['paceUnit']),
    paceFromS: (json['paceFromS'] as num?)?.toInt(),
    paceToS: (json['paceToS'] as num?)?.toInt(),
    updatedAt: _date(json['updatedAt']),
  );

  /// The per-run pace override, if any.
  PaceSpec get pace =>
      PaceSpec.fromFields(unit: paceUnit, fromS: paceFromS, toS: paceToS);
}
