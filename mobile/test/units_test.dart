import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/core/units/distance.dart';
import 'package:bpj/core/units/pace.dart';
import 'package:bpj/core/units/pace_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistUnit', () {
    test('codes and metres', () {
      expect(DistUnit.fromCode('mi'), DistUnit.mi);
      expect(DistUnit.fromCode('km'), DistUnit.km);
      expect(DistUnit.fromCode('x'), isNull);
      expect(DistUnit.fromCode(null), isNull);
      expect(DistUnit.mi.metres, 1609.344);
      expect(DistUnit.km.kmPerUnit, 1);
      expect(DistUnit.mi.kmPerUnit, closeTo(1.609344, 1e-9));
    });
  });

  group('Pace parse and format', () {
    test('accepts m:ss and mm:ss', () {
      expect(Pace.parse('9:30', DistUnit.mi).seconds, 570);
      expect(Pace.parse('10:05', DistUnit.km).seconds, 605);
      expect(Pace.parse(' 7:00 ', DistUnit.mi).seconds, 420);
      expect(Pace.parse('09:30', DistUnit.mi).seconds, 570);
    });

    test('rejects everything else', () {
      for (final bad in ['9.30', '9:60', '9:5', '930', '', 'abc', '9:3x']) {
        expect(Pace.tryParse(bad, DistUnit.mi), isNull, reason: bad);
        expect(() => Pace.parse(bad, DistUnit.mi), throwsFormatException);
      }
      expect(Pace.tryParse(null, DistUnit.mi), isNull);
      expect(Pace.tryParse('-9:30', DistUnit.mi), isNull);
      expect(Pace.tryParse('100:00', DistUnit.mi), isNull);
    });

    test('formats', () {
      expect(const Pace(570, DistUnit.mi).format(), '9:30');
      expect(const Pace(545, DistUnit.mi).format(), '9:05');
      expect(const Pace(570, DistUnit.mi).formatWithUnit(), '9:30/mi');
      expect(const Pace(1800, DistUnit.km).format(), '30:00');
    });

    test('server range check', () {
      expect(const Pace(180, DistUnit.km).isWithinServerRange, isTrue);
      expect(const Pace(1800, DistUnit.km).isWithinServerRange, isTrue);
      expect(const Pace(179, DistUnit.km).isWithinServerRange, isFalse);
      expect(const Pace(1801, DistUnit.km).isWithinServerRange, isFalse);
    });
  });

  group('Pace conversion', () {
    test('mile to km rounds to the nearest second', () {
      expect(
        const Pace(540, DistUnit.mi).convertTo(DistUnit.km).format(),
        '5:36',
      );
      expect(
        const Pace(480, DistUnit.mi).convertTo(DistUnit.km).format(),
        '4:58',
      );
      // Matches the API's derived paceFromSPerKm / paceToSPerKm examples.
      expect(const Pace(570, DistUnit.mi).convertTo(DistUnit.km).seconds, 354);
      expect(const Pace(600, DistUnit.mi).convertTo(DistUnit.km).seconds, 373);
    });

    test('km to mile rounds to the nearest second', () {
      expect(
        const Pace(300, DistUnit.km).convertTo(DistUnit.mi).format(),
        '8:03',
      );
      expect(
        const Pace(360, DistUnit.km).convertTo(DistUnit.mi).format(),
        '9:39',
      );
    });

    test('same unit is identity', () {
      const p = Pace(570, DistUnit.mi);
      expect(identical(p.convertTo(DistUnit.mi), p), isTrue);
    });

    test('secondsPerKm and comparison across units', () {
      expect(const Pace(300, DistUnit.km).secondsPerKm, 300);
      expect(const Pace(480, DistUnit.mi).secondsPerKm, closeTo(298.26, 0.01));
      const eightMi = Pace(480, DistUnit.mi);
      const fiveKm = Pace(300, DistUnit.km);
      expect(eightMi.isFasterThan(fiveKm), isTrue);
      expect(fiveKm.isSlowerThan(eightMi), isTrue);
      expect(eightMi.compareTo(fiveKm), lessThan(0));
      final sorted = [fiveKm, eightMi, const Pace(270, DistUnit.km)]..sort();
      expect(sorted.first.seconds, 270);
      expect(sorted.last, fiveKm);
    });

    test('equality is by seconds and unit', () {
      expect(const Pace(570, DistUnit.mi), const Pace(570, DistUnit.mi));
      expect(
        const Pace(570, DistUnit.mi) == const Pace(570, DistUnit.km),
        isFalse,
      );
    });
  });

  group('PaceSpec', () {
    test('fromFields picks none, single or range', () {
      expect(PaceSpec.fromFields(), isA<NoPace>());
      expect(PaceSpec.fromFields(unit: 'mi'), isA<NoPace>());
      expect(PaceSpec.fromFields(fromS: 570), isA<NoPace>());
      final single = PaceSpec.fromFields(unit: 'mi', fromS: 570);
      expect(single, const SinglePace(Pace(570, DistUnit.mi)));
      final range = PaceSpec.fromFields(unit: 'mi', fromS: 540, toS: 570);
      expect(
        range,
        PaceRange(const Pace(540, DistUnit.mi), const Pace(570, DistUnit.mi)),
      );
      expect(
        PaceSpec.fromFields(unit: 'km', fromS: 300, toS: 300),
        isA<SinglePace>(),
      );
      // A reversed range is put the right way round.
      expect(
        PaceSpec.fromFields(unit: 'km', fromS: 330, toS: 300),
        PaceRange(const Pace(300, DistUnit.km), const Pace(330, DistUnit.km)),
      );
    });

    test('toFields / toJson round trip', () {
      expect(const NoPace().toJson(), {
        'paceUnit': null,
        'paceFromS': null,
        'paceToS': null,
      });
      const single = SinglePace(Pace(570, DistUnit.mi));
      expect(single.toJson(), {
        'paceUnit': 'mi',
        'paceFromS': 570,
        'paceToS': null,
      });
      final range = PaceRange(
        const Pace(540, DistUnit.mi),
        const Pace(570, DistUnit.mi),
      );
      final f = range.toFields();
      expect(
        PaceSpec.fromFields(unit: f.unit, fromS: f.fromS, toS: f.toS),
        range,
      );
    });

    test('display in the same unit', () {
      expect(const NoPace().display(DistUnit.mi), '');
      expect(
        const SinglePace(Pace(570, DistUnit.mi)).display(DistUnit.mi),
        '9:30/mi',
      );
      expect(
        PaceRange(
          const Pace(540, DistUnit.mi),
          const Pace(570, DistUnit.mi),
        ).display(DistUnit.mi),
        '9:00-9:30/mi',
      );
    });

    test('display converts and keeps the original in brackets', () {
      expect(
        const SinglePace(Pace(540, DistUnit.mi)).display(DistUnit.km),
        '5:36/km (9:00/mi)',
      );
      expect(
        const SinglePace(Pace(480, DistUnit.mi)).display(DistUnit.km),
        '4:58/km (8:00/mi)',
      );
      expect(
        PaceRange(
          const Pace(540, DistUnit.mi),
          const Pace(570, DistUnit.mi),
        ).display(DistUnit.km),
        '5:36-5:54/km (9:00-9:30/mi)',
      );
      expect(
        const SinglePace(Pace(300, DistUnit.km)).display(DistUnit.mi),
        '8:03/mi (5:00/km)',
      );
    });

    test('fastest, slowest, isNone', () {
      expect(const NoPace().isNone, isTrue);
      expect(const NoPace().fastest, isNull);
      const single = SinglePace(Pace(570, DistUnit.mi));
      expect(single.fastest, single.slowest);
      final range = PaceRange(
        const Pace(540, DistUnit.mi),
        const Pace(570, DistUnit.mi),
      );
      expect(range.fastest?.seconds, 540);
      expect(range.slowest?.seconds, 570);
    });

    test(
      'contains uses the exact band for a range, a tolerance for single',
      () {
        final range = PaceRange(
          const Pace(540, DistUnit.mi),
          const Pace(570, DistUnit.mi),
        ); // 335.5 - 354.2 s/km
        expect(range.contains(340), isTrue);
        expect(range.contains(335.0), isFalse);
        expect(range.contains(355), isFalse);
        const single = SinglePace(Pace(300, DistUnit.km));
        expect(single.contains(310), isTrue);
        expect(single.contains(316), isFalse);
        expect(single.contains(316, tolerance: 20), isTrue);
        expect(const NoPace().contains(300), isFalse);
      },
    );

    test('overlaps compares bands across units', () {
      final a = PaceRange(
        const Pace(540, DistUnit.mi),
        const Pace(570, DistUnit.mi),
      );
      final b = PaceRange(
        const Pace(340, DistUnit.km),
        const Pace(400, DistUnit.km),
      );
      final c = PaceRange(
        const Pace(400, DistUnit.km),
        const Pace(450, DistUnit.km),
      );
      expect(a.overlaps(b), isTrue);
      expect(b.overlaps(a), isTrue);
      expect(a.overlaps(c), isFalse);
      expect(const SinglePace(Pace(350, DistUnit.km)).overlaps(a), isTrue);
      expect(const NoPace().overlaps(a), isFalse);
      expect(a.overlaps(const NoPace()), isFalse);
    });
  });

  group('Distance', () {
    test('parse', () {
      expect(Distance.parse('5', DistUnit.km), const Distance(5, DistUnit.km));
      expect(Distance.parse('5.5', DistUnit.mi).value, 5.5);
      expect(Distance.parse('5,5', DistUnit.mi).value, 5.5);
      for (final bad in ['', 'abc', '-1', '0', '5.', '.5', '1e3', '5 km']) {
        expect(Distance.tryParse(bad, DistUnit.mi), isNull, reason: bad);
      }
      expect(() => Distance.parse('x', DistUnit.mi), throwsFormatException);
    });

    test('conversion both ways', () {
      expect(
        const Distance(3, DistUnit.mi).convertTo(DistUnit.km).value,
        closeTo(4.828032, 1e-6),
      );
      expect(
        const Distance(5, DistUnit.km).convertTo(DistUnit.mi).value,
        closeTo(3.10686, 1e-4),
      );
      expect(const Distance(3, DistUnit.mi).metres, closeTo(4828.032, 1e-6));
      expect(const Distance(10, DistUnit.km).metres, 10000);
    });

    test('formatValue rounds to one decimal and drops .0', () {
      expect(Distance.formatValue(3), '3');
      expect(Distance.formatValue(3.04), '3');
      expect(Distance.formatValue(4.828), '4.8');
      expect(Distance.formatValue(5.5), '5.5');
      expect(Distance.formatValue(5.96), '6');
      expect(Distance.formatValue(0.25), '0.3');
    });

    test('display in the viewer unit with the original in brackets', () {
      expect(const Distance(3, DistUnit.mi).display(DistUnit.mi), '3 mi');
      expect(
        const Distance(3, DistUnit.mi).display(DistUnit.km),
        '4.8 km (3 mi)',
      );
      expect(
        const Distance(5, DistUnit.km).display(DistUnit.mi),
        '3.1 mi (5 km)',
      );
      expect(const Distance(10, DistUnit.km).display(DistUnit.km), '10 km');
      expect(
        const Distance(16, DistUnit.mi).display(DistUnit.km),
        '25.7 km (16 mi)',
      );
    });

    test('server range', () {
      expect(const Distance(0.1, DistUnit.km).isWithinServerRange, isTrue);
      expect(const Distance(0.05, DistUnit.km).isWithinServerRange, isFalse);
      expect(const Distance(200, DistUnit.km).isWithinServerRange, isTrue);
      expect(const Distance(201, DistUnit.km).isWithinServerRange, isFalse);
    });
  });
}
