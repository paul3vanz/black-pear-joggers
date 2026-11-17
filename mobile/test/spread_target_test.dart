import 'dart:convert';
import 'dart:io';

import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/groups/data/group_dtos.dart';
import 'package:bpj/features/groups/logic/spread_target.dart';
import 'package:flutter_test/flutter_test.dart';

const _jo = GroupLeader(memberId: 'jo', displayName: 'Jo', role: 'leader');

Group _group(Map<String, Object?> json, int i) {
  final from = json['from'] as int?;
  return Group(
    id: 'g$i',
    sessionId: 'a',
    kind: json['kind'] as String? ?? 'run',
    paceUnit: from == null ? null : json['unit'] as String?,
    paceFromS: from,
    paceToS: json['to'] as int?,
    leaders: (json['led'] as bool? ?? true) ? const [_jo] : const [],
    status: (json['led'] as bool? ?? true) ? 'active' : 'needs_leader',
  );
}

/// The spread rule (D134, which replaced D128's numbers), against the case
/// table the API's PaceSpreadTest reads too
/// (api/tests/fixtures/spread_target_cases.json). The expected values there are
/// worked by hand, so each side proves its own copy of the rule.
void main() {
  final table = jsonDecode(
    File('../api/tests/fixtures/spread_target_cases.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final cases = (table['cases']! as List).cast<Map<String, Object?>>();

  for (final c in cases) {
    test('shared table: ${c['name']}', () {
      final unit = DistUnit.fromCode(c['unit'])!;
      final spread = buildSpreadTarget([
        for (final (i, g) in (c['groups']! as List).indexed)
          _group((g as Map).cast<String, Object?>(), i),
      ]);
      final expected = (c['expect']! as Map).cast<String, Object?>();
      int whole(double perKm) => (perKm * unit.kmPerUnit).round();

      expect(spread.empty, expected['empty'], reason: 'empty');
      expect(
        [
          for (final g in spread.gaps) [whole(g.fastS), whole(g.slowS)],
        ],
        (expected['gaps']! as List).map((e) => (e as List).cast<int>()),
        reason: 'gaps',
      );
      expect(
        spread.fasterEnd == null ? null : whole(spread.fasterEnd!.edgeS),
        expected['fasterEnd'],
        reason: 'fasterEnd',
      );
      expect(
        spread.slowerEnd == null ? null : whole(spread.slowerEnd!.edgeS),
        expected['slowerEnd'],
        reason: 'slowerEnd',
      );
      expect(spread.jogWalk, expected['jogWalk'], reason: 'jogWalk');
    });
  }

  group('what the screens read', () {
    Group led(int from, {int? to, String kind = 'run', bool pace = true}) =>
        Group(
          id: 'g$from',
          sessionId: 'a',
          kind: kind,
          paceUnit: pace ? 'mi' : null,
          paceFromS: pace ? from : null,
          paceToS: pace ? to : null,
          leaders: const [_jo],
        );

    test('a gap names its neighbours and the paces needed', () {
      // 9:15 and 10:30: 75 s apart, so a range of the span really uncovered.
      final s = buildSpreadTarget([led(555), led(630)]);
      final gap = s.gaps.single;

      expect([gap.fromIn(DistUnit.mi), gap.toIn(DistUnit.mi)], [555, 630]);
      expect(gap.isSingleIn(DistUnit.mi), isFalse);
      expect([gap.fastIn(DistUnit.mi), gap.slowIn(DistUnit.mi)], [585, 600]);
      expect(s.fasterEnd!.nearestIn(DistUnit.mi), 555);
      expect(s.fasterEnd!.edgeIn(DistUnit.mi), 525); // 8:45
      expect(s.slowerEnd!.nearestIn(DistUnit.mi), 630);
      expect(s.slowerEnd!.edgeIn(DistUnit.mi), 660); // 11:00
    });

    test('more than 30 s is a gap, 30 s or less is not', () {
      expect(buildSpreadTarget([led(480), led(510)]).gaps, isEmpty);
      expect(buildSpreadTarget([led(480), led(511)]).gaps, hasLength(1));
      // Measured slow edge to fast edge: a range covering it hides nothing.
      expect(
        buildSpreadTarget([led(480, to: 600), led(540), led(620)]).gaps,
        isEmpty,
      );
    });

    test('30-60 s is one pace (the middle), over 60 s a range', () {
      final one = buildSpreadTarget([led(555), led(615)]).gaps.single;
      expect(one.single, isTrue);
      expect([one.fastIn(DistUnit.mi), one.slowIn(DistUnit.mi)], [585, 585]);

      final range = buildSpreadTarget([led(525), led(675)]).gaps.single;
      expect(range.single, isFalse);
      expect(
        [range.fastIn(DistUnit.mi), range.slowIn(DistUnit.mi)],
        [555, 645],
      );
    });

    test('open ends are measured from the edge of the nearest group', () {
      // 10:30-11:00: need 10:00 or faster, 11:30 or slower.
      final a = buildSpreadTarget([led(630, to: 660)]);
      expect(a.fasterEnd!.edgeIn(DistUnit.mi), 600);
      expect(a.slowerEnd!.edgeIn(DistUnit.mi), 690);
      expect(a.fasterEnd!.nearestIn(DistUnit.mi), 630);
      expect(a.slowerEnd!.nearestIn(DistUnit.mi), 660);

      // A single 8:45: 8:15 or faster, 9:15 or slower.
      final b = buildSpreadTarget([led(525)]);
      expect(b.fasterEnd!.edgeIn(DistUnit.mi), 495);
      expect(b.slowerEnd!.edgeIn(DistUnit.mi), 555);
    });

    test('an end within 30 s of 8:00 or 12:00 is met', () {
      expect(buildSpreadTarget([led(510)]).fasterEnd, isNull);
      expect(buildSpreadTarget([led(511)]).fasterEnd, isNotNull);
      expect(buildSpreadTarget([led(690)]).slowerEnd, isNull);
      expect(buildSpreadTarget([led(689)]).slowerEnd, isNotNull);
    });

    test('the same rule in km, converted only for display', () {
      // 6:30/km is 10:27/mi; 30 s/mi is about 19 s/km, shown to whole 15 s.
      final s = buildSpreadTarget([led(630, to: 660)]);
      expect(s.fasterEnd!.edgeIn(DistUnit.km), 375); // 6:15/km
      expect(s.slowerEnd!.edgeIn(DistUnit.km), 435); // 7:15/km
    });

    test('counts red and amber items', () {
      // Nothing led: the whole target is the one red item; only jog/walk is amber.
      expect(buildSpreadTarget([]).redCount, 1);
      expect(buildSpreadTarget([]).amberCount, 1);

      final s = buildSpreadTarget([led(555), led(630)]);
      expect(s.redCount, 1);
      expect(s.amberCount, 3); // both ends and jog/walk

      final full = buildSpreadTarget([
        led(465, to: 480),
        for (final p in [510, 540, 570, 600, 630, 660, 690]) led(p),
        led(0, kind: 'jog_walk', pace: false),
      ]);
      expect(full.needsAttention, isFalse);
      expect(full.redCount, 0);
      expect(full.amberCount, 0);
    });

    test('an unled or deleted group counts for nothing', () {
      final unled = Group(
        id: 'u',
        sessionId: 'a',
        paceUnit: 'mi',
        paceFromS: 540,
        status: 'needs_leader',
      );
      expect(buildSpreadTarget([unled]).empty, isTrue);
      expect(
        buildSpreadTarget([
          Group(
            id: 'd',
            sessionId: 'a',
            paceUnit: 'mi',
            paceFromS: 540,
            leaders: const [_jo],
            deletedAt: DateTime(2026),
          ),
        ]).empty,
        isTrue,
      );
    });
  });
}
