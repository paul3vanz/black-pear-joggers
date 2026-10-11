import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/distance.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:bpj/features/groups/ui/distance_input.dart';
import 'package:bpj/features/groups/ui/pace_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PaceFieldsCheck pace(
    PaceMode mode,
    String fast, [
    String slow = '',
    DistUnit unit = DistUnit.mi,
  ]) => checkPaceFields(mode: mode, unit: unit, fast: fast, slow: slow);

  group('checkPaceFields', () {
    test('none needs nothing', () {
      final c = pace(PaceMode.none, 'junk');
      expect(c.isValid, isTrue);
      expect(c.spec, const NoPace());
    });

    test('single parses m:ss in the chosen unit', () {
      expect(
        pace(PaceMode.single, '9:30').spec,
        const SinglePace(Pace(570, DistUnit.mi)),
      );
      expect(
        pace(PaceMode.single, '5:50', '', DistUnit.km).spec,
        const SinglePace(Pace(350, DistUnit.km)),
      );
    });

    test('a bad format is an error', () {
      for (final bad in ['', '9', '9.30', '9:5', '9:60', 'fast', '9:30:00']) {
        final c = pace(PaceMode.single, bad);
        expect(c.fastError, 'Enter a pace like 9:30', reason: bad);
        expect(c.spec, isNull);
      }
    });

    test('3:00 to 30:00 are the limits', () {
      expect(pace(PaceMode.single, '3:00').isValid, isTrue);
      expect(pace(PaceMode.single, '30:00').isValid, isTrue);
      expect(
        pace(PaceMode.single, '2:59').fastError,
        'Enter a pace from 3:00 to 30:00',
      );
      expect(
        pace(PaceMode.single, '30:01').fastError,
        'Enter a pace from 3:00 to 30:00',
      );
    });

    test('a range needs both ends, faster end first', () {
      final ok = pace(PaceMode.range, '9:00', '9:30');
      expect(
        ok.spec,
        PaceRange(const Pace(540, DistUnit.mi), const Pace(570, DistUnit.mi)),
      );
      expect(pace(PaceMode.range, '9:00', '9:00').isValid, isTrue);

      final reversed = pace(PaceMode.range, '9:30', '9:00');
      expect(reversed.isValid, isFalse);
      expect(reversed.slowError, contains('slower end'));
      expect(reversed.fastError, isNull);

      final missing = pace(PaceMode.range, '9:00');
      expect(missing.slowError, 'Enter a pace like 9:30');
      expect(missing.fastError, isNull);
    });
  });

  group('PaceInputController', () {
    test('starts from a spec and falls back to no pace when incomplete', () {
      final c = PaceInputController(
        initial: PaceRange(
          const Pace(300, DistUnit.km),
          const Pace(330, DistUnit.km),
        ),
        defaultUnit: DistUnit.mi,
      );
      addTearDown(c.dispose);
      expect(c.mode, PaceMode.range);
      expect(c.unit, DistUnit.km);
      expect(c.fast.text, '5:00');
      expect(c.slow.text, '5:30');
      expect(c.spec.display(DistUnit.km), '5:00-5:30/km');

      c.slow.text = 'x';
      expect(c.check().isValid, isFalse);
      expect(c.spec, const NoPace());
    });

    test('defaults to none in the viewer unit', () {
      final c = PaceInputController(defaultUnit: DistUnit.km);
      addTearDown(c.dispose);
      expect(c.mode, PaceMode.none);
      expect(c.unit, DistUnit.km);
    });
  });

  group('checkDistanceField', () {
    test('empty is fine and means no distance', () {
      final c = checkDistanceField('  ', DistUnit.mi);
      expect(c.isValid, isTrue);
      expect(c.distance, isNull);
    });

    test('parses with the unit, accepts a comma', () {
      expect(
        checkDistanceField('5.5', DistUnit.km).distance,
        const Distance(5.5, DistUnit.km),
      );
      expect(
        checkDistanceField('3,5', DistUnit.mi).distance,
        const Distance(3.5, DistUnit.mi),
      );
    });

    test('0.1 to 200 are the bounds', () {
      expect(checkDistanceField('0.1', DistUnit.mi).isValid, isTrue);
      expect(checkDistanceField('200', DistUnit.mi).isValid, isTrue);
      for (final bad in ['0.05', '201', '0']) {
        expect(
          checkDistanceField(bad, DistUnit.mi).error,
          isNotNull,
          reason: bad,
        );
      }
      expect(
        checkDistanceField('far', DistUnit.mi).error,
        'Enter a number like 5 or 5.5',
      );
    });
  });
}
