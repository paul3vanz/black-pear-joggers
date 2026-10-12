import 'package:intl/intl.dart';

import '../../../core/util/clock_time.dart';

import '../../../core/db/app_database.dart';
import '../data/runs_repository.dart';

/// How far ahead the Runs list looks (the server generates 8 weeks).
const listHorizonDays = 56;

/// `yyyy-MM-dd` -> a calendar date (no time zone: midday avoids DST edges).
DateTime parseLocalDate(String localDate) {
  final p = localDate.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), 12);
}

/// "Today", "Tomorrow" or "Mon 12 Oct" for a club-local date string.
String dayHeader(String localDate, DateTime now) {
  final today = localDateString(now);
  if (localDate == today) return 'Today';
  if (localDate == localDateString(now.add(const Duration(days: 1)))) {
    return 'Tomorrow';
  }
  return DateFormat('EEE d MMM').format(parseLocalDate(localDate));
}

/// Full date for the detail screen, e.g. "Monday 12 October".
String longDate(String localDate) =>
    DateFormat('EEEE d MMMM').format(parseLocalDate(localDate));

/// "7-8:30pm", or just "7pm" when the run has no end time (D48).
String timeRange(String start, String? end) => formatClockRange(start, end);

/// Upcoming sessions grouped by `localDate` (input already ordered), limited to
/// the next [listHorizonDays] days.
List<(String, List<Session>)> groupByDay(List<Session> sessions, DateTime now) {
  final last = localDateString(now.add(const Duration(days: listHorizonDays)));
  final groups = <(String, List<Session>)>[];
  for (final s in sessions) {
    if (s.localDate.compareTo(last) > 0) continue;
    if (groups.isNotEmpty && groups.last.$1 == s.localDate) {
      groups.last.$2.add(s);
    } else {
      groups.add((s.localDate, [s]));
    }
  }
  return groups;
}

/// "HH:mm" -> minutes since midnight, or null if malformed.
int? parseHm(String hm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hm);
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// Minutes since midnight -> "HH:mm" (wraps past midnight).
String formatHm(int minutes) {
  final m = minutes % (24 * 60);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// The end `HH:mm` for a start plus [durationMin], or null when the run has no
/// duration (D47).
String? endTimeFor(String start, int? durationMin) {
  final s = parseHm(start);
  if (s == null || durationMin == null) return null;
  return formatHm(s + durationMin);
}

/// Duration in minutes between two "HH:mm" strings (wraps past midnight);
/// 60 if either is malformed.
int durationBetween(String start, String end) {
  final s = parseHm(start);
  final e = parseHm(end);
  if (s == null || e == null) return 60;
  final d = (e - s) % (24 * 60);
  return d == 0 ? 60 : d;
}

/// Weekday names for ISO weekday numbers 1..7.
const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// A maps link for [venue]: coordinates when known, otherwise a text search on
/// name and address. Null if there is nothing to search for.
Uri? mapsUrl(Venue venue) {
  final String query;
  if (venue.lat != null && venue.lng != null) {
    query = '${venue.lat},${venue.lng}';
  } else {
    query = [
      venue.name,
      if (venue.address != null) venue.address!,
    ].where((p) => p.trim().isNotEmpty).join(', ');
  }
  if (query.isEmpty) return null;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
}
