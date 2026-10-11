import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/data/plan_dtos.dart';
import 'package:bpj/features/groups/logic/pace_spread.dart';
import 'package:flutter_test/flutter_test.dart';

PlanPace p(int from, [int? to]) => PlanPace(fromSPerKm: from, toSPerKm: to);

void main() {
  group('buildPaceSpread', () {
    test('is empty with no paces', () {
      final s = buildPaceSpread(const [], DistUnit.mi);
      expect(s.isEmpty, isTrue);
      expect(s.buckets, isEmpty);
      expect(s.fastest, isNull);
    });

    test('one pace makes one 30 s/mi bucket', () {
      // 354 s/km is 9:30/mi.
      final s = buildPaceSpread([p(354)], DistUnit.mi);
      expect(s.total, 1);
      expect(s.buckets, [const PaceBucket(fromS: 570, toS: 600, count: 1)]);
      expect(s.fastest!.format(), '9:30');
      expect(s.slowest!.format(), '9:30');
    });

    test('fills the gaps between buckets with empty ones', () {
      // 9:30/mi (354 s/km) and 10:50/mi (404 s/km).
      final s = buildPaceSpread([p(354), p(354), p(404)], DistUnit.mi);
      expect(s.buckets.map((b) => (b.fromS, b.count)).toList(), [
        (570, 2),
        (600, 0),
        (630, 1),
      ]);
      expect(s.maxCount, 2);
    });

    test('a range counts once, in the bucket of its middle', () {
      // 354-373 s/km is 9:30-10:00/mi, middle 9:45 (585 s) -> bucket 570.
      final s = buildPaceSpread([p(354, 373)], DistUnit.mi);
      expect(s.total, 1);
      expect(s.buckets, [const PaceBucket(fromS: 570, toS: 600, count: 1)]);
      expect(s.fastest!.format(), '9:30');
      expect(s.slowest!.format(), '10:00');
    });

    test('a range overlapping two buckets still counts one person', () {
      // 9:20-10:10/mi: middle 9:45.
      final s = buildPaceSpread([p(348, 380)], DistUnit.mi);
      expect(s.buckets.fold<int>(0, (n, b) => n + b.count), 1);
    });

    test('uses 20 s buckets in km', () {
      // 354 s/km is 5:54/km; bucket 340-360.
      final s = buildPaceSpread([p(354), p(361)], DistUnit.km);
      expect(s.buckets.map((b) => (b.fromS, b.toS, b.count)).toList(), [
        (340, 360, 1),
        (360, 380, 1),
      ]);
      expect(s.unit, DistUnit.km);
    });

    test('mi and km views of the same paces agree on the extremes', () {
      final paces = [p(330), p(354, 373), p(400)];
      final mi = buildPaceSpread(paces, DistUnit.mi);
      final km = buildPaceSpread(paces, DistUnit.km);
      expect(km.fastest!.format(), '5:30');
      expect(km.slowest!.format(), '6:40');
      expect(mi.fastest!.format(), '8:51');
      expect(mi.slowest!.format(), '10:44');
      expect(mi.total, km.total);
    });

    test('honours a custom bucket width', () {
      final s = buildPaceSpread(
        [p(354), p(391)],
        DistUnit.mi,
        bucketSeconds: 60,
      );
      expect(s.buckets.first.fromS, 540);
      expect(s.buckets.first.toS, 600);
    });
  });

  group('spreadSummary', () {
    test('shows count and range', () {
      final s = buildPaceSpread([p(330), p(400)], DistUnit.mi);
      expect(
        spreadSummary(s, going: 5, maybe: 1),
        '5 going, 1 maybe · usually 8:51-10:44/mi',
      );
    });

    test('says "about" for a single pace', () {
      final s = buildPaceSpread([p(354)], DistUnit.mi);
      expect(spreadSummary(s, going: 1), '1 going · about 9:30/mi');
    });

    test('is just the count with no paces', () {
      expect(
        spreadSummary(buildPaceSpread(const [], DistUnit.km), going: 3),
        '3 going',
      );
    });
  });
}
