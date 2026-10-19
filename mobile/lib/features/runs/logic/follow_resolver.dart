/// "Runs I follow" (D117): the member's choice for each weekly series. One
/// choice decides both what shows in My runs and which runs they are reminded
/// about. Wire values: `follow`, `auto`, `hide`; no saved choice is `auto`.
enum FollowMode {
  follow,
  auto,
  hide;

  /// Unknown or missing server values fall back to `auto`.
  static FollowMode parse(String? value) => FollowMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => FollowMode.auto,
  );
}

/// What [resolveFollow] decides for one member and one run.
typedef FollowResult = ({bool followed, bool inMine});

/// The one rule for "is this run followed, and does it show in My runs?".
///
/// A line-for-line copy of the server's `FollowResolver::resolve`
/// (api/app/Services/FollowResolver.php): both are tested against the same
/// case table (api/tests/fixtures/follow_resolver_cases.json), so the feed
/// here and the server's reminders can't drift apart. In order:
///  1. an RSVP of going or maybe shows the run;
///  2. hide: not followed, not shown;
///  3. follow: followed and shown;
///  4. auto: followed and shown only when the member usually comes.
/// A run with no series ([mode] null, a one-off) always shows but is never
/// followed. [rsvp] is `going` | `maybe` | `not_going` or null; leading a run
/// counts as going.
FollowResult resolveFollow({
  required String? rsvp,
  required FollowMode? mode,
  required bool usuallyComes,
}) {
  final followed =
      mode == FollowMode.follow || (mode == FollowMode.auto && usuallyComes);
  final answered = rsvp == 'going' || rsvp == 'maybe';
  return (followed: followed, inMine: answered || mode == null || followed);
}
