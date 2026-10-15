import 'package:bpj/core/units/dist_unit.dart';
import 'package:bpj/features/standards/data/standards_dtos.dart';
import 'package:bpj/features/standards/logic/standards_format.dart';
import 'package:bpj/features/standards/logic/standards_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api_phase9.dart';

void main() {
  group('DTO parsing', () {
    test('distanceM may be an int or a double', () {
      final data = StandardsData.fromJson(standardsJson());
      final byName = {for (final e in data.events) e.name: e.distanceM};
      expect(byName['5K'], 5000.0);
      expect(byName['Mile'], 1609.34);
      expect(byName['Half Marathon'], 21097.5);
    });

    test('reads awards, categories, items and mine', () {
      final data = StandardsData.fromJson(standardsJson());
      expect(data.awards, ['Bronze', 'Silver', 'Gold', 'Platinum']);
      expect(data.categoriesFor('female'), ['SEN', 'V50']);
      expect(data.categoriesFor('other'), isEmpty);
      expect(data.mine, const MyCategory(gender: 'female', category: 'V50'));
      expect(data.updatedAt, DateTime.utc(2026, 10, 15, 9, 30));
      final item = data.items.firstWhere(
        (i) => i.event == '5K' && i.gender == 'male' && i.category == 'SEN',
      );
      expect(item.time, '25:48');
    });

    test('tableFor groups by event then award', () {
      final table = StandardsData.fromJson(standardsJson())
          .tableFor('male', 'SEN');
      expect(table.keys, ['Mile', '5K', 'Half Marathon']);
      expect(table['5K']!['Bronze']!.time, '25:48');
      expect(table['5K']!['Bronze']!.timeS, 1548);
      expect(table['Half Marathon']!['Bronze']!.timeS, 7106);
    });

    test('tolerates missing optional fields and a null mine', () {
      final data = StandardsData.fromJson({
        'items': [
          // timeS missing: the time text is still shown.
          {
            'gender': 'male',
            'category': 'SEN',
            'event': 'Mile',
            'award': 'Bronze',
            'time': '7:25',
          },
          // time missing: it is worked out from seconds.
          {
            'gender': 'male',
            'category': 'SEN',
            'event': 'Mile',
            'award': 'Silver',
            'timeS': 400.0,
          },
          // Neither: dropped.
          {
            'gender': 'male',
            'category': 'SEN',
            'event': 'Mile',
            'award': 'Gold',
          },
          'junk',
        ],
        'events': [
          {'event': 'Mile', 'distanceM': '1609.34'},
          {'event': 'Bad'},
        ],
      });
      expect(data.awards, isEmpty);
      expect(data.categories, isEmpty);
      expect(data.mine, isNull);
      expect(data.updatedAt, isNull);
      expect(data.items.map((i) => i.time), ['7:25', '6:40']);
      expect(data.items.first.timeS, isNull);
      expect(data.events.single.distanceM, 1609.34);
    });

    test('an empty object parses to an empty document', () {
      final data = StandardsData.fromJson(const {});
      expect(data.items, isEmpty);
      expect(data.events, isEmpty);
    });
  });

  group('formatRaceTime', () {
    test('m:ss under an hour, h:mm:ss from an hour', () {
      expect(formatRaceTime(445), '7:25');
      expect(formatRaceTime(1548), '25:48');
      expect(formatRaceTime(59), '0:59');
      expect(formatRaceTime(3599), '59:59');
      expect(formatRaceTime(3600), '1:00:00');
      expect(formatRaceTime(7106), '1:58:26');
      expect(formatRaceTime(3 * 3600 + 5 * 60 + 9), '3:05:09');
    });
  });

  group('pace', () {
    test('5K in 25:48 is 8:18/mi and 5:10/km', () {
      expect(formatRacePace(1548, 5000, DistUnit.mi), '8:18/mi');
      expect(formatRacePace(1548, 5000, DistUnit.km), '5:10/km');
    });

    test('every event, per mile and per km', () {
      // (event metres, time in seconds, per mile, per km)
      final cases = [
        (1609.34, 480, '8:00/mi', '4:58/km'), // Mile 8:00
        (10000.0, 3000, '8:03/mi', '5:00/km'), // 10K 50:00
        (21097.5, 7106, '9:02/mi', '5:37/km'), // Half 1:58:26
        (42195.0, 14400, '9:09/mi', '5:41/km'), // Marathon 4:00:00
      ];
      for (final (metres, secs, mi, km) in cases) {
        expect(formatRacePace(secs, metres, DistUnit.mi), mi);
        expect(formatRacePace(secs, metres, DistUnit.km), km);
      }
    });

    test('paceForTime is a Pace in the requested unit', () {
      final p = paceForTime(1548, 5000, DistUnit.km);
      expect(p.seconds, 310);
      expect(p.unit, DistUnit.km);
    });
  });

  group('selection', () {
    final data = StandardsData.fromJson(standardsJson());
    final noMine = StandardsData.fromJson(standardsJson(mine: null));

    test('defaults to mine, else male SEN', () {
      expect(
        defaultSelection(data),
        const MyCategory(gender: 'female', category: 'V50'),
      );
      expect(
        defaultSelection(noMine),
        const MyCategory(gender: 'male', category: 'SEN'),
      );
    });

    test('a mine the table does not have falls back to male SEN', () {
      final odd = StandardsData.fromJson(
        standardsJson(mine: {'gender': 'female', 'category': 'V99'}),
      );
      expect(
        defaultSelection(odd),
        const MyCategory(gender: 'male', category: 'SEN'),
      );
    });

    test('switching gender keeps the category, or goes to mine, or SEN', () {
      const femaleV50 = MyCategory(gender: 'female', category: 'V50');
      // Mine is female V50, so going male keeps no V50 (male has V45): SEN.
      expect(
        selectionAfterGender(data, femaleV50, 'male'),
        const MyCategory(gender: 'male', category: 'SEN'),
      );
      // Back to female: mine.
      expect(
        selectionAfterGender(
          data,
          const MyCategory(gender: 'male', category: 'V45'),
          'female',
        ),
        femaleV50,
      );
      // No mine: SEN exists on both, so it carries over.
      expect(
        selectionAfterGender(
          noMine,
          const MyCategory(gender: 'male', category: 'SEN'),
          'female',
        ),
        const MyCategory(gender: 'female', category: 'SEN'),
      );
    });

    test('labels', () {
      expect(genderLabel('female'), 'Women');
      expect(genderNoun('male'), 'men');
    });
  });
}
