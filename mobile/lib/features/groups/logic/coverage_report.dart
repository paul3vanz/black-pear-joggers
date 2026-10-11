import 'dart:math' as math;

import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';
import '../data/group_dtos.dart';

/// Gaps narrower than this (seconds per km) are not worth a warning.
const minCoverageGapSecPerKm = 20.0;

/// The pace axis the committee reviews, in the viewer's unit: 7:00-12:00/mi,
/// or 4:15-7:30/km. Widened when a group falls outside it.
({double fast, double slow}) defaultCoverageWindow(DistUnit unit) =>
    switch (unit) {
      DistUnit.mi => (
        fast: 420 / DistUnit.mi.kmPerUnit,
        slow: 720 / DistUnit.mi.kmPerUnit,
      ),
      DistUnit.km => (fast: 255.0, slow: 450.0),
    };

/// Where an uncovered stretch sits on the axis.
enum CoverageGapKind { fasterEnd, between, slowerEnd }

/// An uncovered stretch of the pace axis, in seconds per km.
class CoverageGap {
  const CoverageGap({
    required this.kind,
    required this.fastS,
    required this.slowS,
    this.softened = false,
  });

  final CoverageGapKind kind;
  final double fastS;
  final double slowS;

  /// A slower-end tail that a jog/walk group makes less of a problem. Shown
  /// as information, not a warning.
  final bool softened;

  double get width => slowS - fastS;

  /// The edge nearest the fast side, as whole seconds per [unit], rounded
  /// inwards (up, to 5 s) so the stretch named really is uncovered.
  int fromIn(DistUnit unit) => _roundUp5(fastS * unit.kmPerUnit);

  /// The edge nearest the slow side as whole seconds per [unit], rounded
  /// inwards (down, to 5 s).
  int toIn(DistUnit unit) => _roundDown5(slowS * unit.kmPerUnit);
}

int _roundUp5(double s) => (((s / 5) - 1e-6).ceil()) * 5;
int _roundDown5(double s) => (((s / 5) + 1e-6).floor()) * 5;

/// A merged run of overlapping or touching group bands, seconds per km.
class CoverageBand {
  const CoverageBand(this.fastS, this.slowS);

  final double fastS;
  final double slowS;
}

class CoverageReport {
  const CoverageReport({
    required this.unit,
    required this.windowFastS,
    required this.windowSlowS,
    required this.bands,
    required this.gaps,
    required this.pacedLed,
    required this.noPaceLed,
    required this.needsLeader,
    required this.hasJogWalk,
    required this.fastestLed,
    required this.slowestLed,
  });

  final DistUnit unit;

  /// The axis window, seconds per km.
  final double windowFastS;
  final double windowSlowS;

  /// Merged covered bands, fastest first.
  final List<CoverageBand> bands;

  /// Uncovered stretches (at least [minCoverageGapSecPerKm] wide), fastest
  /// first.
  final List<CoverageGap> gaps;

  /// Led groups with a pace, fastest first.
  final List<Group> pacedLed;

  /// Led groups with no pace (jog/walk, efforts, social, a distance only...).
  final List<Group> noPaceLed;

  /// Groups with no leader. They cover nothing until someone steps up.
  final List<Group> needsLeader;

  /// A led jog/walk group with no pace is on offer.
  final bool hasJogWalk;

  final Group? fastestLed;
  final Group? slowestLed;

  bool get hasBands => bands.isNotEmpty;
  int get ledCount => pacedLed.length + noPaceLed.length;
  bool get isEmpty => ledCount == 0 && needsLeader.isEmpty;

  /// Groups exist, but none has a leader yet.
  bool get onlyNeedsLeader => ledCount == 0 && needsLeader.isNotEmpty;

  /// Gaps to warn about (everything but a softened slow-end tail).
  List<CoverageGap> get problems => [
    for (final g in gaps)
      if (!g.softened) g,
  ];
}

/// Reviews the spread of leaders on one run: which stretches of the pace axis
/// a group with a confirmed leader covers, and where there are gaps.
///
/// Only groups with at least one leader count. A single pace covers the pace
/// plus or minus [tolerance]; a range covers its ends (D28). Groups with no
/// pace do not use the axis. The window is [defaultCoverageWindow] for [unit],
/// widened for any band outside it.
CoverageReport buildCoverage({
  required List<Group> groups,
  required DistUnit unit,
  double tolerance = PaceSpec.singleToleranceSecPerKm,
  double minGap = minCoverageGapSecPerKm,
}) {
  final needsLeader = <Group>[];
  final paced = <Group>[];
  final noPace = <Group>[];
  for (final g in groups) {
    if (g.isDeleted) continue;
    if (g.leaders.isEmpty) {
      needsLeader.add(g);
    } else if (g.pace.band(tolerance: tolerance) == null) {
      noPace.add(g);
    } else {
      paced.add(g);
    }
  }
  double fastOf(Group g) => g.pace.fastest!.secondsPerKm;
  paced.sort((a, b) => fastOf(a).compareTo(fastOf(b)));

  final window = defaultCoverageWindow(unit);
  var windowFast = window.fast;
  var windowSlow = window.slow;
  final raw = [for (final g in paced) g.pace.band(tolerance: tolerance)!]
    ..sort((a, b) => a.fast.compareTo(b.fast));
  for (final b in raw) {
    windowFast = math.min(windowFast, b.fast);
    windowSlow = math.max(windowSlow, b.slow);
  }

  // Merge overlapping or touching bands.
  final bands = <CoverageBand>[];
  for (final b in raw) {
    if (bands.isNotEmpty && b.fast <= bands.last.slowS) {
      final last = bands.removeLast();
      bands.add(CoverageBand(last.fastS, math.max(last.slowS, b.slow)));
    } else {
      bands.add(CoverageBand(b.fast, b.slow));
    }
  }

  final hasJogWalk = noPace.any((g) => g.kind == 'jog_walk');
  final gaps = <CoverageGap>[];
  if (bands.isNotEmpty) {
    if (bands.first.fastS - windowFast >= minGap) {
      gaps.add(
        CoverageGap(
          kind: CoverageGapKind.fasterEnd,
          fastS: windowFast,
          slowS: bands.first.fastS,
        ),
      );
    }
    for (var i = 0; i + 1 < bands.length; i++) {
      final from = bands[i].slowS;
      final to = bands[i + 1].fastS;
      if (to - from >= minGap) {
        gaps.add(
          CoverageGap(kind: CoverageGapKind.between, fastS: from, slowS: to),
        );
      }
    }
    if (windowSlow - bands.last.slowS >= minGap) {
      gaps.add(
        CoverageGap(
          kind: CoverageGapKind.slowerEnd,
          fastS: bands.last.slowS,
          slowS: windowSlow,
          softened: hasJogWalk,
        ),
      );
    }
  }

  double slowOf(Group g) => g.pace.slowest!.secondsPerKm;
  return CoverageReport(
    unit: unit,
    windowFastS: windowFast,
    windowSlowS: windowSlow,
    bands: bands,
    gaps: gaps,
    pacedLed: paced,
    noPaceLed: noPace,
    needsLeader: needsLeader,
    hasJogWalk: hasJogWalk,
    fastestLed: paced.isEmpty ? null : paced.first,
    slowestLed: paced.isEmpty
        ? null
        : paced.reduce((a, b) => slowOf(a) >= slowOf(b) ? a : b),
  );
}
