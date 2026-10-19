import '../../../core/db/app_database.dart';
import '../ui/run_format.dart';

/// The day lists a member can save on `PUT /preferences`, as ISO weekdays
/// (Dart's `DateTime.weekday`, Monday = 1). Only "days I may lead" is still
/// chosen in the app (Lead a run). "Days I run" (D115) was replaced by Runs I
/// follow (D117); the server keeps it for older app versions, so it stays
/// readable here.
enum DayKind {
  run('runDays'),
  lead('leadDays');

  const DayKind(this.field);

  /// The `PUT /preferences` key.
  final String field;
}

/// Short names for the weekday chips, indexed by `DateTime.weekday - 1`
/// (Dart numbers Monday 1 to Sunday 7).
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// `1,3` -> {1, 3}; ignores anything that is not a weekday number. Reads the
/// old local `leadRosterDays` filter, which pre-selects "days I may lead".
Set<int> decodeWeekdays(String? stored) => {
  for (final part in (stored ?? '').split(','))
    if (int.tryParse(part.trim()) case final d? when d >= 1 && d <= 7) d,
};

/// [1, 3] -> "Mon, Wed" (sorted).
String formatWeekdays(Iterable<int> days) =>
    ([...days]..sort()).map((d) => weekdayShort[d - 1]).join(', ');

/// The weekday (1 = Monday ... 7 = Sunday) of a run, in club-local time.
int sessionWeekday(Session s) => parseLocalDate(s.localDate).weekday;

/// The weekdays that occur in [sessions], so the chips only offer real days.
Set<int> weekdaysOf(Iterable<Session> sessions) => {
  for (final s in sessions) sessionWeekday(s),
};

/// The days Lead a run shows: the lead days, else everything (null).
Set<int>? leadRosterDays({List<int>? leadDays}) => leadDays?.toSet();
