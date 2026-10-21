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
import 'leaders_line.dart';

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

String _groupName(Group g) {
  final label = g.label?.trim() ?? '';
  if (g.kind == 'jog_walk') return 'Jog/walk group';
  if (label.isNotEmpty) return label;
  return g.kind == 'run' ? 'Pace group' : '${groupKindLabel(g.kind)} group';
}

/// How many things the committee still has to sort out: uncovered stretches
/// that matter and groups waiting for a leader.
int coverageToFill(CoverageReport report) =>
    report.problems.length + report.needsLeader.length;

/// The committee's coverage view of one run: the groups in pace order, fastest
/// first, with each uncovered stretch of the pace axis shown as a row between
/// them (D28, reworked as a ladder in D122). Only groups with a confirmed
/// leader cover a pace, so it works weeks ahead. Below it, when there is
/// something to say, the people who have said they're coming and no led group
/// covers. Rendered for committee, admin and the coordinator only (the caller
/// decides; the people part also needs names in the plan).
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Group coverage',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!report.isEmpty) _StatusChip(report: report),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Groups with a leader, fastest first. Gaps are paces nobody '
              'is leading.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _Ladder(report: report, units: units),
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

/// "Covered" or "2 to fill", the answer at a glance.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.report});

  final CoverageReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = coverageToFill(report);
    final covered = fill == 0 && report.ledCount > 0;
    final bg = covered ? scheme.primaryContainer : scheme.errorContainer;
    final fg = covered ? scheme.onPrimaryContainer : scheme.onErrorContainer;
    return Chip(
      key: const ValueKey('coverage-status'),
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        covered ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        size: 18,
        color: fg,
      ),
      label: Text(
        covered
            ? 'Covered'
            : report.ledCount == 0
            ? 'No leaders yet'
            : '$fill to fill',
        style: TextStyle(color: fg),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
    );
  }
}

/// The pace ladder: every group (led or not) and every uncovered stretch,
/// fastest first, then the groups with no pace.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.report, required this.units});

  final CoverageReport report;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    if (report.isEmpty) return const Text('No groups yet');
    final unit = units.paceUnit;
    // Paced groups with and without a leader, by their fastest pace.
    final steps = <({double key, Widget row})>[
      for (final g in [
        ...report.pacedLed,
        ...report.needsLeader.where((g) => g.pace.fastest != null),
      ])
        (
          key: g.pace.fastest!.secondsPerKm,
          row: _GroupRow(group: g, units: units),
        ),
      for (final gap in report.gaps)
        (key: gap.fastS, row: _GapRow(gap: gap, unit: unit)),
    ]..sort((a, b) => a.key.compareTo(b.key));
    final unpaced = [
      ...report.noPaceLed,
      ...report.needsLeader.where((g) => g.pace.fastest == null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
        for (final s in steps) s.row,
        if (unpaced.isNotEmpty) ...[
          const _SectionLabel('No set pace'),
          for (final g in unpaced) _GroupRow(group: g, units: units),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One group on the ladder. A coloured edge says whether it is led.
class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.units});

  final Group group;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final needs = group.leaders.isEmpty;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final heading = group.pace.isNone
        ? _groupName(group)
        : groupHeading(group, units).title;
    final subtitle = group.pace.isNone
        ? null
        : groupHeading(group, units).subtitle;
    return Padding(
      key: ValueKey('coverage-group-${group.id}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 4,
                  child: ColoredBox(
                    color: needs ? scheme.error : scheme.primary,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                heading,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (needs)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  'Needs a leader',
                                  style: TextStyle(
                                    color: scheme.onErrorContainer,
                                  ),
                                ),
                                backgroundColor: scheme.errorContainer,
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                        if (subtitle != null) Text(subtitle, style: muted),
                        if (!needs) LeadersLine(leaders: group.leaders),
                        if (group.goingCount + group.maybeCount > 0)
                          Text(
                            goingText(group.goingCount, group.maybeCount),
                            style: muted,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An uncovered stretch between (or beyond) the groups: red for a problem,
/// grey for information (a slow-end tail a jog/walk group softens).
class _GapRow extends StatelessWidget {
  const _GapRow({required this.gap, required this.unit});

  final CoverageGap gap;
  final DistUnit unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = gap.softened ? scheme.outline : scheme.error;
    return Padding(
      key: ValueKey('coverage-gap-${gap.fastS.round()}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                gap.softened ? Icons.info_outline : Icons.warning_amber_rounded,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(coverageGapText(gap, unit))),
            ],
          ),
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
