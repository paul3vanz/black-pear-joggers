import 'package:flutter/material.dart' show TimeOfDay;

/// Club-style 12-hour times (D48): `7pm`, `7:30pm`, `12pm` (noon), `12am` (midnight).
///
/// The API and the database keep 24-hour `HH:mm` strings; only what people read goes
/// through here. React/TS equivalent: a small `formatClock()` helper that every
/// component calls instead of `toLocaleTimeString`.

/// `HH:mm` -> minutes since midnight, or null if it isn't a valid time.
int? _minutes(String hm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(hm.trim());
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

/// The `am`/`pm` suffix for a minutes-since-midnight value.
String _suffix(int minutes) => minutes ~/ 60 < 12 ? 'am' : 'pm';

/// The number part without a suffix: `7`, `7:30`, `12`.
String _number(int minutes) {
  final h24 = minutes ~/ 60;
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  final min = minutes % 60;
  return min == 0 ? '$h' : '$h:${min.toString().padLeft(2, '0')}';
}

/// `19:00` -> `7pm`, `19:30` -> `7:30pm`. Returns [hm] unchanged when malformed
/// so bad data stays visible instead of crashing a screen.
String formatClock(String hm) {
  final m = _minutes(hm);
  return m == null ? hm : '${_number(m)}${_suffix(m)}';
}

/// Same as [formatClock] for the platform time picker's [TimeOfDay].
String formatClockOfDay(TimeOfDay t) {
  final m = t.hour * 60 + t.minute;
  return '${_number(m)}${_suffix(m)}';
}

/// A run's time span. Start only when [end] is null or empty (a run with no end
/// time). The first suffix is dropped when both ends share it: `7-8:30pm`, but
/// `11am-1pm`.
String formatClockRange(String start, String? end) {
  if (end == null || end.isEmpty) return formatClock(start);
  final s = _minutes(start);
  final e = _minutes(end);
  if (s == null || e == null) return '$start-$end';
  final sameSuffix = _suffix(s) == _suffix(e);
  return '${_number(s)}${sameSuffix ? '' : _suffix(s)}-${_number(e)}${_suffix(e)}';
}
