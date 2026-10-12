import '../../../core/db/app_database.dart';
import '../../groups/data/group_dtos.dart';

/// How far back "recently used by the club" looks. The local session cache is
/// pruned after about two weeks (D17), so in practice this covers what is
/// cached: recent Saturdays and the runs already scheduled.
const recentEventWeeks = 12;

/// Event location ids used by event groups (`kind` `event` with a `locationId`)
/// in [sessions], most used first. A location counts once per run, so five
/// people adding it to the same Saturday do not outweigh five Saturdays. Ties
/// go to the more recent run, then to the id so the order is stable.
/// Cancelled runs and runs before [sinceDate] (`yyyy-MM-dd`) are ignored.
List<String> rankRecentLocationIds(
  Iterable<Session> sessions, {
  required String sinceDate,
}) {
  final counts = <String, int>{};
  final latest = <String, String>{};
  for (final s in sessions) {
    if (s.status == 'cancelled' || s.localDate.compareTo(sinceDate) < 0) {
      continue;
    }
    final seen = <String>{};
    for (final Group g in decodeGroups(s.groupsJson)) {
      final id = g.locationId;
      if (g.kind != 'event' || id == null || g.isDeleted) continue;
      if (!seen.add(id)) continue;
      counts[id] = (counts[id] ?? 0) + 1;
      if ((latest[id] ?? '').compareTo(s.localDate) < 0) {
        latest[id] = s.localDate;
      }
    }
  }
  final ids = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      final byDate = latest[b]!.compareTo(latest[a]!);
      return byDate != 0 ? byDate : a.compareTo(b);
    });
  return ids;
}

/// Location ids on the event groups of one run (what "Already added" greys
/// out in the picker).
Set<String> locationIdsOnSessionRow(Session? session) => {
  if (session != null)
    for (final g in decodeGroups(session.groupsJson))
      if (g.kind == 'event' && g.locationId != null && !g.isDeleted)
        g.locationId!,
};
