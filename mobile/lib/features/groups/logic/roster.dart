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
