import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace.dart';
import '../../../core/units/pace_spec.dart';
import '../data/plan_dtos.dart';

/// Histogram bucket width in seconds per [unit]: 30 s/mile or 20 s/km.
int defaultBucketSeconds(DistUnit unit) => unit == DistUnit.mi ? 30 : 20;

/// The pace that stands for a person in a histogram: a single pace as is, and
/// the middle of a range. Seconds per [unit]; null with no pace.
double? effectiveSeconds(PaceSpec spec, DistUnit unit) {
  final fast = spec.fastest;
  final slow = spec.slowest;
  if (fast == null || slow == null) return null;
  return (fast.convertTo(unit).seconds + slow.convertTo(unit).seconds) / 2;
}

/// One bar of a pace histogram: people whose effective pace lies in
/// `[fromS, toS)`, in seconds per viewer unit.
class PaceBucket {
  const PaceBucket({
    required this.fromS,
    required this.toS,
    required this.count,
  });

  final int fromS;
  final int toS;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is PaceBucket &&
      other.fromS == fromS &&
      other.toS == toS &&
      other.count == count;

  @override
  int get hashCode => Object.hash(fromS, toS, count);

  @override
  String toString() => 'PaceBucket($fromS-$toS x$count)';
}

/// The anonymous pace distribution of a group.
class PaceSpread {
  const PaceSpread({
    required this.unit,
    required this.buckets,
    required this.total,
    this.fastest,
    this.slowest,
  });

  static const empty = PaceSpread(unit: DistUnit.mi, buckets: [], total: 0);

  final DistUnit unit;

  /// Contiguous buckets from the fastest to the slowest person, empty ones
  /// included so the strip keeps its scale.
  final List<PaceBucket> buckets;

  /// People with a pace.
  final int total;

  /// The fastest and slowest ends across everyone, in [unit].
  final Pace? fastest;
  final Pace? slowest;

  bool get isEmpty => total == 0;

  int get maxCount => buckets.fold(0, (m, b) => b.count > m ? b.count : m);
}

/// Buckets [paces] (everyone going or maybe, in s/km) into [bucketSeconds]
/// wide slots in the viewer's [unit]. A range counts once, in the bucket of
/// its middle; the spread's `fastest`/`slowest` keep the outer ends.
PaceSpread buildPaceSpread(
  List<PlanPace> paces,
  DistUnit unit, {
  int? bucketSeconds,
}) {
  final width = bucketSeconds ?? defaultBucketSeconds(unit);
  assert(width > 0, 'bucketSeconds must be positive');
  final specs = [
    for (final p in paces)
      if (!p.spec.isNone) p.spec,
  ];
  if (specs.isEmpty) return PaceSpread(unit: unit, buckets: const [], total: 0);
  final counts = <int, int>{};
  Pace? fastest;
  Pace? slowest;
  for (final spec in specs) {
    final mid = effectiveSeconds(spec, unit)!;
    final index = mid ~/ width;
    counts[index] = (counts[index] ?? 0) + 1;
    final f = spec.fastest!.convertTo(unit);
    final s = spec.slowest!.convertTo(unit);
    if (fastest == null || f.seconds < fastest.seconds) fastest = f;
    if (slowest == null || s.seconds > slowest.seconds) slowest = s;
  }
  final first = counts.keys.reduce((a, b) => a < b ? a : b);
  final last = counts.keys.reduce((a, b) => a > b ? a : b);
  return PaceSpread(
    unit: unit,
    buckets: [
      for (var i = first; i <= last; i++)
        PaceBucket(
          fromS: i * width,
          toS: (i + 1) * width,
          count: counts[i] ?? 0,
        ),
    ],
    total: specs.length,
    fastest: fastest,
    slowest: slowest,
  );
}

/// "9:30" for [seconds] (a bucket edge).
String mmss(int seconds) => Pace(seconds, DistUnit.mi).format();

/// "usually 8:30-9:45/mi", "about 9:00/mi", or '' when nobody has a pace.
String spreadRange(PaceSpread spread) {
  final fast = spread.fastest;
  final slow = spread.slowest;
  if (spread.isEmpty || fast == null || slow == null) return '';
  final code = spread.unit.code;
  if (fast.seconds == slow.seconds) return 'about ${fast.format()}/$code';
  return 'usually ${fast.format()}-${slow.format()}/$code';
}

/// "5 going · usually 8:30-9:45/mi", "1 going · about 9:00/mi" or just
/// "3 going" when nobody has set a pace. [going] and [maybe] are the group's
/// counts; the spread covers whoever has a pace.
String spreadSummary(PaceSpread spread, {required int going, int maybe = 0}) {
  final people = maybe > 0 ? '$going going, $maybe maybe' : '$going going';
  final range = spreadRange(spread);
  return range.isEmpty ? people : '$people · $range';
}
