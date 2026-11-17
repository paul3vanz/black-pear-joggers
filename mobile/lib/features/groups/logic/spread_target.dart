import 'dart:math' as math;

import '../../../core/units/dist_unit.dart';
import '../data/group_dtos.dart';

/// The spread of paces the committee aims for on a paced run (D128, gap rule
/// changed in D134). Written per mile, which is how the committee thinks of
/// them, and worked in seconds per km (paces are stored as entered and only
/// converted for display).
///
/// The API's `PaceSpread` (early nudges) is the twin; both read
/// api/tests/fixtures/spread_target_cases.json.
const spreadTargetFastPerMi = 480.0; // 8:00/mi
const spreadTargetSlowPerMi = 720.0; // 12:00/mi

/// A hole bigger than this between two edges is worth asking about, and a new
/// group has to be at least this far from an edge to fill it.
const spreadMaxGapPerMi = 30.0;

/// Beyond twice [spreadMaxGapPerMi] a gap is worded as a range of paces rather
/// than one pace.
const spreadRangeGapPerMi = 60.0;

/// A new group fitting a single-pace gap may sit this far either side of it.
const spreadFillMarginPerMi = 15.0;

double _km(double perMile) => perMile / DistUnit.mi.kmPerUnit;

int _round15(double s) => (s / 15).round() * 15;

/// Where two neighbouring led groups are too far apart. All values are seconds
/// per km.
class SpreadGap {
  const SpreadGap({
    required this.fromS,
    required this.toS,
    required this.fastS,
    required this.slowS,
    required this.single,
  });

  /// The slow edge of the faster group and the fast edge of the slower one.
  final double fromS;
  final double toS;

  /// The stretch to ask about, in seconds per km: for a range gap
  /// [spreadMaxGapPerMi] outside each edge; for a [single] one, a margin of
  /// [spreadFillMarginPerMi] inside each edge.
  final double fastS;
  final double slowS;

  /// A 30-60 s gap, worded as one pace (its mid-point) rather than a range.
  final bool single;

  /// The pace named in [unit] (whole 15 s): the mid-point of a [single] gap,
  /// else the faster end of the range of paces needed.
  int fastIn(DistUnit unit) => isSingleIn(unit)
      ? _round15((fromS + toS) / 2 * unit.kmPerUnit)
      : _round15((fromS + _km(spreadMaxGapPerMi)) * unit.kmPerUnit);

  /// As [fastIn] for the slower end of the range (same as [fastIn] for a
  /// [single] gap).
  int slowIn(DistUnit unit) => isSingleIn(unit)
      ? fastIn(unit)
      : _round15((toS - _km(spreadMaxGapPerMi)) * unit.kmPerUnit);

  /// Worded as one pace in [unit]: a [single] gap, or a range that rounds to
  /// nothing wider than one 15 s step.
  bool isSingleIn(DistUnit unit) =>
      single ||
      _round15((fromS + _km(spreadMaxGapPerMi)) * unit.kmPerUnit) >=
          _round15((toS - _km(spreadMaxGapPerMi)) * unit.kmPerUnit);

  /// The neighbours' edges in [unit], to the second ("nobody between 9:15 and
  /// 10:30").
  int fromIn(DistUnit unit) => (fromS * unit.kmPerUnit).round();
  int toIn(DistUnit unit) => (toS * unit.kmPerUnit).round();
}

/// An open end of the target: a faster or slower group is needed, measured from
/// the edge of the fastest or slowest led group.
class SpreadEnd {
  const SpreadEnd({required this.edgeS, required this.nearestS});

  /// The pace asked for in seconds per km: [spreadMaxGapPerMi] faster than the
  /// fastest group's fast edge, or slower than the slowest group's slow edge.
  final double edgeS;

  /// The slowest or fastest led group's own edge in seconds per km, for "the
  /// fastest group is 9:15".
  final double nearestS;

  /// [edgeS] to the nearest 15 s in [unit] (10:00/mi, or 6:15/km for the same
  /// stretch).
  int edgeIn(DistUnit unit) => _round15(edgeS * unit.kmPerUnit);

  int nearestIn(DistUnit unit) => (nearestS * unit.kmPerUnit).round();
}

class SpreadTarget {
  const SpreadTarget({
    required this.empty,
    required this.gaps,
    required this.fasterEnd,
    required this.slowerEnd,
    required this.jogWalk,
  });

  /// No group with a leader and a pace at all: the whole target is open.
  final bool empty;

  /// Red: too far between two led groups, fastest first.
  final List<SpreadGap> gaps;

  /// Amber: nothing led within 30 s/mi of 8:00, or of 12:00. Null when met.
  final SpreadEnd? fasterEnd;
  final SpreadEnd? slowerEnd;

  /// A led jog/walk group with no pace is on offer.
  final bool jogWalk;

  /// Something the committee could still ask about: a red gap or an amber
  /// shortfall, the whole target when nothing is led, or no jog/walk group.
  bool get needsAttention =>
      empty ||
      gaps.isNotEmpty ||
      fasterEnd != null ||
      slowerEnd != null ||
      !jogWalk;

  /// Red items: the gaps, or the whole target when nothing is led.
  int get redCount => empty ? 1 : gaps.length;

  /// Amber items: the open ends and a missing jog/walk group.
  int get amberCount =>
      (fasterEnd != null ? 1 : 0) +
      (slowerEnd != null ? 1 : 0) +
      (jogWalk ? 0 : 1);
}

/// Reviews the spread of led groups on one paced run against the committee's
/// target (D128): groups from about 8:00 to 12:00/mi plus jog/walk, with
/// flexibility and no big hole between neighbours.
///
/// Only groups with a confirmed leader count, at their real pace: a single pace
/// is that pace and a range is its two ends, with no tolerance padding and
/// nothing rounded to a minute. A group with no pace only counts as the jog/walk
/// group when its kind is `jog_walk`.
SpreadTarget buildSpreadTarget(List<Group> groups) {
  final bands = <({double fast, double slow})>[];
  var jogWalk = false;
  for (final g in groups) {
    if (g.isDeleted || g.leaders.isEmpty) continue;
    final fast = g.pace.fastest;
    final slow = g.pace.slowest;
    if (fast == null || slow == null) {
      if (g.kind == 'jog_walk') jogWalk = true;
      continue;
    }
    bands.add((fast: fast.secondsPerKm, slow: slow.secondsPerKm));
  }
  if (bands.isEmpty) {
    return SpreadTarget(
      empty: true,
      gaps: const [],
      fasterEnd: null,
      slowerEnd: null,
      jogWalk: jogWalk,
    );
  }

  final fastEnd = _km(spreadTargetFastPerMi + spreadMaxGapPerMi);
  final slowEnd = _km(spreadTargetSlowPerMi - spreadMaxGapPerMi);
  final maxGap = _km(spreadMaxGapPerMi);
  final rangeGap = _km(spreadRangeGapPerMi);
  final margin = _km(spreadFillMarginPerMi);

  bands.sort((a, b) => a.fast.compareTo(b.fast));
  final gaps = <SpreadGap>[];
  // The slowest edge so far, so a range inside a wider group hides nothing.
  var edge = bands.first.slow;
  for (final b in bands.skip(1)) {
    final hole = b.fast - edge;
    if (hole > maxGap + 1e-9) {
      final single = hole <= rangeGap + 1e-9;
      final gap = SpreadGap(
        fromS: edge,
        toS: b.fast,
        fastS: single ? edge + margin : edge + maxGap,
        slowS: single ? b.fast - margin : b.fast - maxGap,
        single: single,
      );
      gaps.add(gap);
    }
    edge = math.max(edge, b.slow);
  }

  return SpreadTarget(
    empty: false,
    gaps: gaps,
    fasterEnd: bands.first.fast > fastEnd + 1e-9
        ? SpreadEnd(
            edgeS: bands.first.fast - maxGap,
            nearestS: bands.first.fast,
          )
        : null,
    slowerEnd: edge < slowEnd - 1e-9
        ? SpreadEnd(edgeS: edge + maxGap, nearestS: edge)
        : null,
    jogWalk: jogWalk,
  );
}
