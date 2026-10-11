import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/units/dist_unit.dart';
import '../../../core/units/distance.dart';
import '../../../core/units/pace_spec.dart';
import 'group_dtos.dart';

/// What a leader chose last time, enough to offer "Same as last time".
class LastGroupSpec {
  const LastGroupSpec({
    this.kind = 'run',
    this.label,
    this.description,
    this.pace = const NoPace(),
    this.distance,
  });

  final String kind;
  final String? label;
  final String? description;
  final PaceSpec pace;
  final Distance? distance;

  factory LastGroupSpec.fromGroup(Group g) => LastGroupSpec(
    kind: g.kind,
    label: g.label,
    description: g.description,
    pace: g.pace,
    distance: g.distance,
  );

  Map<String, Object?> toJson() => {
    'kind': kind,
    'label': label,
    'description': description,
    ...pace.toJson(),
    'distanceValue': distance?.value,
    'distanceUnit': distance?.unit.code,
  };

  static LastGroupSpec? tryDecode(String? json) {
    if (json == null) return null;
    try {
      final m = jsonDecode(json);
      if (m is! Map) return null;
      final unit = DistUnit.fromCode(m['distanceUnit']);
      final value = (m['distanceValue'] as num?)?.toDouble();
      return LastGroupSpec(
        kind: m['kind'] as String? ?? 'run',
        label: m['label'] as String?,
        description: m['description'] as String?,
        pace: PaceSpec.fromFields(
          unit: m['paceUnit'] as String?,
          fromS: (m['paceFromS'] as num?)?.toInt(),
          toS: (m['paceToS'] as num?)?.toInt(),
        ),
        distance: unit == null || value == null ? null : Distance(value, unit),
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LastGroupSpec &&
      other.kind == kind &&
      other.label == label &&
      other.description == description &&
      other.pace == pace &&
      other.distance == distance;

  @override
  int get hashCode => Object.hash(kind, label, description, pace, distance);
}

/// Remembers the last group the signed-in member created to lead, per series
/// (and overall for ad-hoc runs). Uses the per-account database's small
/// key/value table (`sync_cursors`), so it is isolated per account without a
/// schema change (D27).
class LastGroupStore {
  LastGroupStore(this._db);

  final AppDatabase _db;

  static String _key(int clubId, String? seriesId) =>
      'lastGroup:$clubId:${seriesId ?? 'any'}';

  Future<LastGroupSpec?> _read(String key) async => LastGroupSpec.tryDecode(
    (await (_db.select(
      _db.syncCursors,
    )..where((c) => c.key.equals(key))).getSingleOrNull())?.serverTime,
  );

  Future<void> _write(String key, LastGroupSpec spec) => _db
      .into(_db.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(key: key, serverTime: jsonEncode(spec)),
      );

  /// The last group for [seriesId] (else the last one overall; ad-hoc runs,
  /// with no series, use the overall one).
  Future<LastGroupSpec?> read(int clubId, String? seriesId) async {
    if (seriesId != null) {
      final own = await _read(_key(clubId, seriesId));
      if (own != null) return own;
    }
    return _read(_key(clubId, null));
  }

  /// Records [spec] for [seriesId] and as the overall last group.
  Future<void> write(int clubId, String? seriesId, LastGroupSpec spec) async {
    if (seriesId != null) await _write(_key(clubId, seriesId), spec);
    await _write(_key(clubId, null), spec);
  }
}
