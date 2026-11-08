import 'dart:math' as math;

import '../../../core/units/dist_unit.dart';
import '../data/group_dtos.dart';

/// The spread of paces the committee aims for on a paced run (D128). Written per
/// mile, which is how the committee thinks of them, and worked in seconds per km.
/// The server has the same rule (`PaceSpread`); both are tested against
/// `api/tests/fixtures/spread_target_cases.json`, so change them together.
const spreadTargetFastPerMi = 480.0; // 8:00/mi
const spreadTargetSlowPerMi = 720.0; // 12:00/mi
const spreadEndFlexPerMi = 30.0;

/// Two neighbouring groups this far apart or more leave a gap.
const spreadMaxGapPerMi = 45.0;

/// A new group fits this far inside each edge of a gap.
const spreadFillMarginPerMi = 15.0;

double _km(double perMile) => perMile / DistUnit.mi.kmPerUnit;

int _roundUp5(double s) => (((s / 5) - 1e-6).ceil()) * 5;
int _roundDown5(double s) => (((s / 5) + 1e-6).floor()) * 5;
int _round5(double s) => (s / 5).round() * 5;

/// Where two neighbouring led groups are too far apart. All values are seconds
/// per km.
class SpreadGap {
  const SpreadGap({
    required this.fromS,
    required this.toS,
    required this.fastS,
    required this.slowS,
  });

  /// The slow edge of the faster group and the fast edge of the slower one.
  final double fromS;
  final double toS;

  /// Where a new group would fit: [spreadFillMarginPerMi] inside each edge.
  final double fastS;
  final double slowS;

  /// The stretch as whole 5 s in [unit], rounded inwards so what is named really
  /// is open ("9:30 to 10:15").
  int fastIn(DistUnit unit) => _roundUp5(fastS * unit.kmPerUnit);
  int slowIn(DistUnit unit) => _roundDown5(slowS * unit.kmPerUnit);

  /// The neighbours' edges in [unit], to the second ("nobody between 9:15 and
  /// 10:30").
  int fromIn(DistUnit unit) => (fromS * unit.kmPerUnit).round();
  int toIn(DistUnit unit) => (toS * unit.kmPerUnit).round();
}

/// An open end of the target: nothing as fast as 8:30, or as slow as 11:30.
class SpreadEnd {
  const SpreadEnd({required this.edgeS, required this.nearestS});

  /// The edge of the open stretch in seconds per km: the fastest a group may
  /// start (faster end), or the slowest it may finish (slower end), to meet it.
  final double edgeS;

  /// The slowest or fastest led group's own edge in seconds per km, for "the
  /// fastest group is 9:15".
  final double nearestS;

  /// [edgeS] to the nearest 5 s in [unit] (8:30/mi, or 5:15/km for the same
  /// stretch).
  int edgeIn(DistUnit unit) => _round5(edgeS * unit.kmPerUnit);

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

  /// Amber: nothing led as fast as 8:30, or as slow as 11:30. Null when met.
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

  final fastEnd = _km(spreadTargetFastPerMi + spreadEndFlexPerMi);
  final slowEnd = _km(spreadTargetSlowPerMi - spreadEndFlexPerMi);
  final maxGap = _km(spreadMaxGapPerMi);
  final margin = _km(spreadFillMarginPerMi);

  bands.sort((a, b) => a.fast.compareTo(b.fast));
  final gaps = <SpreadGap>[];
  // The slowest edge so far, so a range inside a wider group hides nothing.
  var edge = bands.first.slow;
  for (final b in bands.skip(1)) {
    if (b.fast - edge >= maxGap - 1e-9) {
      gaps.add(
        SpreadGap(
          fromS: edge,
          toS: b.fast,
          fastS: edge + margin,
          slowS: b.fast - margin,
        ),
      );
    }
    edge = math.max(edge, b.slow);
  }

  return SpreadTarget(
    empty: false,
    gaps: gaps,
    fasterEnd: bands.first.fast > fastEnd + 1e-9
        ? SpreadEnd(edgeS: fastEnd, nearestS: bands.first.fast)
        : null,
    slowerEnd: edge < slowEnd - 1e-9
        ? SpreadEnd(edgeS: slowEnd, nearestS: edge)
        : null,
    jogWalk: jogWalk,
  );
}
