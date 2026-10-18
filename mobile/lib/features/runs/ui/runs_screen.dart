import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/clock.dart';
import '../../membership/ui/membership_providers.dart';
import '../../events/logic/event_summary.dart';
import '../../groups/data/group_dtos.dart';
import '../../groups/data/run_preferences_repository.dart';
import '../../groups/data/summary_dtos.dart';
import '../../groups/ui/group_format.dart';
import '../../groups/ui/groups_providers.dart';
import '../../messages/data/messages_repository.dart';
import '../data/runs_repository.dart';
import '../data/session_changes.dart';
import '../logic/my_days.dart';
import '../logic/run_modes.dart';
import 'my_days_panel.dart';
import 'run_format.dart';
import 'series_image.dart';
import 'runs_providers.dart';

/// The Runs tab (`/runs`): upcoming club runs grouped by day. Same offline
/// pattern as Updates: render the Drift cache straight away, refresh in the
/// background and show a small banner if that fails. The "Days I run" panel
/// (D115) hides other weekdays, except runs you're going to or leading.
class RunsScreen extends ConsumerStatefulWidget {
  const RunsScreen({super.key});

  @override
  ConsumerState<RunsScreen> createState() => _RunsScreenState();
}

class _RunsScreenState extends ConsumerState<RunsScreen> {
  bool _refreshing = true;
  bool _refreshFailed = false;

  /// True once the preferences refresh finished (either way), so the panel
  /// does not flash "Showing every day" while the saved choice loads.
  bool _prefsSettled = false;

  /// The member tapped Show N more: list every day until they tap back.
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  /// Pulls the saved run days; a failure keeps the cached value and never
  /// shows the offline banner on its own.
  Future<void> _refreshPrefs() async {
    try {
      await ref
          .read(runPreferencesRepositoryProvider)
          .refresh(ref.read(activeClubIdProvider));
    } on Object {
      // Offline: the cached choice (or every day) is shown.
    }
    if (mounted && !_prefsSettled) setState(() => _prefsSettled = true);
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    unawaited(_refreshPrefs());
    var failed = false;
    try {
      await repo.refresh(clubId);
      // Unread dots on the group cards.
      await ref.read(messagesRepositoryProvider).refreshThreadsQuietly(clubId);
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _refreshFailed = failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final sessions = ref.watch(upcomingSessionsProvider(clubId)).value;
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final canManage = ref.watch(canManageRunsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runs'),
        actions: [
          TextButton.icon(
            onPressed: () => unawaited(context.push('/runs/lead')),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Lead a run'),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showManageMenu(context),
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Manage'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildList(context, sessions, venues),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Session>? sessions,
    List<Venue> venues,
  ) {
    // The club-local day, refreshed at midnight and on resume (D87).
    final now = ref.watch(clubTodayProvider).now;
    final venueNames = {for (final v in venues) v.id: v.name};
    final prefs = ref
        .watch(runPreferencesProvider(ref.watch(activeClubIdProvider)))
        .value;
    final inRange = [
      for (final (_, day) in groupByDay(sessions ?? const [], now)) ...day,
    ];
    final filtered = filterByDays(
      inRange,
      _showAll
          ? null
          : runTabDays(runDays: prefs?.runDays, leadDays: prefs?.leadDays),
      _isMine,
    );
    final groups = groupByDay(filtered.kept, now);
    final present = weekdaysOf(inRange);
    final saved = prefs?.runDays;
    // Like the old roster filter (D56): one weekday has nothing to narrow.
    final showPanel =
        (_prefsSettled || saved != null) &&
        (saved != null || present.length > 1);
    final showBanner = _refreshFailed && !_refreshing;
    final empty = sessions != null && inRange.isEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (_refreshing && groups.isEmpty) const LinearProgressIndicator(),
        if (showBanner)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OfflineBanner(
              groups.isEmpty
                  ? "Offline — runs couldn't be loaded"
                  : 'Offline — showing saved runs',
            ),
          ),
        if (showPanel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MyDaysPanel(
              kind: DayKind.run,
              present: present,
              saved: saved,
              otherSaved: prefs?.leadDays,
              preselect: prefs?.leadDays?.toSet() ?? const {},
              hidden: filtered.hidden,
              showAll: _showAll,
              onShowAll: (on) => setState(() => _showAll = on),
              onSaved: () => setState(() => _showAll = false),
            ),
          ),
        if (empty && !_refreshing && !showBanner) const _EmptyState(),
        if (!empty && groups.isEmpty && filtered.hidden > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Text(
              'No runs on your days. Tap Show ${filtered.hidden} more to see '
              'the rest.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        for (final (date, day) in groups) ...[
          _DayHeader(
            label: dayHeader(date, now),
            isToday: date == localDateString(now),
          ),
          for (final s in day)
            _RunCard(
              session: s,
              venueName: s.venueId == null ? null : venueNames[s.venueId],
              venueNames: venueNames,
              isToday: date == localDateString(now),
            ),
        ],
      ],
    );
  }

  /// Runs that ignore the day filter: ones you said you're coming to (or
  /// might) and ones you lead, so an answer never disappears.
  static bool _isMine(Session s) {
    final summary = decodeSummary(s.summaryJson);
    if (summary == null) return false;
    return summary.myLeading ||
        summary.myStatus == 'going' ||
        summary.myStatus == 'maybe';
  }

  void _showManageMenu(BuildContext context) {
    final router = GoRouter.of(context);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add ad-hoc run'),
                onTap: () {
                  Navigator.of(sheet).pop();
                  unawaited(router.push('/runs/new'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat),
                title: const Text('Manage series'),
                onTap: () {
                  Navigator.of(sheet).pop();
                  unawaited(router.push('/runs/series'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('Manage venues'),
                onTap: () {
                  Navigator.of(sheet).pop();
                  unawaited(router.push('/runs/venues'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('Members and roles'),
                onTap: () {
                  Navigator.of(sheet).pop();
                  unawaited(router.push('/profile/members'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.directions_run,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No upcoming runs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Club runs will show up here once they are scheduled.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.isToday});

  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isToday
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.session,
    required this.venueName,
    required this.venueNames,
    required this.isToday,
  });

  final Session session;
  final String? venueName;
  final Map<String, String> venueNames;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cancelled = session.status == 'cancelled';
    final changes = sessionChanges(session, venueName: (id) => venueNames[id]);
    final summary = decodeSummary(session.summaryJson);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/runs/${session.id}'),
        // The series banner sits flush at the top of the card (nothing when absent).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SeriesImage(url: session.imageUrl),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cancelled || changes.isNotEmpty || isToday)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (cancelled)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                'Cancelled',
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                              backgroundColor: scheme.errorContainer,
                            ),
                          if (!cancelled && changes.isNotEmpty)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                'Changed',
                                style: TextStyle(
                                  color: scheme.onTertiaryContainer,
                                ),
                              ),
                              backgroundColor: scheme.tertiaryContainer,
                            ),
                          if (isToday)
                            const Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text('Today'),
                            ),
                        ],
                      ),
                    ),
                  Text(
                    timeRange(session.localStartTime, session.localEndTime),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (cancelled && session.cancelReason != null)
                    Text(
                      session.cancelReason!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  for (final change in changes)
                    Text(
                      change,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (venueName != null) Text(venueName!, style: muted),
                  Text(groupModeLabel(session.groupMode), style: muted),
                  if (!cancelled && summary != null)
                    _SummaryRow(
                      summary: summary,
                      mode: session.groupMode,
                      groups: decodeGroups(session.groupsJson),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "3 groups · 12 going" with chips for your own response and "You're leading",
/// from the session `summary` (works offline, it is in the cache). Events and
/// races get their own wording instead (D84): "3 going to 2 events", never a
/// group count, and "You're going to Worcester parkrun" for your own answer.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.summary,
    required this.mode,
    required this.groups,
  });

  final SessionSummary summary;
  final String mode;
  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final eventLike = isEventLikeMode(mode);
    final counts = eventLike
        ? eventSummaryText(mode: mode, summary: summary, groups: groups)
        : [
            if (summary.groupCount > 0)
              countLabel(summary.groupCount, 'group', 'groups'),
            if (summary.goingCount > 0) '${summary.goingCount} going',
          ].join(' · ');
    final eventName = myEventName(mode: mode, summary: summary, groups: groups);
    // Leaders are marked going automatically (D30), so "You're going" beside
    // "You're leading" is noise; other statuses still show. (`when` is a Dart 3
    // guard on a switch case.)
    final response = switch (summary.myStatus) {
      'going' when summary.myLeading && !eventLike => null,
      'going' when eventName != null => "You're going to $eventName",
      'going' => "You're going",
      'maybe' => 'Maybe',
      'not_going' => "Can't come",
      _ => null,
    };
    final leading = summary.myLeading && !eventLike;
    if (counts.isEmpty && response == null && !leading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (counts.isNotEmpty)
            Text(
              counts,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (response != null)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(response),
              backgroundColor: summary.myStatus == 'going'
                  ? scheme.primaryContainer
                  : null,
            ),
          if (leading)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                "You're leading",
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
              backgroundColor: scheme.secondaryContainer,
            ),
        ],
      ),
    );
  }
}
