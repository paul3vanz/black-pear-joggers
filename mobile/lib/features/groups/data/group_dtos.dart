import 'dart:convert';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/distance.dart';
import '../../../core/units/pace_spec.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// The kinds the group editor offers. The server also has `event` (a parkrun or
/// race entry, Phase 8), created through the event picker, not this list.
const groupKinds = ['run', 'jog_walk', 'efforts', 'route', 'social', 'other'];

/// A confirmed leader of a group.
class GroupLeader {
  const GroupLeader({
    required this.memberId,
    required this.displayName,
    required this.role,
  });

  final String memberId;
  final String displayName;

  /// `leader` | `co_leader` | `backmarker`.
  final String role;

  factory GroupLeader.fromJson(Map<String, Object?> json) => GroupLeader(
    memberId: json['memberId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    role: json['role'] as String? ?? 'leader',
  );

  Map<String, Object?> toJson() => {
    'memberId': memberId,
    'displayName': displayName,
    'role': role,
  };
}

/// A pace group of a session (the contract's Group shape). Paces and distance
/// are as the leader entered them; the `*PerKm` / `distanceM` values are the
/// server's derived copies for sorting and matching.
class Group {
  const Group({
    required this.id,
    required this.sessionId,
    this.kind = 'run',
    this.label,
    this.description,
    this.paceUnit,
    this.paceFromS,
    this.paceToS,
    this.paceFromSPerKm,
    this.paceToSPerKm,
    this.distanceValue,
    this.distanceUnit,
    this.distanceM,
    this.status = 'active',
    this.sortOrder = 0,
    this.leaders = const [],
    this.locationId,
    this.createdByMemberId,
    this.goingCount = 0,
    this.maybeCount = 0,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String sessionId;
  final String kind;
  final String? label;
  final String? description;
  final String? paceUnit;
  final int? paceFromS;
  final int? paceToS;
  final int? paceFromSPerKm;
  final int? paceToSPerKm;
  final double? distanceValue;
  final String? distanceUnit;
  final int? distanceM;

  /// `active` | `needs_leader`.
  final String status;
  final int sortOrder;
  final List<GroupLeader> leaders;

  /// The `event_locations` row of an event group (kind `event`), if any.
  final String? locationId;

  /// Who created an event group (they may edit or delete it).
  final String? createdByMemberId;
  final int goingCount;
  final int maybeCount;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory Group.fromJson(Map<String, Object?> json) {
    final rawLeaders = json['leaders'];
    return Group(
      id: json['id']! as String,
      sessionId: json['sessionId'] as String? ?? '',
      kind: _str(json['kind']) ?? 'run',
      label: _str(json['label']),
      description: _str(json['description']),
      paceUnit: _str(json['paceUnit']),
      paceFromS: (json['paceFromS'] as num?)?.toInt(),
      paceToS: (json['paceToS'] as num?)?.toInt(),
      paceFromSPerKm: (json['paceFromSPerKm'] as num?)?.toInt(),
      paceToSPerKm: (json['paceToSPerKm'] as num?)?.toInt(),
      distanceValue: (json['distanceValue'] as num?)?.toDouble(),
      distanceUnit: _str(json['distanceUnit']),
      distanceM: (json['distanceM'] as num?)?.toInt(),
      status: _str(json['status']) ?? 'active',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      leaders: [
        if (rawLeaders is List)
          for (final l in rawLeaders)
            if (l is Map) GroupLeader.fromJson(Map<String, Object?>.from(l)),
      ],
      locationId: _str(json['locationId']),
      createdByMemberId: _str(json['createdByMemberId']),
      goingCount: (json['goingCount'] as num?)?.toInt() ?? 0,
      maybeCount: (json['maybeCount'] as num?)?.toInt() ?? 0,
      updatedAt: _date(json['updatedAt']),
      deletedAt: _date(json['deletedAt']),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'kind': kind,
    'label': label,
    'description': description,
    'paceUnit': paceUnit,
    'paceFromS': paceFromS,
    'paceToS': paceToS,
    'paceFromSPerKm': paceFromSPerKm,
    'paceToSPerKm': paceToSPerKm,
    'distanceValue': distanceValue,
    'distanceUnit': distanceUnit,
    'distanceM': distanceM,
    'status': status,
    'sortOrder': sortOrder,
    'leaders': [for (final l in leaders) l.toJson()],
    'locationId': locationId,
    'createdByMemberId': createdByMemberId,
    'goingCount': goingCount,
    'maybeCount': maybeCount,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
  };

  bool get isDeleted => deletedAt != null;
  bool get needsLeader => status == 'needs_leader';

  /// The pace as the leader entered it (none, single or range).
  PaceSpec get pace =>
      PaceSpec.fromFields(unit: paceUnit, fromS: paceFromS, toS: paceToS);

  /// The distance as entered, or null.
  Distance? get distance {
    final unit = DistUnit.fromCode(distanceUnit);
    final value = distanceValue;
    return unit == null || value == null ? null : Distance(value, unit);
  }

  /// The fast end in seconds per km for sorting: the derived server value,
  /// else computed from [pace]; null with no pace.
  double? get sortSecPerKm =>
      paceFromSPerKm?.toDouble() ?? pace.fastest?.secondsPerKm;

  bool isLedBy(String memberId) => leaders.any((l) => l.memberId == memberId);

  Group copyWith({
    List<GroupLeader>? leaders,
    int? goingCount,
    int? maybeCount,
    String? status,
  }) => Group(
    id: id,
    sessionId: sessionId,
    kind: kind,
    label: label,
    description: description,
    paceUnit: paceUnit,
    paceFromS: paceFromS,
    paceToS: paceToS,
    paceFromSPerKm: paceFromSPerKm,
    paceToSPerKm: paceToSPerKm,
    distanceValue: distanceValue,
    distanceUnit: distanceUnit,
    distanceM: distanceM,
    status: status ?? this.status,
    sortOrder: sortOrder,
    leaders: leaders ?? this.leaders,
    locationId: locationId,
    createdByMemberId: createdByMemberId,
    goingCount: goingCount ?? this.goingCount,
    maybeCount: maybeCount ?? this.maybeCount,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

/// Decodes a stored `groupsJson`; an empty list when absent or malformed.
List<Group> decodeGroups(String? json) {
  if (json == null || json.isEmpty) return <Group>[];
  try {
    final list = jsonDecode(json);
    if (list is! List) return <Group>[];
    return [
      for (final g in list)
        if (g is Map && g['id'] is String)
          Group.fromJson(Map<String, Object?>.from(g)),
    ];
  } on Object {
    return <Group>[];
  }
}

String encodeGroups(List<Group> groups) =>
    jsonEncode([for (final g in groups) g.toJson()]);
