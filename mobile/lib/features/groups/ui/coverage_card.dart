import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/admin_only.dart';
import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/dist_unit.dart';
import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import '../logic/coverage_report.dart';
import '../logic/gap_report.dart';
import '../logic/pace_spread.dart';
import '../logic/spread_target.dart';
import '../../runs/logic/run_modes.dart';
import '../../runs/ui/runs_providers.dart';
import 'ask_leaders_sheet.dart';
import 'group_access.dart';
import 'groups_providers.dart';
import 'pace_spread_list.dart';

/// One uncovered stretch as a sentence, in [unit], e.g. "No led group between
/// 8:45 and 9:30/mi".
String coverageGapText(CoverageGap gap, DistUnit unit) {
  final code = unit.code;
  return switch (gap.kind) {
    CoverageGapKind.between =>
      'No led group between ${mmss(gap.fromIn(unit))} and '
          '${mmss(gap.toIn(unit))}/$code',
    CoverageGapKind.fasterEnd =>
      'No group faster than ${mmss(gap.toIn(unit))}/$code',
    CoverageGapKind.slowerEnd =>
      'No group slower than ${mmss(gap.fromIn(unit))}/$code',
  };
}

/// "4 runners around 10:00-10:30/mi, no group yet".
String gapText(PaceGap gap, UnitPrefs units) {
  final n = gap.count;
  return '${n == 1 ? '1 runner' : '$n runners'} around '
      '${mmss(gap.fromS)}-${mmss(gap.toS)}/${units.paceUnit.code}, no group '
      'yet. Could a leader cover this?';
}

/// The committee's coverage view of one run: the groups in pace order, fastest
/// first, with the holes in the spread of paces shown between them (D28, a
/// ladder in D122, the committee's own target in D128): see [PaceSpreadList].
/// Only groups with a confirmed leader cover a pace, so it works weeks ahead.
/// Below it, when there is something to say, the people who have said they're
/// coming and no led group covers. Rendered for committee, admin and the
/// coordinator only (the caller decides; the people part also needs names in
/// the plan).
class CoverageCard extends ConsumerWidget {
  const CoverageCard({
    super.key,
    required this.session,
    required this.plan,
    required this.groups,
    required this.units,
  });

  final Session session;

  /// Null until the plan has loaded; the people section then stays hidden.
  final SessionPlan? plan;
  final List<Group> groups;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final report = buildCoverage(groups: groups, unit: units.paceUnit);
    final spread = usesSpreadTarget(session.groupMode);
    final open = isRunOpen(session, ref.watch(nowProvider));
    final isCommittee = ref.watch(canManageRunsProvider);
    final canAsk = isCommittee && open;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group coverage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (spread && !report.isEmpty) ...[
              const SizedBox(height: 6),
              SpreadChips(
                key: const ValueKey('coverage-status'),
                spread: buildSpreadTarget(groups),
                report: report,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              spread
                  ? 'Groups with a leader, fastest first, aiming for 8:00 to '
                        '12:00/mi plus jog/walk. Red is a gap between two '
                        'groups, amber is something to add if you can.'
                  : 'Groups with a leader, fastest first.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            PaceSpreadList(
              groups: groups,
              units: units,
              spread: spread,
              // Committee only (the server agrees), while the run is open.
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
            Wrap(
              children: [
                if (open)
                  TextButton.icon(
                    onPressed: () => unawaited(
                      context.push('/runs/${session.id}/groups/new?intent=add'),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a group'),
                  ),
                if (isCommittee)
                  TextButton.icon(
                    key: const ValueKey('open-leaders-chat'),
                    onPressed: () => unawaited(
                      context.push('/runs/${session.id}/leaders-chat'),
                    ),
                    icon: const Icon(Icons.forum_outlined),
                    label: const AdminLabel('Leaders thread'),
                  ),
              ],
            ),
            _People(plan: plan, report: report, units: units),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// "People coming with no matching group": the attendee-based view. Shown
/// only when some going/maybe member has a pace no led group covers, or has no
/// pace at all.
class _People extends StatelessWidget {
  const _People({
    required this.plan,
    required this.report,
    required this.units,
  });

  final SessionPlan? plan;
  final CoverageReport report;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final members = p == null ? null : gapMembers(p);
    if (members == null || members.isEmpty) return const SizedBox.shrink();
    final gaps = buildGapReport(
      members: members,
      groups: [for (final g in report.pacedLed) g.pace],
      unit: units.paceUnit,
    );
    if (!gaps.hasGaps && gaps.noPace.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            'People coming with no matching group',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Based on the ${members.length} people who have said they're "
            'coming so far — more may join closer to the day.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final gap in gaps.gaps)
            _Line(
              icon: Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              text: gapText(gap, units),
            ),
          if (gaps.noPace.isNotEmpty)
            Text('${gaps.noPace.length} going with no pace set'),
        ],
      ),
    );
  }
}
