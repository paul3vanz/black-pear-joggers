import 'dart:convert';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/data/session_changes.dart';
import 'package:bpj/features/runs/ui/run_format.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

Session session({
  String start = '19:00',
  String title = 'Monday club run',
  String? venueId = 'v1',
  String status = 'scheduled',
  Map<String, Object?>? original,
}) => Session(
  id: 's',
  clubId: 1,
  title: title,
  venueId: venueId,
  startsAt: DateTime.utc(2026, 10, 12, 18),
  endsAt: DateTime.utc(2026, 10, 12, 19, 30),
  localDate: '2026-10-12',
  localStartTime: start,
  localEndTime: '20:30',
  groupMode: 'paced',
  status: status,
  isDetached: original != null,
  originalJson: original == null ? null : jsonEncode(original),
  updatedAt: DateTime.utc(2026, 10, 5),
);

void main() {
  const usual = {
    'localStartTime': '19:00',
    'venueId': 'v1',
    'title': 'Monday club run',
  };
  String? names(String id) => {'v1': 'OECC', 'v2': 'Perdiswell'}[id];

  group('sessionChanges', () {
    test('no original means no changes', () {
      expect(sessionChanges(session()), isEmpty);
    });

    test('original equal to the session means no changes', () {
      expect(sessionChanges(session(original: usual)), isEmpty);
    });

    test('moved venue names the old venue', () {
      final s = session(venueId: 'v2', original: usual);
      expect(sessionChanges(s, venueName: names), ['Moved from OECC']);
    });

    test('moved venue with an unknown old venue is generic', () {
      final s = session(venueId: 'v2', original: usual);
      expect(sessionChanges(s), ['Venue changed']);
    });

    test('different start time', () {
      final s = session(start: '18:30', original: usual);
      expect(sessionChanges(s), ['Starts at 6:30pm (usually 7pm)']);
    });

    test('renamed', () {
      final s = session(title: 'Social run', original: usual);
      expect(sessionChanges(s), ['Renamed (usually "Monday club run")']);
    });

    test('several changes at once', () {
      final s = session(
        start: '18:30',
        venueId: 'v2',
        title: 'Social run',
        original: usual,
      );
      expect(sessionChanges(s, venueName: names), hasLength(3));
    });

    test('cancelled runs show no change labels', () {
      final s = session(start: '18:30', status: 'cancelled', original: usual);
      expect(sessionChanges(s), isEmpty);
    });

    test('malformed original JSON is ignored', () {
      final s = session().copyWith(originalJson: const Value('{not json'));
      expect(sessionChanges(s), isEmpty);
    });
  });

  group('run_format', () {
    final now = DateTime(2026, 10, 7, 9);

    test('day headers', () {
      expect(dayHeader('2026-10-07', now), 'Today');
      expect(dayHeader('2026-10-08', now), 'Tomorrow');
      expect(dayHeader('2026-10-12', now), 'Mon 12 Oct');
    });

    test('groupByDay groups and limits to the horizon', () {
      final groups = groupByDay([
        session().copyWith(id: 'a', localDate: '2026-10-12'),
        session().copyWith(id: 'b', localDate: '2026-10-12'),
        session().copyWith(id: 'c', localDate: '2026-10-14'),
        session().copyWith(id: 'far', localDate: '2027-03-01'),
      ], now);
      expect(groups.map((g) => g.$1), ['2026-10-12', '2026-10-14']);
      expect(groups.first.$2, hasLength(2));
    });

    test('durationBetween', () {
      expect(durationBetween('19:00', '20:30'), 90);
      expect(durationBetween('23:30', '00:30'), 60);
    });
  });
}
