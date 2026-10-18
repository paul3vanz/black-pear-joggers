import '../../../core/db/app_database.dart';
import '../ui/run_format.dart';

/// The two day choices a member makes (D115): the days they run, which narrow
/// the Runs tab, and the days they may lead, which narrow Lead a run. Both are
/// ISO weekdays (Dart's `DateTime.weekday`, Monday = 1) held by the server,
/// which keeps lead days inside run days.
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

/// The runs left after a day filter, and how many it hid.
typedef DayFilterResult = ({List<Session> kept, int hidden});

/// Keeps the runs on one of [days] plus every run for which [always] is true
/// (one you lead or said you're coming to never disappears). Null [days] keeps
/// everything; an empty set keeps only the [always] runs. Order is kept.
DayFilterResult filterByDays(
  Iterable<Session> sessions,
  Set<int>? days,
  bool Function(Session session) always,
) {
  final kept = <Session>[];
  var hidden = 0;
  for (final s in sessions) {
    if (days == null || days.contains(sessionWeekday(s)) || always(s)) {
      kept.add(s);
    } else {
      hidden++;
    }
  }
  return (kept: kept, hidden: hidden);
}

/// The days the Runs tab shows: the run days plus any lead day (you're there
/// when you lead). Null while no run days are chosen.
Set<int>? runTabDays({List<int>? runDays, List<int>? leadDays}) =>
    runDays == null ? null : {...runDays, ...?leadDays};

/// The days Lead a run shows: the lead days, else the run days (nobody leads
/// on a day they don't run), else everything.
Set<int>? leadRosterDays({List<int>? runDays, List<int>? leadDays}) =>
    (leadDays ?? runDays)?.toSet();
