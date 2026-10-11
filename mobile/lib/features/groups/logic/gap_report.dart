import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';
import '../data/plan_dtos.dart';
import 'pace_spread.dart';

/// Someone going or maybe, with the pace the plan holds for them (their
/// per-run override, else their usual range).
class GapMember {
  const GapMember({
    required this.memberId,
    required this.name,
    required this.status,
    required this.pace,
  });

  final String memberId;
  final String name;
  final String status;
  final PaceSpec pace;

  factory GapMember.fromAttendee(PlanAttendee a) => GapMember(
    memberId: a.memberId,
    name: a.displayName,
    status: a.status,
    pace: a.pace,
  );
}

/// One pace slot with the people in it and how many no group covers.
class GapBucket {
  const GapBucket({
    required this.fromS,
    required this.toS,
    required this.members,
    required this.uncovered,
  });

  final int fromS;
  final int toS;
  final List<GapMember> members;
  final List<GapMember> uncovered;

  int get count => members.length;
  bool get isGap => uncovered.isNotEmpty;
}

/// A run of neighbouring buckets with uncovered people, e.g. "10:00-10:30".
class PaceGap {
  const PaceGap({
    required this.fromS,
    required this.toS,
    required this.members,
  });

  final int fromS;
  final int toS;
  final List<GapMember> members;

  int get count => members.length;
}

class GapReport {
  const GapReport({
    required this.unit,
    required this.buckets,
    required this.gaps,
    required this.noPace,
  });

  final DistUnit unit;

  /// Only the buckets that have people, fastest first.
  final List<GapBucket> buckets;

  /// Merged neighbouring uncovered buckets, fastest first.
  final List<PaceGap> gaps;

  /// Going or maybe, with no pace to match on.
  final List<GapMember> noPace;

  int get uncoveredCount => gaps.fold(0, (n, g) => n + g.count);
  int get withPaceCount => buckets.fold(0, (n, b) => n + b.count);
  bool get hasGaps => gaps.isNotEmpty;
}

/// Compares who is coming with the pace bands the groups offer.
///
/// [members] are everyone going or maybe (grouped or not). Each is bucketed by
/// their effective pace in [unit]. A member is covered when some group's band
/// overlaps theirs (single paces get the shared tolerance, ranges are exact);
/// groups with no pace cover nobody. Members with no pace go to `noPace`.
GapReport buildGapReport({
  required List<GapMember> members,
  required List<PaceSpec> groups,
  required DistUnit unit,
  int? bucketSeconds,
  double tolerance = PaceSpec.singleToleranceSecPerKm,
}) {
  final width = bucketSeconds ?? defaultBucketSeconds(unit);
  final noPace = <GapMember>[];
  final byIndex = <int, List<GapMember>>{};
  for (final m in members) {
    final mid = effectiveSeconds(m.pace, unit);
    if (mid == null) {
      noPace.add(m);
    } else {
      (byIndex[mid ~/ width] ??= []).add(m);
    }
  }
  bool covered(GapMember m) =>
      groups.any((g) => g.overlaps(m.pace, tolerance: tolerance));
  final indexes = byIndex.keys.toList()..sort();
  final buckets = [
    for (final i in indexes)
      GapBucket(
        fromS: i * width,
        toS: (i + 1) * width,
        members: byIndex[i]!,
        uncovered: [
          for (final m in byIndex[i]!)
            if (!covered(m)) m,
        ],
      ),
  ];
  final gaps = <PaceGap>[];
  int? lastIndex;
  for (var k = 0; k < buckets.length; k++) {
    final b = buckets[k];
    if (!b.isGap) continue;
    final index = indexes[k];
    if (gaps.isNotEmpty && lastIndex == index - 1) {
      final g = gaps.removeLast();
      gaps.add(
        PaceGap(
          fromS: g.fromS,
          toS: b.toS,
          members: [...g.members, ...b.uncovered],
        ),
      );
    } else {
      gaps.add(
        PaceGap(fromS: b.fromS, toS: b.toS, members: List.of(b.uncovered)),
      );
    }
    lastIndex = index;
  }
  return GapReport(unit: unit, buckets: buckets, gaps: gaps, noPace: noPace);
}

/// The members for a gap report from a plan: everyone going or maybe whose
/// name the caller may see (unassigned members plus every group's attendees).
/// Null when the plan holds no names for the caller (not committee).
List<GapMember>? gapMembers(SessionPlan plan) {
  final unassigned = plan.unassigned.members;
  if (unassigned == null) return null;
  final seen = <String>{};
  return [
    for (final a in [
      ...unassigned,
      for (final g in plan.groups) ...?g.attendees,
    ])
      if (a.status != 'not_going' && seen.add(a.memberId))
        GapMember.fromAttendee(a),
  ];
}
