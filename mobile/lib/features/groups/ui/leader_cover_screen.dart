import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ui/admin_only.dart';
import '../../../core/util/clock.dart';
import '../../../core/units/dist_unit.dart';
import '../../runs/data/runs_repository.dart';
import '../../runs/logic/run_modes.dart';
import '../../runs/ui/run_format.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/group_dtos.dart';
import '../logic/coverage_report.dart';
import '../logic/spread_target.dart';
import 'ask_leaders_sheet.dart';
import 'group_access.dart';
import 'groups_providers.dart';
import 'pace_spread_list.dart';

/// How far ahead the committee looks.
const leaderCoverDays = 28;

/// Whether a run has something the committee could still fix: a paced run with a
/// red gap, an open end or no jog/walk group (D128), or any run with a group
/// that has no leader or no groups at all.
bool runNeedsLeaders(Session session, List<Group> groups) {
  final report = buildCoverage(groups: groups, unit: DistUnit.mi);
  if (report.needsLeader.isNotEmpty) return true;
  if (usesSpreadTarget(session.groupMode)) {
    return buildSpreadTarget(groups).needsAttention;
  }
  return report.ledCount == 0;
}

/// Profile > Leader cover (committee only): the next four weeks of runs that use
/// pace groups, each with the picture of who leads and where the holes are, so
/// the committee can ask people ahead of time rather than three days out (D127).
/// Reads the cached sessions and their groups, so it works offline; asking needs
/// a connection.
class LeaderCoverScreen extends ConsumerStatefulWidget {
  const LeaderCoverScreen({super.key});

  @override
  ConsumerState<LeaderCoverScreen> createState() => _LeaderCoverScreenState();
}

class _LeaderCoverScreenState extends ConsumerState<LeaderCoverScreen> {
  bool _onlyNeeds = false;

  /// Runs the committee opened or closed by hand; the rest follow whether they
  /// need attention.
  final _open = <String, bool>{};

  Future<void> _refresh() async {
    try {
      await ref
          .read(runsRepositoryProvider)
          .refresh(ref.read(activeClubIdProvider));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't refresh. Showing what's saved."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!ref.watch(canManageRunsProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leader cover')),
        body: const Center(
          child: Text('Only committee members and admins can see this.'),
        ),
      );
    }
    final clubId = ref.watch(activeClubIdProvider);
    final today = ref.watch(clubTodayProvider);
    final now = ref.watch(nowProvider);
    final units = ref.watch(unitPrefsProvider);
    final last = localDateString(
      today.now.add(const Duration(days: leaderCoverDays)),
    );
    final sessions =
        ref.watch(upcomingSessionsProvider(clubId)).value ?? const <Session>[];
    final entries = [
      for (final s in sessions)
        if (s.localDate.compareTo(last) <= 0 &&
            s.status != 'cancelled' &&
            usesPaceGroups(s.groupMode))
          (
            session: s,
            groups: ref.watch(sessionGroupsProvider(s.id)).value ?? <Group>[],
          ),
    ];
    final need = entries
        .where((e) => runNeedsLeaders(e.session, e.groups))
        .length;
    final shown = [
      for (final e in entries)
        if (!_onlyNeeds || runNeedsLeaders(e.session, e.groups)) e,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leader cover'),
        actions: const [AdminAppBarAction()],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              entries.isEmpty
                  ? 'No runs with pace groups in the next 4 weeks.'
                  : 'Next 4 weeks, aiming for 8:00 to 12:00/mi plus jog/walk. '
                        '${need == 0
                            ? 'Every run is covered.'
                            : need == 1
                            ? '1 run could use a leader.'
                            : '$need runs could use a leader.'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SwitchListTile(
              key: const ValueKey('only-needs'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Show only runs that need attention'),
              value: _onlyNeeds,
              onChanged: (v) => setState(() => _onlyNeeds = v),
            ),
            for (final e in shown)
              _RunCard(
                key: ValueKey('cover-${e.session.id}'),
                session: e.session,
                groups: e.groups,
                units: units,
                now: now,
                today: today.date,
                open:
                    _open[e.session.id] ?? runNeedsLeaders(e.session, e.groups),
                onToggle: (open) => setState(() => _open[e.session.id] = open),
              ),
          ],
        ),
      ),
    );
  }
}

class _RunCard extends ConsumerWidget {
  const _RunCard({
    super.key,
    required this.session,
    required this.groups,
    required this.units,
    required this.now,
    required this.today,
    required this.open,
    required this.onToggle,
  });

  final Session session;
  final List<Group> groups;
  final UnitPrefs units;
  final DateTime now;
  final String today;
  final bool open;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spread = usesSpreadTarget(session.groupMode);
    final report = buildCoverage(groups: groups, unit: units.paceUnit);
    final canAsk = isRunOpen(session, now);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('cover-toggle-${session.id}'),
            onTap: () => onToggle(!open),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dayHeader(session.localDate, now)} · '
                          '${timeRange(session.localStartTime, session.localEndTime)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          session.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (spread)
                          SpreadChips(
                            spread: buildSpreadTarget(groups),
                            report: report,
                          )
                        else
                          _PlainChips(report: report),
                      ],
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PaceSpreadList(
                    groups: groups,
                    units: units,
                    spread: spread,
                    onAsk: canAsk
                        ? (target) => unawaited(
                            showAskLeadersSheet(
                              context,
                              ref,
                              session: session,
                              target: target,
                            ),
                          )
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: ValueKey('cover-open-${session.id}'),
                      onPressed: () =>
                          unawaited(context.push('/runs/${session.id}')),
                      child: const Text('Open run'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Covered", "No groups yet" or "2 groups need a leader" for a run with no
/// spread target (a `single` or `open` run).
class _PlainChips extends StatelessWidget {
  const _PlainChips({required this.report});

  final CoverageReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = report.needsLeader.length;
    final (text, color) = report.isEmpty
        ? ('No groups yet', scheme.error)
        : n > 0
        ? (
            n == 1 ? '1 group needs a leader' : '$n groups need a leader',
            scheme.error,
          )
        : report.ledCount == 0
        ? ('No leaders yet', scheme.error)
        : ('Covered', scheme.primary);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color),
        ),
      ),
    );
  }
}
