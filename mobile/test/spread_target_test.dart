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

/// D128: the rule against the case table the server's PaceSpreadTest reads too
/// (api/tests/fixtures/spread_target_cases.json). The expected values there are
/// worked by hand, so each side proves its own copy of the rule.
void main() {
  final table = jsonDecode(
    File('../api/tests/fixtures/spread_target_cases.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final cases = (table['cases']! as List).cast<Map<String, Object?>>();

  test('the shared table has the cases the plan names', () {
    expect(cases.length, greaterThan(15));
  });

  for (final c in cases) {
    test(c['name']! as String, () {
      final unit = DistUnit.fromCode(c['unit'])!;
      final groups = [
        for (final (i, g) in (c['groups']! as List).indexed)
          _group((g as Map).cast<String, Object?>(), i),
      ];
      final spread = buildSpreadTarget(groups);
      final expected = (c['expect']! as Map).cast<String, Object?>();

      expect(spread.empty, expected['empty'], reason: 'empty');
      expect(
        [
          for (final g in spread.gaps) [g.fastIn(unit), g.slowIn(unit)],
        ],
        (expected['gaps']! as List).map((e) => (e as List).cast<int>()),
        reason: 'gaps',
      );
      expect(
        spread.fasterEnd?.edgeIn(unit),
        expected['fasterEnd'],
        reason: 'fasterEnd',
      );
      expect(
        spread.slowerEnd?.edgeIn(unit),
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

    test('a gap names its neighbours and the stretch', () {
      final s = buildSpreadTarget([led(555), led(630)]);
      final gap = s.gaps.single;

      expect([gap.fromIn(DistUnit.mi), gap.toIn(DistUnit.mi)], [555, 630]);
      expect([gap.fastIn(DistUnit.mi), gap.slowIn(DistUnit.mi)], [570, 615]);
      expect(s.fasterEnd!.nearestIn(DistUnit.mi), 555);
      expect(s.slowerEnd!.nearestIn(DistUnit.mi), 630);
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
        for (final p in [520, 560, 600, 640, 680, 720]) led(p),
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
