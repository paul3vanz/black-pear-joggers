import 'dart:convert';
import 'dart:io';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/features/runs/logic/follow_resolver.dart';
import 'package:bpj/features/runs/logic/run_feed.dart';
import 'package:flutter_test/flutter_test.dart';

/// D117: the app's resolver against the SAME case table as the server's
/// (`api/tests/FollowResolverTest.php`), so My runs and the reminder job give
/// the same answer for the same member and run.
void main() {
  final table = jsonDecode(
    File('../api/tests/fixtures/follow_resolver_cases.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final columns = (table['columns']! as List).cast<String>();
  final cases = [
    for (final row in (table['cases']! as List).cast<List<Object?>>())
      {for (var i = 0; i < columns.length; i++) columns[i]: row[i]},
  ];

  test('the shared table has every My runs rule', () {
    expect(cases.length, greaterThan(20));
    expect(cases.map((c) => c['mode']).toSet(), {
      'follow',
      'auto',
      'hide',
      null,
    });
    expect(cases.map((c) => c['rsvp']).toSet(), {
      null,
      'going',
      'maybe',
      'not_going',
    });
  });

  for (final c in cases) {
    test('rsvp ${c['rsvp']}, mode ${c['mode']}, usually ${c['usuallyComes']}: '
        '${c['why']}', () {
      final mode = c['mode'] as String?;
      final result = resolveFollow(
        rsvp: c['rsvp'] as String?,
        mode: mode == null ? null : FollowMode.parse(mode),
        usuallyComes: c['usuallyComes']! as bool,
      );
      expect(result, (
        followed: c['followed']! as bool,
        inMine: c['inMine']! as bool,
      ));
    });
  }

  group('feedRun', () {
    Session session({
      String? seriesId = 's1',
      String? myStatus,
      bool leading = false,
    }) => Session(
      id: 'r1',
      clubId: 1,
      seriesId: seriesId,
      title: 'Run',
      startsAt: DateTime.utc(2026, 10, 19, 18),
      endsAt: DateTime.utc(2026, 10, 19, 21),
      localDate: '2026-10-19',
      localStartTime: '19:00',
      groupMode: 'paced',
      status: 'scheduled',
      isDetached: false,
      summaryJson: jsonEncode({'myStatus': myStatus, 'myLeading': leading}),
      updatedAt: DateTime.utc(2026, 10, 19),
    );
    SeriesFollow follow(FollowMode mode, {bool usual = false}) => SeriesFollow(
      seriesId: 's1',
      title: 'Run',
      weekday: 1,
      localStartTime: '19:00',
      groupMode: 'paced',
      mode: mode,
      usuallyComes: usual,
    );

    test('status chip and button follow the resolver', () {
      FeedRun run(Session s, [SeriesFollow? f]) => feedRun(s, {'s1': ?f});

      final hidden = run(session(), follow(FollowMode.hide, usual: true));
      expect(
        (hidden.status, hidden.inMine, hidden.canFollow),
        (RunStatus.hidden, false, true),
      );
      final following = run(session(), follow(FollowMode.follow));
      expect(
        (following.status, following.inMine, following.canFollow),
        (RunStatus.following, true, false),
      );
      final autoUsual = run(session(), follow(FollowMode.auto, usual: true));
      expect((autoUsual.status, autoUsual.inMine), (RunStatus.following, true));
      final autoRare = run(session(), follow(FollowMode.auto));
      expect(
        (autoRare.status, autoRare.inMine, autoRare.canFollow),
        (RunStatus.notFollowing, false, true),
      );
      // An RSVP shows a hidden run and offers Manage, not Follow.
      final goingHidden = run(
        session(myStatus: 'going'),
        follow(FollowMode.hide),
      );
      expect(
        (goingHidden.status, goingHidden.inMine, goingHidden.canFollow),
        (RunStatus.going, true, false),
      );
      final maybe = run(session(myStatus: 'maybe'), follow(FollowMode.auto));
      expect((maybe.status, maybe.inMine), (RunStatus.maybe, true));
      // Leading counts as going.
      expect(
        run(session(leading: true), follow(FollowMode.hide)).status,
        RunStatus.going,
      );
      // Can't come on an unfollowed run says so and still offers Follow.
      final cantCome = run(
        session(myStatus: 'not_going'),
        follow(FollowMode.auto),
      );
      expect((cantCome.status, cantCome.canFollow), (RunStatus.cantCome, true));
      // Can't come on a followed run shows that, not Following, and the run
      // leaves My runs.
      final cantFollowed = run(
        session(myStatus: 'not_going'),
        follow(FollowMode.follow),
      );
      expect(
        (cantFollowed.status, cantFollowed.inMine),
        (RunStatus.cantCome, false),
      );
      final cantOneOff = run(session(myStatus: 'not_going', seriesId: null));
      expect(
        (cantOneOff.status, cantOneOff.inMine),
        (RunStatus.cantCome, false),
      );
      // A series missing from the cache counts as auto with no history.
      expect(run(session()).status, RunStatus.notFollowing);
      // A one-off run always shows and has nothing to follow.
      final oneOff = run(session(seriesId: null));
      expect(
        (oneOff.status, oneOff.inMine, oneOff.canFollow),
        (RunStatus.oneOff, true, false),
      );
    });

    test('hasFollowChoices is false until something is not auto', () {
      expect(hasFollowChoices([follow(FollowMode.auto, usual: true)]), isFalse);
      expect(hasFollowChoices([follow(FollowMode.hide)]), isTrue);
      expect(hasFollowChoices(const []), isFalse);
    });
  });
}
