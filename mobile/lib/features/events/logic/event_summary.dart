import '../../groups/data/group_dtos.dart';
import '../../groups/data/summary_dtos.dart';
import '../../runs/logic/run_modes.dart';

/// The Runs-card summary for an `events` or `race` run (D79, D84): a plain
/// function of the session's embedded groups and the caller's `summary`, so it
/// works offline and is easy to test (like a pure selector in a React app).
///
/// - events: "3 going to 2 events", "1 going to 1 event", "1 going" (going, no
///   event picked yet), or "No one has picked a parkrun yet".
/// - race: "4 going" or "No one has said they're going yet".
///
/// It never mentions groups: the server's `groupCount` means nothing to a
/// member here.
String eventSummaryText({
  required String mode,
  required SessionSummary summary,
  required List<Group> groups,
}) {
  final eventGroups = [
    for (final g in groups)
      if (g.kind == 'event' && !g.isDeleted && g.goingCount > 0) g,
  ];
  final inEvents = eventGroups.fold<int>(0, (sum, g) => sum + g.goingCount);
  // `summary.goingCount` is everyone going, with or without an event; the
  // larger of the two copes with a summary that is a moment behind the groups.
  final going = summary.goingCount > inEvents ? summary.goingCount : inEvents;
  if (going == 0) {
    return isRaceMode(mode)
        ? "No one has said they're going yet"
        : 'No one has picked a parkrun yet';
  }
  if (isRaceMode(mode) || eventGroups.isEmpty) return '$going going';
  final n = eventGroups.length;
  return '$going going to $n ${n == 1 ? 'event' : 'events'}';
}

/// The name of the event the caller is going to ("Worcester parkrun"), or null
/// when they are not going, picked none, or the run is a race (where "you're
/// going" already says it).
String? myEventName({
  required String mode,
  required SessionSummary summary,
  required List<Group> groups,
}) {
  if (!isEventsMode(mode) || summary.myStatus != 'going') return null;
  final id = summary.myGroupId;
  if (id == null) return null;
  for (final g in groups) {
    if (g.id == id && g.kind == 'event') {
      final name = g.label?.trim();
      return name == null || name.isEmpty ? null : name;
    }
  }
  return null;
}
