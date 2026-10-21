import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/logic/coverage_report.dart';
import 'package:bpj/features/groups/ui/coverage_card.dart';
import 'package:flutter_test/flutter_test.dart';

const _jo = GroupLeader(memberId: 'jo', displayName: 'Jo', role: 'leader');

/// A led group with a single pace (or a range with [toS]) in [unit].
Group led(
  String id,
  int fromS, {
  int? toS,
  String unit = 'mi',
  String kind = 'run',
  bool leader = true,
  bool pace = true,
}) => Group(
  id: id,
  sessionId: 'a',
  kind: kind,
  paceUnit: pace ? unit : null,
  paceFromS: pace ? fromS : null,
  paceToS: pace ? toS : null,
  leaders: leader ? const [_jo] : const [],
  status: leader ? 'active' : 'needs_leader',
);

String text(CoverageReport r, [DistUnit unit = DistUnit.mi]) =>
    [for (final g in r.gaps) coverageGapText(g, unit)].join(' | ');

void main() {
  CoverageReport mi(List<Group> g) =>
      buildCoverage(groups: g, unit: DistUnit.mi);

  test('no groups at all', () {
    final r = mi([]);
    expect(r.isEmpty, isTrue);
    expect(r.hasBands, isFalse);
    expect(r.gaps, isEmpty);
  });

  test('the default window is 7:00-12:00/mi or 4:15-7:30/km', () {
    final r = mi([]);
    expect(r.windowFastS * 1.609344, closeTo(420, 0.01));
    expect(r.windowSlowS * 1.609344, closeTo(720, 0.01));
    final k = buildCoverage(groups: [], unit: DistUnit.km);
    expect([k.windowFastS, k.windowSlowS], [255, 450]);
  });

  test('one single pace covers it plus or minus the tolerance', () {
    final r = mi([led('a', 540)]);
    expect(r.bands, hasLength(1));
    expect(r.bands.single.slowS - r.bands.single.fastS, closeTo(30, 0.001));
    expect(r.fastestLed!.id, 'a');
    expect(r.slowestLed!.id, 'a');
    expect(r.gaps.map((g) => g.kind), [
      CoverageGapKind.fasterEnd,
      CoverageGapKind.slowerEnd,
    ]);
    expect(
      text(r),
      'No group faster than 8:35/mi | No group slower than 9:25/mi',
    );
  });

  test('ranges that overlap or touch merge into one band', () {
    final r = mi([
      led('a', 540, toS: 600),
      led('b', 590, toS: 660),
      led('c', 660, toS: 700),
    ]);
    expect(r.bands, hasLength(1));
    expect(r.fastestLed!.id, 'a');
    expect(r.slowestLed!.id, 'c');
    expect(r.gaps.where((g) => g.kind == CoverageGapKind.between), isEmpty);
  });

  test('a gap in the middle is named in the viewer unit', () {
    final r = mi([led('a', 480), led('b', 630)]);
    final between = r.gaps.singleWhere(
      (g) => g.kind == CoverageGapKind.between,
    );
    expect(coverageGapText(between, DistUnit.mi), startsWith('No led group'));
    expect(
      coverageGapText(between, DistUnit.mi),
      'No led group between 8:25 and 10:05/mi',
    );
  });

  test(
    'the ends of the window are information, a gap in the middle is not',
    () {
      final r = mi([led('a', 480), led('b', 630)]);
      final kinds = {for (final g in r.gaps) g.kind: g};
      expect(kinds[CoverageGapKind.fasterEnd]!.softened, isTrue);
      expect(kinds[CoverageGapKind.slowerEnd]!.softened, isTrue);
      expect(kinds[CoverageGapKind.between]!.softened, isFalse);
      // Only the middle gap is something to fill.
      expect(r.problems.map((g) => g.kind), [CoverageGapKind.between]);
      expect(
        coverageGapText(kinds[CoverageGapKind.slowerEnd]!, DistUnit.mi),
        startsWith('No group slower than'),
      );
    },
  );

  test('a single group leaves nothing to fill, only the two ends to note', () {
    final r = mi([led('a', 525)]); // 8:45/mi
    expect(r.problems, isEmpty);
    expect(r.gaps, hasLength(2));
  });

  test('a jog/walk group is listed apart and does not use the pace axis', () {
    final withJog = mi([
      led('a', 480),
      led('b', 570),
      led('j', 0, kind: 'jog_walk', pace: false),
    ]);
    expect(withJog.hasJogWalk, isTrue);
    expect(withJog.noPaceLed.single.id, 'j');
  });

  test('groups without a leader are listed apart and cover nothing', () {
    final r = mi([led('a', 540), led('x', 660, leader: false)]);
    expect(r.needsLeader.single.id, 'x');
    expect(r.pacedLed.single.id, 'a');
    expect(r.bands, hasLength(1));
    expect(r.slowestLed!.id, 'a');

    final only = mi([led('x', 660, leader: false)]);
    expect(only.onlyNeedsLeader, isTrue);
    expect(only.isEmpty, isFalse);
    expect(only.hasBands, isFalse);
    expect(only.gaps, isEmpty);
  });

  test('groups with no pace do not use the axis', () {
    final r = mi([
      led('e', 0, kind: 'efforts', pace: false),
      led('s', 0, kind: 'social', pace: false),
    ]);
    expect(r.noPaceLed, hasLength(2));
    expect(r.hasBands, isFalse);
    expect(r.hasJogWalk, isFalse);
    expect(r.ledCount, 2);
  });

  test('the km window and km wording', () {
    final r = buildCoverage(
      groups: [led('a', 360, unit: 'km')],
      unit: DistUnit.km,
    );
    expect([r.windowFastS, r.windowSlowS], [255, 450]);
    expect(
      text(r, DistUnit.km),
      'No group faster than 5:45/km | No group slower than 6:15/km',
    );
  });

  test('a group outside the window widens it', () {
    final r = mi([led('slow', 840)]);
    expect(r.windowSlowS, greaterThan(840 / 1.609344));
    expect(r.gaps.every((g) => g.slowS <= r.windowSlowS), isTrue);
    final fast = mi([led('fast', 360)]);
    expect(fast.windowFastS, lessThan(360 / 1.609344));
  });

  test('gaps under 20 s/km are ignored', () {
    List<CoverageGapKind> between(int toS) =>
        buildCoverage(
              groups: [
                led('a', 360, unit: 'km'),
                led('b', toS, unit: 'km'),
              ],
              unit: DistUnit.km,
            ).gaps
            .map((g) => g.kind)
            .where((k) => k == CoverageGapKind.between)
            .toList();
    // Bands are +/-15: 6:00 ends at 375, 6:40 starts at 385 (10 apart).
    expect(between(400), isEmpty);
    // 6:50 starts at 395: exactly 20 apart counts.
    expect(between(410), hasLength(1));
  });
}
