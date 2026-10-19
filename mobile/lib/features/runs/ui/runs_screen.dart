import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/clock.dart';
import '../../membership/ui/membership_providers.dart';
import '../../events/logic/event_summary.dart';
import '../../groups/data/group_dtos.dart';
import '../../groups/data/summary_dtos.dart';
import '../../groups/ui/group_format.dart';
import '../../messages/data/messages_repository.dart';
import '../data/follows_repository.dart';
import '../data/runs_repository.dart';
import '../data/session_changes.dart';
import '../logic/follow_resolver.dart';
import '../logic/run_feed.dart';
import '../logic/run_modes.dart';
import 'follow_widgets.dart';
import 'run_format.dart';
import 'series_image.dart';
import 'runs_providers.dart';

/// The Runs tab (`/runs`): upcoming club runs grouped by day. Same offline
/// pattern as Updates: render the Drift cache straight away, refresh in the
/// background and show a small banner if that fails.
///
/// Two views (D117): **My runs** shows what the member follows plus their
/// RSVPs (`resolveFollow`), **All runs** shows everything. Switching is screen
/// state only: it never saves anything and is not remembered. Follow choices
/// are made on Runs I follow (`/follows`) or with the Follow button on a card.
class RunsScreen extends ConsumerStatefulWidget {
  const RunsScreen({super.key});

  @override
  ConsumerState<RunsScreen> createState() => _RunsScreenState();
}

class _RunsScreenState extends ConsumerState<RunsScreen> {
  bool _refreshing = true;
  bool _refreshFailed = false;

  /// The view the member picked; null until they tap the switch, so the
  /// default can follow the cache (see [_effectiveView]).
  RunsView? _view;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  /// Pulls the follow choices; a failure keeps the cache and never shows the
  /// offline banner on its own.
  Future<void> _refreshFollows() async {
    try {
      await ref
          .read(followsRepositoryProvider)
          .refresh(ref.read(activeClubIdProvider));
    } on Object {
      // Offline: the cached choices are used.
    }
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    unawaited(_refreshFollows());
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

  /// My runs, unless the member has never made a follow choice: they saw
  /// every run before, so they start on All runs until they choose
  /// (open question 3 of the plan). Choices that can't be read (yet) also mean
  /// All runs, so a cache problem never hides runs.
  RunsView _effectiveView(List<SeriesFollow>? follows) =>
      _view ??
      (follows != null && hasFollowChoices(follows)
          ? RunsView.mine
          : RunsView.all);

  Future<void> _follow(String seriesId) async {
    final clubId = ref.read(activeClubIdProvider);
    final messenger = ScaffoldMessenger.of(context);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await ref
          .read(followsRepositoryProvider)
          .setMode(clubId, seriesId, FollowMode.follow);
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ApiException.from(e).isNetworkError
                ? "Couldn't follow that run. You're offline."
                : "Couldn't follow that run. Try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final sessions = ref.watch(upcomingSessionsProvider(clubId)).value;
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final follows = ref.watch(seriesFollowsProvider(clubId)).value;
    final canManage = ref.watch(canManageRunsProvider);
    // The club-local day, refreshed at midnight and on resume (D87).
    final now = ref.watch(clubTodayProvider).now;
    final view = _effectiveView(follows);

    final inRange = [
      for (final (_, day) in groupByDay(sessions ?? const [], now)) ...day,
    ];
    final feed = buildFeed(inRange, {
      for (final f in follows ?? const <SeriesFollow>[]) f.seriesId: f,
    });
    final others = otherRuns(feed, now);
    final showFooter = view == RunsView.mine && others.total > 0;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: RunsViewSwitch(
              view: view,
              onChanged: (v) => setState(() => _view = v),
            ),
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showManageMenu(context),
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Manage'),
            )
          : null,
      bottomNavigationBar: showFooter
          ? _OtherRunsBar(
              others: others,
              onShowAll: () => setState(() => _view = RunsView.all),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildList(
            context,
            view: view,
            sessions: sessions,
            feed: feed,
            follows: follows,
            venues: venues,
            now: now,
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context, {
    required RunsView view,
    required List<Session>? sessions,
    required List<FeedRun> feed,
    required List<SeriesFollow>? follows,
    required List<Venue> venues,
    required DateTime now,
  }) {
    final venueNames = {for (final v in venues) v.id: v.name};
    final shown = view == RunsView.all
        ? feed
        : [
            for (final r in feed)
              if (r.inMine) r,
          ];
    final byId = {for (final r in shown) r.session.id: r};
    final groups = groupByDay([for (final r in shown) r.session], now);
    final showBanner = _refreshFailed && !_refreshing;
    final noRuns = sessions != null && feed.isEmpty;
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
        if (view == RunsView.mine)
          const _MyRunsCaption()
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: JustLookingBanner(),
          ),
        if (noRuns && !_refreshing && !showBanner) const _EmptyState(),
        if (!noRuns && groups.isEmpty && view == RunsView.mine)
          _NothingFollowedState(
            followsAny: (follows ?? const []).any((f) => f.followed),
            onShowAll: () => setState(() => _view = RunsView.all),
          ),
        for (final (date, day) in groups) ...[
          _DayHeader(
            label: dayHeader(date, now),
            isToday: date == localDateString(now),
          ),
          for (final s in day)
            _RunCard(
              run: byId[s.id]!,
              venueName: s.venueId == null ? null : venueNames[s.venueId],
              venueNames: venueNames,
              isToday: date == localDateString(now),
              dimmed: byId[s.id]!.status == RunStatus.hidden,
              onFollow: s.seriesId == null
                  ? null
                  : () => unawaited(_follow(s.seriesId!)),
            ),
        ],
      ],
    );
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

/// "Followed runs and your RSVPs" with the way to change them.
class _MyRunsCaption extends StatelessWidget {
  const _MyRunsCaption();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Followed runs and your RSVPs',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('runsIFollowLink'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.only(left: 8),
          ),
          onPressed: () => unawaited(context.push('/follows')),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Runs I follow'), Icon(Icons.chevron_right)],
          ),
        ),
      ],
    );
  }
}

/// The bar above the navigation in My runs: how much All runs would add.
class _OtherRunsBar extends StatelessWidget {
  const _OtherRunsBar({required this.others, required this.onShowAll});

  final ({int thisWeek, int total}) others;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = others.thisWeek > 0
        ? '${countLabel(others.thisWeek, 'other run', 'other runs')} this week'
        : '${countLabel(others.total, 'other run', 'other runs')} coming up';
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  key: const ValueKey('otherRunsText'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                key: const ValueKey('showAllRuns'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: onShowAll,
                child: const Text('Show all runs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// My runs with nothing in it (there are runs, none resolve to followed).
class _NothingFollowedState extends StatelessWidget {
  const _NothingFollowedState({
    required this.followsAny,
    required this.onShowAll,
  });

  /// True when some series is followed but none of its runs are coming up.
  final bool followsAny;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            followsAny
                ? 'None of the runs you follow are coming up'
                : "You're not following any runs yet",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Follow the runs you go to and they show here, with reminders.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => unawaited(context.push('/follows')),
                child: const Text('Choose runs'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder(),
                ),
                onPressed: onShowAll,
                child: const Text('Show all runs'),
              ),
            ],
          ),
        ],
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
          fontSize: 14,
          fontWeight: FontWeight.w500,
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
    required this.run,
    required this.venueName,
    required this.venueNames,
    required this.isToday,
    required this.dimmed,
    required this.onFollow,
  });

  final FeedRun run;
  final String? venueName;
  final Map<String, String> venueNames;
  final bool isToday;

  /// A hidden run in All runs.
  final bool dimmed;
  final VoidCallback? onFollow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedColors = RunFeedColors.of(context);
    final session = run.session;
    final cancelled = session.status == 'cancelled';
    final changes = sessionChanges(session, venueName: (id) => venueNames[id]);
    final summary = decodeSummary(session.summaryJson);
    final textColor = dimmed ? feedColors.hiddenText : null;
    final muted = TextStyle(
      fontSize: 13,
      color: dimmed ? feedColors.hiddenText : scheme.onSurfaceVariant,
    );
    void open() => unawaited(context.push('/runs/${session.id}'));
    final showFollow = run.canFollow && onFollow != null && !cancelled;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: dimmed ? feedColors.hiddenFill : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: dimmed
            ? BorderSide(color: feedColors.hiddenBorder)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('run-${session.id}'),
        onTap: open,
        // The series banner sits flush at the top of the card (nothing when absent).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Opacity(
              opacity: dimmed ? 0.5 : 1,
              child: SeriesImage(url: session.imageUrl),
            ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  timeRange(
                                    session.localStartTime,
                                    session.localEndTime,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: dimmed
                                        ? feedColors.hiddenText
                                        : scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                RunStatusChip(run.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                decoration: cancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (venueName != null)
                              Text(venueName!, style: muted),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (showFollow)
                        OutlinedButton.icon(
                          key: ValueKey('follow-${session.id}'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: onFollow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Follow'),
                        )
                      else
                        FilledButton.tonal(
                          key: ValueKey('manage-${session.id}'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: const StadiumBorder(),
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                          ),
                          onPressed: open,
                          child: const Text('Manage'),
                        ),
                    ],
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

/// "3 groups · 12 going" and "You're leading", from the session `summary`
/// (works offline, it is in the cache). Your own answer is the status chip at
/// the top of the card. Events and races get their own wording instead (D84):
/// "3 going to 2 events", never a group count, and "You're going to Worcester
/// parkrun" for your own answer.
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
    final eventName = summary.myStatus == 'going'
        ? myEventName(mode: mode, summary: summary, groups: groups)
        : null;
    final leading = summary.myLeading && !eventLike;
    if (counts.isEmpty && eventName == null && !leading) {
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
          if (eventName != null)
            Text(
              "You're going to $eventName",
              style: theme.textTheme.bodyMedium,
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
