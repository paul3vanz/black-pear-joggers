import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/data/plan_dtos.dart';
import 'package:bpj/features/groups/logic/gap_report.dart';
import 'package:flutter_test/flutter_test.dart';

PaceSpec single(int s, [DistUnit u = DistUnit.mi]) => SinglePace(Pace(s, u));

PaceSpec range(int a, int b, [DistUnit u = DistUnit.mi]) =>
    PaceRange(Pace(a, u), Pace(b, u));

GapMember who(String id, PaceSpec pace) =>
    GapMember(memberId: id, name: 'M $id', status: 'going', pace: pace);

void main() {
  group('buildGapReport', () {
    test('everyone is a gap when there are no groups', () {
      final r = buildGapReport(
        members: [who('a', single(600)), who('b', single(610))],
        groups: const [],
        unit: DistUnit.mi,
      );
      expect(r.hasGaps, isTrue);
      expect(r.gaps, hasLength(1));
      expect(r.gaps.first.count, 2);
      expect((r.gaps.first.fromS, r.gaps.first.toS), (600, 630));
    });

    test('full coverage has no gaps', () {
      final r = buildGapReport(
        members: [who('a', single(600)), who('b', single(660))],
        groups: [range(570, 700)],
        unit: DistUnit.mi,
      );
      expect(r.hasGaps, isFalse);
      expect(r.withPaceCount, 2);
    });

    test('a partial gap names only the uncovered bucket', () {
      final r = buildGapReport(
        members: [
          who('a', single(540)), // covered
          who('b', single(660)), // gap
          who('c', single(670)), // gap, same bucket
        ],
        groups: [range(520, 570)],
        unit: DistUnit.mi,
      );
      expect(r.buckets, hasLength(2));
      expect(r.gaps, hasLength(1));
      expect(r.gaps.first.members.map((m) => m.memberId), ['b', 'c']);
      expect((r.gaps.first.fromS, r.gaps.first.toS), (660, 690));
    });

    test('merges neighbouring gap buckets but not separated ones', () {
      final r = buildGapReport(
        members: [
          who('a', single(600)),
          who('b', single(640)),
          who('c', single(760)),
        ],
        groups: const [],
        unit: DistUnit.mi,
      );
      // 600 and 640 are buckets 600 and 630: adjacent. 760 is separate.
      expect(r.gaps, hasLength(2));
      expect((r.gaps[0].fromS, r.gaps[0].toS), (600, 660));
      expect((r.gaps[1].fromS, r.gaps[1].toS), (750, 780));
    });

    test('a single-pace group covers neighbours inside the tolerance', () {
      // 600 s/mi group; 15 s/km tolerance is about 24 s/mi each side.
      final near = buildGapReport(
        members: [who('a', single(620))],
        groups: [single(600)],
        unit: DistUnit.mi,
      );
      expect(near.hasGaps, isFalse);
      final far = buildGapReport(
        members: [who('a', single(700))],
        groups: [single(600)],
        unit: DistUnit.mi,
      );
      expect(far.hasGaps, isTrue);
    });

    test('a member range is covered by any overlapping group', () {
      final r = buildGapReport(
        members: [who('a', range(560, 620))],
        groups: [range(610, 700)],
        unit: DistUnit.mi,
      );
      expect(r.hasGaps, isFalse);
    });

    test('groups with no pace cover nobody', () {
      final r = buildGapReport(
        members: [who('a', single(600))],
        groups: const [NoPace()],
        unit: DistUnit.mi,
      );
      expect(r.hasGaps, isTrue);
    });

    test('lists members without a pace separately', () {
      final r = buildGapReport(
        members: [who('a', const NoPace()), who('b', single(600))],
        groups: [single(600)],
        unit: DistUnit.mi,
      );
      expect(r.noPace.map((m) => m.memberId), ['a']);
      expect(r.withPaceCount, 1);
      expect(r.hasGaps, isFalse);
    });

    test('works in km with 20 s buckets', () {
      final r = buildGapReport(
        members: [who('a', single(350, DistUnit.km))],
        groups: const [],
        unit: DistUnit.km,
      );
      expect((r.gaps.first.fromS, r.gaps.first.toS), (340, 360));
    });

    test('buckets a mile pace by its km value for a km viewer', () {
      // 9:00/mi is 5:35/km: bucket 320-340.
      final r = buildGapReport(
        members: [who('a', single(540))],
        groups: const [],
        unit: DistUnit.km,
      );
      expect((r.gaps.first.fromS, r.gaps.first.toS), (320, 340));
    });
  });

  group('gapMembers', () {
    test('is null when the plan has no names for the caller', () {
      expect(gapMembers(const SessionPlan(sessionId: 's')), isNull);
    });

    test('merges unassigned and group attendees, skipping duplicates', () {
      const a = PlanAttendee(
        memberId: 'a',
        displayName: 'A',
        status: 'going',
        paceUnit: 'mi',
        paceFromS: 600,
      );
      const b = PlanAttendee(memberId: 'b', displayName: 'B', status: 'maybe');
      final plan = SessionPlan(
        sessionId: 's',
        unassigned: const UnassignedPlan(members: [a]),
        groups: const [
          GroupPlan(groupId: 'g', attendees: [a, b]),
        ],
      );
      expect(gapMembers(plan)!.map((m) => m.memberId), ['a', 'b']);
    });
  });
}
