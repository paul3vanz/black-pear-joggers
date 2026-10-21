import '../../../core/db/app_database.dart';
import '../../../core/util/clock.dart';
import '../../groups/data/summary_dtos.dart';
import 'follow_resolver.dart';

/// One weekly series as `GET /follows` returns it (D117), cached in Drift so
/// My runs works offline.
class SeriesFollow {
  const SeriesFollow({
    required this.seriesId,
    required this.title,
    required this.weekday,
    required this.localStartTime,
    required this.groupMode,
    required this.mode,
    required this.usuallyComes,
  });

  final String seriesId;
  final String title;

  /// ISO weekday, 1 = Monday ... 7 = Sunday.
  final int weekday;

  /// Club-local `HH:MM`.
  final String localStartTime;
  final String groupMode;
  final FollowMode mode;

  /// Went to one of the last 6 runs (always false for events and races).
  final bool usuallyComes;

  /// What [mode] resolves to with no RSVP.
  bool get followed => resolveFollow(
    rsvp: null,
    mode: mode,
    usuallyComes: usuallyComes,
  ).followed;

  SeriesFollow copyWith({FollowMode? mode}) => SeriesFollow(
    seriesId: seriesId,
    title: title,
    weekday: weekday,
    localStartTime: localStartTime,
    groupMode: groupMode,
    mode: mode ?? this.mode,
    usuallyComes: usuallyComes,
  );

  factory SeriesFollow.fromJson(Map<String, Object?> json) => SeriesFollow(
    seriesId: json['seriesId']! as String,
    title: json['title'] as String? ?? 'Run',
    weekday: (json['weekday'] as num?)?.toInt() ?? 1,
    localStartTime: json['localStartTime'] as String? ?? '',
    groupMode: json['groupMode'] as String? ?? 'paced',
    mode: FollowMode.parse(json['mode'] as String?),
    usuallyComes: json['usuallyComes'] as bool? ?? false,
  );
}

/// The one status chip on a run card.
enum RunStatus {
  /// RSVP yes, or leading.
  going,
  maybe,
  cantCome,
  following,
  notFollowing,
  hidden,

  /// A one-off run (no series): nothing to follow, so no chip.
  oneOff,
}

/// A run with what the member's choices make of it.
class FeedRun {
  const FeedRun({
    required this.session,
    required this.status,
    required this.inMine,
    required this.canFollow,
  });

  final Session session;
  final RunStatus status;

  /// Shows in My runs ([resolveFollow], minus runs answered "can't come").
  final bool inMine;

  /// Has a series the member does not follow and no RSVP yes: the card
  /// offers **Follow** instead of **Manage**.
  final bool canFollow;
}

/// Resolves one run against the cached [follows] (series id => follow). A
/// series missing from the cache counts as auto with no history.
FeedRun feedRun(Session session, Map<String, SeriesFollow> follows) {
  final summary = decodeSummary(session.summaryJson);
  final rsvp = summary?.myLeading == true ? 'going' : summary?.myStatus;
  final seriesId = session.seriesId;
  final follow = seriesId == null ? null : follows[seriesId];
  final mode = seriesId == null ? null : (follow?.mode ?? FollowMode.auto);
  final result = resolveFollow(
    rsvp: rsvp,
    mode: mode,
    usuallyComes: follow?.usuallyComes ?? false,
  );
  final status = switch (rsvp) {
    'going' => RunStatus.going,
    'maybe' => RunStatus.maybe,
    // An explicit "can't come" beats whatever the follow choice says.
    'not_going' => RunStatus.cantCome,
    _ when mode == null => RunStatus.oneOff,
    _ when mode == FollowMode.hide => RunStatus.hidden,
    _ when result.followed => RunStatus.following,
    _ => RunStatus.notFollowing,
  };
  return FeedRun(
    session: session,
    status: status,
    // A run they've said they can't do drops out of My runs but stays in All
    // runs. The resolver is shared with the server, so this stays client-side.
    inMine: result.inMine && rsvp != 'not_going',
    canFollow:
        mode != null && !result.followed && rsvp != 'going' && rsvp != 'maybe',
  );
}

/// Every run resolved, in the given order.
List<FeedRun> buildFeed(
  Iterable<Session> sessions,
  Map<String, SeriesFollow> follows,
) => [for (final s in sessions) feedRun(s, follows)];

/// Runs that My runs leaves out, for the footer: those in the next 7 days
/// ("this week") and all of them.
({int thisWeek, int total}) otherRuns(Iterable<FeedRun> feed, DateTime now) {
  final weekEnd = localDateString(now.add(const Duration(days: 7)));
  var week = 0;
  var total = 0;
  for (final r in feed) {
    if (r.inMine) continue;
    total++;
    if (r.session.localDate.compareTo(weekEnd) < 0) week++;
  }
  return (thisWeek: week, total: total);
}

/// True once the member has made any choice (a series not on auto). Until
/// then the Runs tab opens on All runs, as they saw before (open question 3).
bool hasFollowChoices(Iterable<SeriesFollow> follows) =>
    follows.any((f) => f.mode != FollowMode.auto);
