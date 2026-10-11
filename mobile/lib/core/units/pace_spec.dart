import 'dist_unit.dart';
import 'pace.dart';

/// The pace part of a group (or a member's preference): none, a single pace, or
/// a range. A sealed class is Dart's discriminated union:
/// `type PaceSpec = {kind:'none'} | {kind:'single', pace} | {kind:'range', fast, slow}`.
sealed class PaceSpec {
  const PaceSpec();

  /// How far (seconds per km) either side of a single pace still counts as
  /// "close to" it when matching.
  static const singleToleranceSecPerKm = 15.0;

  /// Builds a spec from the API fields (`paceUnit`, `paceFromS`, `paceToS`).
  /// A missing unit or `paceFromS` means no pace; a missing `paceToS` means a
  /// single pace. A reversed range is put the right way round.
  factory PaceSpec.fromFields({String? unit, int? fromS, int? toS}) {
    final u = DistUnit.fromCode(unit);
    if (u == null || fromS == null) return const NoPace();
    if (toS == null || toS == fromS) return SinglePace(Pace(fromS, u));
    final fast = fromS < toS ? fromS : toS;
    final slow = fromS < toS ? toS : fromS;
    return PaceRange(Pace(fast, u), Pace(slow, u));
  }

  /// The API fields for this spec, nulls for the parts it doesn't have.
  ({String? unit, int? fromS, int? toS}) toFields();

  /// Same as [toFields] as a JSON map (`paceUnit`, `paceFromS`, `paceToS`).
  Map<String, Object?> toJson() {
    final f = toFields();
    return {'paceUnit': f.unit, 'paceFromS': f.fromS, 'paceToS': f.toS};
  }

  bool get isNone => this is NoPace;

  /// The fastest pace in the spec (the only one for a single pace), or null.
  Pace? get fastest;

  /// The slowest pace in the spec, or null.
  Pace? get slowest;

  /// `9:30/mi`, `9:00-9:30/mi`; empty for no pace. In another unit than the
  /// viewer's: `5:36/km (9:30/mi)` with the original in brackets.
  String display(DistUnit viewerUnit);

  /// The matching band in seconds per km: a range is exact, a single pace is
  /// widened by [tolerance]. Null for no pace.
  ({double fast, double slow})? band({
    double tolerance = singleToleranceSecPerKm,
  });

  /// Whether [secPerKm] falls inside the band.
  bool contains(double secPerKm, {double tolerance = singleToleranceSecPerKm}) {
    final b = band(tolerance: tolerance);
    return b != null && secPerKm >= b.fast && secPerKm <= b.slow;
  }

  /// Whether this spec's band touches [other]'s band. False if either has no pace.
  bool overlaps(PaceSpec other, {double tolerance = singleToleranceSecPerKm}) {
    final a = band(tolerance: tolerance);
    final b = other.band(tolerance: tolerance);
    if (a == null || b == null) return false;
    return a.fast <= b.slow && b.fast <= a.slow;
  }
}

/// No pace (jog/walk, efforts, a social run).
class NoPace extends PaceSpec {
  const NoPace();

  @override
  ({String? unit, int? fromS, int? toS}) toFields() =>
      (unit: null, fromS: null, toS: null);

  @override
  Pace? get fastest => null;

  @override
  Pace? get slowest => null;

  @override
  String display(DistUnit viewerUnit) => '';

  @override
  ({double fast, double slow})? band({double tolerance = 15}) => null;

  @override
  bool operator ==(Object other) => other is NoPace;

  @override
  int get hashCode => 0;
}

/// A single pace: the group aims to run close to it.
class SinglePace extends PaceSpec {
  const SinglePace(this.pace);

  final Pace pace;

  @override
  ({String? unit, int? fromS, int? toS}) toFields() =>
      (unit: pace.unit.code, fromS: pace.seconds, toS: null);

  @override
  Pace? get fastest => pace;

  @override
  Pace? get slowest => pace;

  @override
  String display(DistUnit viewerUnit) {
    if (viewerUnit == pace.unit) return pace.formatWithUnit();
    final converted = pace.convertTo(viewerUnit);
    return '${converted.formatWithUnit()} (${pace.formatWithUnit()})';
  }

  @override
  ({double fast, double slow})? band({double tolerance = 15}) {
    final spk = pace.secondsPerKm;
    return (fast: spk - tolerance, slow: spk + tolerance);
  }

  @override
  bool operator ==(Object other) => other is SinglePace && other.pace == pace;

  @override
  int get hashCode => pace.hashCode;
}

/// A range from [fast] (fewer seconds) to [slow], both in the same unit.
class PaceRange extends PaceSpec {
  PaceRange(this.fast, this.slow)
    : assert(fast.unit == slow.unit, 'range ends must share a unit'),
      assert(fast.seconds <= slow.seconds, 'fast end must be the faster');

  final Pace fast;
  final Pace slow;

  DistUnit get unit => fast.unit;

  @override
  ({String? unit, int? fromS, int? toS}) toFields() =>
      (unit: unit.code, fromS: fast.seconds, toS: slow.seconds);

  @override
  Pace? get fastest => fast;

  @override
  Pace? get slowest => slow;

  String _own() => '${fast.format()}-${slow.format()}/${unit.code}';

  @override
  String display(DistUnit viewerUnit) {
    if (viewerUnit == unit) return _own();
    final f = fast.convertTo(viewerUnit);
    final s = slow.convertTo(viewerUnit);
    return '${f.format()}-${s.format()}/${viewerUnit.code} (${_own()})';
  }

  @override
  ({double fast, double slow})? band({double tolerance = 15}) =>
      (fast: fast.secondsPerKm, slow: slow.secondsPerKm);

  @override
  bool operator ==(Object other) =>
      other is PaceRange && other.fast == fast && other.slow == slow;

  @override
  int get hashCode => Object.hash(fast, slow);
}
