import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../runs/data/runs_repository.dart';
import '../../runs/ui/run_format.dart';

/// The leader roster looks this many weeks ahead.
const rosterWeeks = 6;

/// One calendar week (Monday start) of roster runs.
class RosterWeek {
  const RosterWeek({
    required this.monday,
    required this.label,
    required this.sessions,
  });

  /// `yyyy-MM-dd` of the Monday.
  final String monday;

  /// "This week", "Next week" or "Week of 26 Oct".
  final String label;
  final List<Session> sessions;
}

/// The Monday on or before the club-local date [localDate].
String mondayOf(String localDate) {
  final d = parseLocalDate(localDate);
  return localDateString(d.subtract(Duration(days: d.weekday - 1)));
}

/// The runs a member can sign up to lead: not cancelled, not yet ended and
/// within the next [weeks] weeks, grouped by week. [sessions] must already be
/// ordered by date and start time (`watchUpcomingSessions`).
List<RosterWeek> buildRoster(
  List<Session> sessions,
  DateTime now, {
  int weeks = rosterWeeks,
}) {
  final last = localDateString(now.add(Duration(days: weeks * 7)));
  final thisMonday = mondayOf(localDateString(now));
  final nextMonday = mondayOf(
    localDateString(parseLocalDate(thisMonday).add(const Duration(days: 7))),
  );
  String label(String monday) {
    if (monday == thisMonday) return 'This week';
    if (monday == nextMonday) return 'Next week';
    return 'Week of ${DateFormat('d MMM').format(parseLocalDate(monday))}';
  }

  final result = <RosterWeek>[];
  for (final s in sessions) {
    if (s.status == 'cancelled' || s.endsAt.isBefore(now)) continue;
    if (s.localDate.compareTo(last) > 0) continue;
    final monday = mondayOf(s.localDate);
    if (result.isNotEmpty && result.last.monday == monday) {
      result.last.sessions.add(s);
    } else {
      result.add(
        RosterWeek(monday: monday, label: label(monday), sessions: [s]),
      );
    }
  }
  return result;
}

/// Short names for the weekday filter chips, indexed by `DateTime.weekday - 1`
/// (Dart numbers Monday 1 to Sunday 7).
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The weekdays (1 = Monday ... 7 = Sunday) that occur in [weeks], so the
/// filter only offers days that exist.
Set<int> rosterWeekdays(List<RosterWeek> weeks) => {
  for (final w in weeks)
    for (final s in w.sessions) parseLocalDate(s.localDate).weekday,
};

/// The roster after the day filter: [weeks] is what to show and [hidden] how
/// many runs the filter removed.
typedef RosterFilterResult = ({List<RosterWeek> weeks, int hidden});

/// Keeps the runs on one of [days] (empty = all days) plus every run for which
/// [isLeading] is true, so a run you lead never disappears (D56). Weeks that
/// end up empty are dropped.
RosterFilterResult filterRosterByDays(
  List<RosterWeek> weeks,
  Set<int> days,
  bool Function(Session session) isLeading,
) {
  if (days.isEmpty) return (weeks: weeks, hidden: 0);
  var hidden = 0;
  final kept = <RosterWeek>[];
  for (final w in weeks) {
    final shown = <Session>[];
    for (final s in w.sessions) {
      if (days.contains(parseLocalDate(s.localDate).weekday) || isLeading(s)) {
        shown.add(s);
      } else {
        hidden++;
      }
    }
    if (shown.isNotEmpty) {
      kept.add(RosterWeek(monday: w.monday, label: w.label, sessions: shown));
    }
  }
  return (weeks: kept, hidden: hidden);
}

/// `1,3` -> {1, 3}; ignores anything that is not a weekday number.
Set<int> decodeWeekdays(String? stored) => {
  for (final part in (stored ?? '').split(','))
    if (int.tryParse(part.trim()) case final d? when d >= 1 && d <= 7) d,
};

/// {3, 1} -> `1,3`.
String encodeWeekdays(Set<int> days) => (days.toList()..sort()).join(',');
