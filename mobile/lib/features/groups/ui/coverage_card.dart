import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/dist_unit.dart';
import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import '../logic/coverage_report.dart';
import '../logic/gap_report.dart';
import '../logic/pace_spread.dart';
import 'group_access.dart';
import 'group_format.dart';
import 'groups_providers.dart';
import 'pace_strip.dart';

/// One uncovered stretch as a sentence, in [unit], e.g. "No led group between
/// 8:45 and 9:30/mi".
String coverageGapText(CoverageGap gap, DistUnit unit) {
  final code = unit.code;
  return switch (gap.kind) {
    CoverageGapKind.between =>
      'No led group between ${mmss(gap.fromIn(unit))} and '
          '${mmss(gap.toIn(unit))}/$code',
    CoverageGapKind.fasterEnd =>
      'Nobody leading faster than ${mmss(gap.toIn(unit))}/$code',
    CoverageGapKind.slowerEnd =>
      'Nobody leading slower than ${mmss(gap.fromIn(unit))}/$code '
          '(down to ${mmss(gap.toIn(unit))}/$code)',
  };
}

/// "4 runners around 10:00-10:30/mi, no group yet".
String gapText(PaceGap gap, UnitPrefs units) {
  final n = gap.count;
  return '${n == 1 ? '1 runner' : '$n runners'} around '
      '${mmss(gap.fromS)}-${mmss(gap.toS)}/${units.paceUnit.code}, no group '
      'yet. Could a leader cover this?';
}

String _groupName(Group g) {
  final label = g.label?.trim() ?? '';
  if (g.kind == 'jog_walk') return 'Jog/walk group';
  if (label.isNotEmpty) return label;
  return g.kind == 'run' ? 'Pace group' : '${groupKindLabel(g.kind)} group';
}

/// The committee's coverage view of one run: how the groups that have a
/// confirmed leader spread over the pace axis, and where the gaps are (D28).
/// It looks at leaders, not RSVPs, so it works weeks ahead. Below it, when
/// there is something to say, the people who have said they're coming and no
/// led group covers. Rendered for committee, admin and the coordinator only
/// (the caller decides; the people part also needs names in the plan).
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
    final unit = units.paceUnit;
    final report = buildCoverage(groups: groups, unit: unit);
    final open = isRunOpen(session, ref.watch(nowProvider));
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
            const SizedBox(height: 4),
            Text(
              'Groups with a leader, across the paces runners may need.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _Coverage(report: report, unit: unit),
            if (open)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(
                    context.push('/runs/${session.id}/groups/new?intent=add'),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a group'),
                ),
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

class _Coverage extends StatelessWidget {
  const _Coverage({required this.report, required this.unit});

  final CoverageReport report;
  final DistUnit unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (report.isEmpty) return const Text('No groups yet');
    final needs = report.needsLeader;
    final fast = report.fastestLed;
    final slow = report.slowestLed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.ledCount == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('No groups with a leader yet'),
          )
        else if (!report.hasBands)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('No pace group has a leader yet'),
          )
        else ...[
          CoverageStrip(report: report),
          const SizedBox(height: 8),
          if (fast != null)
            Text('Fastest led group: ${fast.pace.display(unit)}'),
          if (slow != null)
            Text('Slowest led group: ${slow.pace.display(unit)}'),
          const SizedBox(height: 8),
          for (final gap in report.gaps)
            _Line(
              icon: gap.softened
                  ? Icons.info_outline
                  : Icons.warning_amber_rounded,
              color: gap.softened ? scheme.onSurfaceVariant : scheme.error,
              text: coverageGapText(gap, unit),
            ),
        ],
        if (report.hasJogWalk)
          _Line(
            icon: Icons.directions_walk,
            color: scheme.onSurfaceVariant,
            text: 'Jog/walk group on offer',
          ),
        if (report.noPaceLed.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final g in report.noPaceLed)
                Chip(
                  avatar: Icon(groupKindIcon(g.kind), size: 18),
                  label: Text(
                    '${_groupName(g)} led by ${leadersText(g.leaders)}',
                  ),
                ),
            ],
          ),
        if (needs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Needs a leader: ${[for (final g in needs) g.pace.isNone ? _groupName(g) : g.pace.display(unit)].join(', ')}',
            ),
          ),
      ],
    );
  }
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
