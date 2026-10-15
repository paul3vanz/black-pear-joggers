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
import '../../runs/ui/runs_providers.dart';
import '../data/group_dtos.dart';
import '../data/small_kv_store.dart';
import '../data/summary_dtos.dart';
import '../logic/roster.dart';
import 'group_access.dart';
import 'groups_providers.dart';
import 'roster_run_card.dart';

/// `/runs/lead`: the next six weeks of runs grouped by week, so a member can
/// see which need a leader and offer to lead. Reads the Drift cache; pull to
/// refresh runs the normal sessions refresh. A day filter (only the weekdays
/// that exist) narrows the list; it is remembered per club (D56).
class LeaderRosterScreen extends ConsumerStatefulWidget {
  const LeaderRosterScreen({super.key});

  @override
  ConsumerState<LeaderRosterScreen> createState() => _LeaderRosterScreenState();
}

class _LeaderRosterScreenState extends ConsumerState<LeaderRosterScreen> {
  bool _refreshFailed = false;

  /// The chosen weekdays (1 = Monday); empty means all days.
  Set<int> _days = {};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    unawaited(_loadDays());
  }

  Future<void> _loadDays() async {
    final clubId = ref.read(activeClubIdProvider);
    final stored = await ref
        .read(smallKvStoreProvider)
        .get(SmallKvStore.leadDaysKey(clubId));
    if (mounted) setState(() => _days = decodeWeekdays(stored));
  }

  Future<void> _setDays(Set<int> days) async {
    setState(() => _days = days);
    final clubId = ref.read(activeClubIdProvider);
    final store = ref.read(smallKvStoreProvider);
    final key = SmallKvStore.leadDaysKey(clubId);
    if (days.isEmpty) {
      await store.remove(key);
    } else {
      await store.set(key, encodeWeekdays(days));
    }
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
  /// the cached groups). Such runs ignore the day filter.
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
    final allWeeks = buildRoster(sessions ?? const [], now);
    // Only offer weekdays that occur, and only when there is a choice. A
    // remembered day that no longer occurs is ignored rather than hiding runs.
    final present = rosterWeekdays(allWeeks);
    final canFilter = present.length > 1;
    final selected = canFilter ? _days.intersection(present) : <int>{};
    final filtered = filterRosterByDays(
      allWeeks,
      selected,
      (s) => _leads(s, myId),
    );
    final weeks = filtered.weeks;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lead a run')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
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
              if (canFilter)
                _DayFilter(
                  days: present.toList()..sort(),
                  selected: selected,
                  onChanged: (d) => unawaited(_setDays(d)),
                ),
              if (filtered.hidden > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${filtered.hidden} '
                    '${filtered.hidden == 1 ? 'run' : 'runs'} hidden by your '
                    'day filter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No runs coming up that need leaders.',
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

/// Weekday chips (multi-select, none = all days) and "Show all".
class _DayFilter extends StatelessWidget {
  const _DayFilter({
    required this.days,
    required this.selected,
    required this.onChanged,
  });

  final List<int> days;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final d in days)
        FilterChip(
          label: Text(weekdayShort[d - 1]),
          selected: selected.contains(d),
          onSelected: (on) =>
              onChanged(on ? {...selected, d} : ({...selected}..remove(d))),
        ),
      if (selected.isNotEmpty)
        TextButton(
          onPressed: () => onChanged(<int>{}),
          child: const Text('Show all'),
        ),
    ],
  );
}
