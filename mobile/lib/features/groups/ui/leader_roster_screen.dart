import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/clock.dart';
import '../../membership/ui/membership_providers.dart';
import '../../../core/config/club_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/open_link.dart';
import '../../runs/data/runs_repository.dart';
import '../../runs/logic/my_days.dart';
import '../../runs/ui/my_days_panel.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/group_dtos.dart';
import '../data/run_preferences_repository.dart';
import '../data/small_kv_store.dart';
import '../data/summary_dtos.dart';
import '../logic/roster.dart';
import 'group_access.dart';
import 'groups_providers.dart';
import 'roster_run_card.dart';

/// `/runs/lead`: the next six weeks of runs grouped by week, so a member can
/// see which need a leader and offer to lead. Reads the Drift cache; pull to
/// refresh runs the normal sessions refresh. The "Days I may lead" panel (D107)
/// is saved on the server and narrows the list to those weekdays (every day
/// until chosen; run days no longer apply, D117); **Show N more** reveals the
/// rest for this visit.
class LeaderRosterScreen extends ConsumerStatefulWidget {
  const LeaderRosterScreen({super.key});

  @override
  ConsumerState<LeaderRosterScreen> createState() => _LeaderRosterScreenState();
}

class _LeaderRosterScreenState extends ConsumerState<LeaderRosterScreen> {
  bool _refreshFailed = false;

  /// True once the preferences refresh finished (either way), so the panel does
  /// not flash the first-time prompt while the saved choice is still loading.
  bool _prefsSettled = false;

  /// The old local day filter (D56), only used to pre-select the chips when the
  /// server has no choice yet. Not saved until the member taps Save.
  Set<int> _legacyDays = {};

  /// The member tapped Show N more: list every day until they tap back.
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    unawaited(_refreshPrefs());
    unawaited(_loadLegacyDays());
  }

  Future<void> _loadLegacyDays() async {
    final clubId = ref.read(activeClubIdProvider);
    final stored = await ref
        .read(smallKvStoreProvider)
        .get(SmallKvStore.leadDaysKey(clubId));
    if (mounted) setState(() => _legacyDays = decodeWeekdays(stored));
  }

  /// Pulls the saved "days I may lead"; a failure keeps the cached value.
  Future<void> _refreshPrefs() async {
    final clubId = ref.read(activeClubIdProvider);
    try {
      await ref.read(runPreferencesRepositoryProvider).refresh(clubId);
    } on Object {
      // Offline: the cache (or the first-time prompt) is shown.
    }
    if (mounted) setState(() => _prefsSettled = true);
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    var failed = false;
    try {
      await repo.refreshSessions(clubId);
    } on Object {
      failed = true;
    }
    if (mounted) setState(() => _refreshFailed = failed);
  }

  /// Whether the viewer leads a group on [s] (from the cached summary, else
  /// the cached groups). Such runs ignore the days choice.
  bool _leads(Session s, String? myId) {
    if (decodeSummary(s.summaryJson)?.myLeading ?? false) return true;
    return myId != null &&
        decodeGroups(s.groupsJson).any((g) => g.isLedBy(myId));
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final sessions = ref.watch(upcomingSessionsProvider(clubId)).value;
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final venueNames = {for (final v in venues) v.id: v.name};
    final now = ref.watch(nowProvider);
    final myId = ref.watch(myMemberIdProvider);
    final prefs = ref.watch(runPreferencesProvider(clubId)).value;
    // null = never chosen; [] = chose none.
    final saved = prefs?.leadDays;
    final allWeeks = buildRoster(sessions ?? const [], now);
    final filtered = filterRosterByDays(
      allWeeks,
      _showAll ? null : leadRosterDays(leadDays: saved),
      (s) => _leads(s, myId),
    );
    final weeks = filtered.weeks;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lead a run')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            unawaited(_refreshPrefs());
            await _refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'Runs in the next $rosterWeeks weeks. Offer to lead a group, or '
                'help lead one that is already there.',
                style: theme.textTheme.bodyMedium,
              ),
              // A link row to the club's guidance for new leaders.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(
                    openLink(
                      context,
                      ref,
                      ref
                          .read(clubConfigProvider)
                          .website
                          .resolve('/leading-a-group'),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Tips on leading a group'),
                ),
              ),
              if (_prefsSettled || saved != null)
                MyDaysPanel(
                  kind: DayKind.lead,
                  present: rosterWeekdays(allWeeks),
                  saved: saved,
                  // Run days no longer exist in the app (D117), so there is
                  // no "this changes your run days" hint.
                  otherSaved: null,
                  // The old local filter starts ticked.
                  preselect: _legacyDays,
                  promptWhenUnset: true,
                  hidden: filtered.hidden,
                  showAll: _showAll,
                  onShowAll: (on) => setState(() => _showAll = on),
                  onSaved: () {
                    setState(() => _showAll = false);
                    // The server owns the choice now; drop the old local filter.
                    unawaited(
                      ref
                          .read(smallKvStoreProvider)
                          .remove(SmallKvStore.leadDaysKey(clubId)),
                    );
                  },
                ),
              const SizedBox(height: 8),
              if (_refreshFailed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: OfflineBanner(
                    "You're offline. Showing saved runs; changes need a "
                    'connection.',
                  ),
                ),
              if (sessions != null && weeks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    filtered.hidden > 0
                        ? 'No runs on your days. Tap Show ${filtered.hidden} '
                              'more to see the rest.'
                        : 'No runs coming up that need leaders.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final week in weeks) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    week.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final s in week.sessions)
                  RosterRunCard(
                    key: ValueKey(s.id),
                    session: s,
                    venueName: s.venueId == null ? null : venueNames[s.venueId],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
