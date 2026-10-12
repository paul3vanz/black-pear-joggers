import 'package:bpj/core/util/clock_time.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatClock', () {
    const cases = {
      '19:00': '7pm',
      '19:30': '7:30pm',
      '07:05': '7:05am',
      '12:00': '12pm', // noon
      '12:30': '12:30pm',
      '00:00': '12am', // midnight
      '00:15': '12:15am',
      '23:59': '11:59pm',
      '9:00': '9am', // no leading zero needed on input
      '19:00:00': '7pm', // seconds ignored
    };
    cases.forEach((input, expected) {
      test('$input -> $expected', () => expect(formatClock(input), expected));
    });

    test('malformed input comes back unchanged', () {
      expect(formatClock(''), '');
      expect(formatClock('25:00'), '25:00');
      expect(formatClock('soon'), 'soon');
    });

    test('TimeOfDay', () {
      expect(formatClockOfDay(const TimeOfDay(hour: 19, minute: 30)), '7:30pm');
      expect(formatClockOfDay(const TimeOfDay(hour: 0, minute: 0)), '12am');
      expect(formatClockOfDay(const TimeOfDay(hour: 12, minute: 0)), '12pm');
    });
  });

  group('formatClockRange', () {
    const cases = {
      ('19:00', '20:30'): '7-8:30pm',
      ('11:00', '13:00'): '11am-1pm',
      ('09:00', '10:30'): '9-10:30am',
      ('12:00', '13:00'): '12-1pm',
      ('23:30', '00:30'): '11:30pm-12:30am',
      ('06:30', '07:30'): '6:30-7:30am',
    };
    cases.forEach((input, expected) {
      test('${input.$1}-${input.$2} -> $expected', () {
        expect(formatClockRange(input.$1, input.$2), expected);
      });
    });

    test('start only when there is no end', () {
      expect(formatClockRange('19:00', null), '7pm');
      expect(formatClockRange('19:30', ''), '7:30pm');
    });
  });
}
