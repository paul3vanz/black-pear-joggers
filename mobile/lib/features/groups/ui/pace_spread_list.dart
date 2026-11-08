import 'package:flutter/material.dart';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';
import '../data/group_dtos.dart';
import '../logic/coverage_report.dart';
import '../logic/pace_spread.dart';
import '../logic/spread_target.dart';
import 'ask_leaders_sheet.dart';
import 'group_format.dart';
import 'groups_providers.dart';
import 'leaders_line.dart';

/// "Gap · 9:30 to 10:15/mi": where a new group would fit between two led groups.
String spreadGapText(SpreadGap gap, DistUnit unit) =>
    'Gap · ${mmss(gap.fastIn(unit))} to ${mmss(gap.slowIn(unit))}/${unit.code}';

/// "Nobody between 9:15 and 10:30".
String spreadGapDetail(SpreadGap gap, DistUnit unit) =>
    'Nobody between ${mmss(gap.fromIn(unit))} and ${mmss(gap.toIn(unit))}';

/// "Nothing faster than 8:30/mi" (the target's fast end).
String spreadFasterText(SpreadEnd end, DistUnit unit) =>
    'Nothing faster than ${mmss(end.edgeIn(unit))}/${unit.code}';

/// "Nothing slower than 11:30/mi" (the target's slow end).
String spreadSlowerText(SpreadEnd end, DistUnit unit) =>
    'Nothing slower than ${mmss(end.edgeIn(unit))}/${unit.code}';

/// What the committee asks for, after "Ask for": "a group between 9:30 and
/// 10:15/mi".
String spreadGapPhrase(SpreadGap gap, DistUnit unit) =>
    'a group between ${mmss(gap.fastIn(unit))} and '
    '${mmss(gap.slowIn(unit))}/${unit.code}';

/// The ask for a gap: the stretch, in seconds per km.
AskTarget spreadGapTarget(SpreadGap gap, DistUnit unit) => (
  fastSPerKm: gap.fastS.round(),
  slowSPerKm: gap.slowS.round(),
  jogWalk: false,
  label: spreadGapPhrase(gap, unit),
);

/// The ask for an open end: "faster than 8:30" runs from the open bound to the
/// edge, "slower than 11:30" from the edge to the open bound.
AskTarget spreadEndTarget(
  SpreadEnd end, {
  required bool faster,
  required DistUnit unit,
}) {
  final edge = end.edgeS.round();
  final shown = mmss(end.edgeIn(unit));
  return faster
      ? (
          fastSPerKm: askOpenFast,
          slowSPerKm: edge,
          jogWalk: false,
          label: 'a group faster than $shown/${unit.code}',
        )
      : (
          fastSPerKm: edge,
          slowSPerKm: askOpenSlow,
          jogWalk: false,
          label: 'a group slower than $shown/${unit.code}',
        );
}

/// Ask for a jog/walk group.
const AskTarget spreadJogWalkTarget = (
  fastSPerKm: null,
  slowSPerKm: null,
  jogWalk: true,
  label: 'a jog/walk group',
);

/// Ask for leaders for the whole run, no pace in mind.
const AskTarget spreadWholeRunTarget = (
  fastSPerKm: null,
  slowSPerKm: null,
  jogWalk: false,
  label: '',
);

/// Amber: asked for but not alarming (the ends of the target, jog/walk). The
/// theme has no warning colour, so this is a fixed amber for each brightness.
Color spreadAmber(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFF0C060)
    : const Color(0xFF8A5A00);

/// "2 gaps", "Add if you can: faster end, jog/walk" and "Covered" as chips, the
/// answer at a glance for one run.
class SpreadChips extends StatelessWidget {
  const SpreadChips({super.key, required this.spread, required this.report});

  final SpreadTarget spread;
  final CoverageReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amber = spreadAmber(context);
    final toFill = report.needsLeader.length;
    final chips = <Widget>[
      if (spread.empty)
        _Chip(
          text: report.ledCount == 0 && toFill == 0
              ? 'No groups yet'
              : 'No leaders yet',
          color: scheme.error,
        )
      else if (spread.gaps.isNotEmpty)
        _Chip(
          text: spread.gaps.length == 1
              ? '1 gap'
              : '${spread.gaps.length} gaps',
          color: scheme.error,
        ),
      if (toFill > 0)
        _Chip(
          text: toFill == 1
              ? '1 group needs a leader'
              : '$toFill groups need a leader',
          color: scheme.error,
        ),
      if (spread.fasterEnd != null ||
          spread.slowerEnd != null ||
          !spread.jogWalk)
        _Chip(
          text:
              'Add if you can: ${[if (spread.fasterEnd != null) 'faster end', if (spread.slowerEnd != null) 'slower end', if (!spread.jogWalk) 'jog/walk'].join(', ')}',
          color: amber,
        ),
      if (!spread.needsAttention && toFill == 0)
        _Chip(text: 'Covered', color: scheme.primary),
    ];
    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    ),
  );
}

/// The committee's picture of one run (D128): its groups in pace order, fastest
/// at the top, with a red gap row wherever two led groups are 45 s or more
/// apart, an amber row for an open end of the target (nothing faster than 8:30,
/// nothing slower than 11:30) and a jog/walk row last. A single pace is a dot
/// and a range a short bar, both with the pace written out; neither is treated
/// differently. A group with no leader shows as needing one. Each red or amber
/// row can be asked about ([onAsk], null to hide the buttons).
///
/// Used on the run page's coverage card and on the Leader cover screen, so the
/// committee sees one picture in both places. With [spread] false (a `single` or
/// `open` run) only the groups are listed.
class PaceSpreadList extends StatelessWidget {
  const PaceSpreadList({
    super.key,
    required this.groups,
    required this.units,
    this.spread = true,
    this.onAsk,
  });

  final List<Group> groups;
  final UnitPrefs units;
  final bool spread;

  /// Opens the ask sheet for what the row is about; null hides the buttons.
  final void Function(AskTarget target)? onAsk;

  @override
  Widget build(BuildContext context) {
    final unit = units.paceUnit;
    final report = buildCoverage(groups: groups, unit: unit);
    final target = buildSpreadTarget(groups);
    final rows = <Widget>[];

    // Paced groups, led or waiting for a leader, fastest first, with the gaps
    // between them.
    final steps = <({double key, Widget row})>[
      for (final g in [
        ...report.pacedLed,
        ...report.needsLeader.where((g) => g.pace.fastest != null),
      ])
        (
          key: g.pace.fastest!.secondsPerKm,
          row: _GroupRow(group: g, units: units, onAsk: onAsk),
        ),
      if (spread)
        for (final gap in target.gaps)
          (
            key: gap.fastS,
            row: _HoleRow(
              key: ValueKey('spread-gap-${gap.fastIn(unit)}'),
              tone: _Tone.gap,
              pace: '${mmss(gap.fastIn(unit))}-${mmss(gap.slowIn(unit))}',
              title: spreadGapText(gap, unit),
              detail: spreadGapDetail(gap, unit),
              askKey: ValueKey('ask-gap-${gap.fastIn(unit)}'),
              onAsk: onAsk == null
                  ? null
                  : () => onAsk!(spreadGapTarget(gap, unit)),
            ),
          ),
    ]..sort((a, b) => a.key.compareTo(b.key));

    if (spread && target.fasterEnd != null) {
      final end = target.fasterEnd!;
      rows.add(
        _HoleRow(
          key: const ValueKey('spread-faster-end'),
          tone: _Tone.end,
          pace: '<${mmss(end.edgeIn(unit))}',
          title: spreadFasterText(end, unit),
          detail: 'Fastest group is ${mmss(end.nearestIn(unit))}',
          askKey: const ValueKey('ask-faster-end'),
          onAsk: onAsk == null
              ? null
              : () => onAsk!(spreadEndTarget(end, faster: true, unit: unit)),
        ),
      );
    }
    if (spread && target.empty) {
      rows.add(
        _HoleRow(
          key: const ValueKey('spread-empty'),
          tone: _Tone.gap,
          pace: '8:00-12:00',
          title: report.isEmpty
              ? 'No groups yet'
              : 'No groups with a leader yet',
          detail: 'Aiming for 8:00 to 12:00/mi',
          askKey: const ValueKey('ask-run'),
          onAsk: onAsk == null ? null : () => onAsk!(spreadWholeRunTarget),
        ),
      );
    }
    rows.addAll(steps.map((s) => s.row));
    if (spread && target.slowerEnd != null) {
      final end = target.slowerEnd!;
      rows.add(
        _HoleRow(
          key: const ValueKey('spread-slower-end'),
          tone: _Tone.end,
          pace: '>${mmss(end.edgeIn(unit))}',
          title: spreadSlowerText(end, unit),
          detail: 'Slowest group is ${mmss(end.nearestIn(unit))}',
          askKey: const ValueKey('ask-slower-end'),
          onAsk: onAsk == null
              ? null
              : () => onAsk!(spreadEndTarget(end, faster: false, unit: unit)),
        ),
      );
    }

    // Groups with no pace: the jog/walk group first, then anything else.
    final unpaced =
        [
          ...report.noPaceLed,
          ...report.needsLeader.where((g) => g.pace.fastest == null),
        ]..sort(
          (a, b) =>
              (b.kind == 'jog_walk' ? 1 : 0) - (a.kind == 'jog_walk' ? 1 : 0),
        );
    for (final g in unpaced) {
      rows.add(_GroupRow(group: g, units: units, onAsk: onAsk));
    }
    if (spread &&
        !target.jogWalk &&
        !unpaced.any((g) => g.kind == 'jog_walk')) {
      rows.add(
        _HoleRow(
          key: const ValueKey('spread-jog-walk'),
          tone: _Tone.end,
          pace: 'Jog/walk',
          title: 'Jog/walk: nobody yet',
          detail: 'Add if you can',
          askKey: const ValueKey('ask-jog-walk'),
          onAsk: onAsk == null ? null : () => onAsk!(spreadJogWalkTarget),
        ),
      );
    }

    if (rows.isEmpty) return const Text('No groups yet');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// A pace column, the rail with its marker, then the content and any button.
class _RailRow extends StatelessWidget {
  const _RailRow({
    super.key,
    required this.pace,
    required this.marker,
    required this.body,
    this.trailing,
  });

  /// Pace text for the left column (already in the viewer's unit).
  final Widget pace;
  final Widget marker;
  final Widget body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final rail = Theme.of(context).colorScheme.outlineVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 78,
            child: Align(alignment: Alignment.centerRight, child: pace),
          ),
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: Container(width: 2, color: rail)),
                marker,
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: body,
            ),
          ),
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(left: 8), child: trailing),
        ],
      ),
    );
  }
}

TextStyle? _paceStyle(BuildContext context, {Color? color}) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w500,
      color: color,
    );

/// A group: its pace on the left, a dot (single pace) or a bar (range) on the
/// rail, then who leads it. A group with no leader has a hollow red marker and
/// a chip.
class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.units, this.onAsk});

  final Group group;
  final UnitPrefs units;
  final void Function(AskTarget target)? onAsk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unit = units.paceUnit;
    final needs = group.leaders.isEmpty;
    final fast = group.pace.fastest;
    final slow = group.pace.slowest;
    final isRange = group.pace is PaceRange;
    final color = needs ? scheme.error : scheme.primary;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final paceLabel = fast == null || slow == null
        ? (group.kind == 'jog_walk' ? 'Jog/walk' : groupKindLabel(group.kind))
        : isRange
        ? '${fast.convertTo(unit).format()}-${slow.convertTo(unit).format()}'
        : fast.convertTo(unit).format();
    final details = [
      if (fast != null) isRange ? 'Range' : 'Single pace',
      if ((group.label?.trim() ?? '').isNotEmpty) group.label!.trim(),
      ?distanceText(group.distance, units),
      if (group.goingCount + group.maybeCount > 0)
        goingText(group.goingCount, group.maybeCount),
    ];
    final band = group.pace.band();
    final canAsk = needs && onAsk != null && band != null;
    return _RailRow(
      key: ValueKey('coverage-group-${group.id}'),
      pace: Text(
        fast == null ? paceLabel : '$paceLabel/${unit.code}',
        style: _paceStyle(context),
        textAlign: TextAlign.right,
      ),
      marker: Container(
        width: 12,
        height: isRange ? 26 : 12,
        decoration: BoxDecoration(
          color: needs ? scheme.surface : color,
          border: needs ? Border.all(color: color, width: 2) : null,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needs)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Needs a leader',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            LeadersLine(leaders: group.leaders),
          if (details.isNotEmpty) Text(details.join(' · '), style: muted),
        ],
      ),
      trailing: canAsk
          ? FilledButton.tonal(
              key: ValueKey('ask-group-${group.id}'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => onAsk!((
                fastSPerKm: band.fast.round(),
                slowSPerKm: band.slow.round(),
                jogWalk: false,
                label: 'a group at ${paceText(group.pace, units)}',
              )),
              child: const Text('Ask'),
            )
          : null,
    );
  }
}

enum _Tone { gap, end }

/// A red gap or an amber open end: a dashed box on the rail with an Ask button.
class _HoleRow extends StatelessWidget {
  const _HoleRow({
    super.key,
    required this.tone,
    required this.pace,
    required this.title,
    required this.detail,
    required this.askKey,
    this.onAsk,
  });

  final _Tone tone;
  final String pace;
  final String title;
  final String detail;
  final Key askKey;
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == _Tone.gap
        ? theme.colorScheme.error
        : spreadAmber(context);
    return _RailRow(
      pace: Text(
        pace,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.right,
      ),
      marker: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
      trailing: onAsk == null
          ? null
          : FilledButton.tonal(
              key: askKey,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: onAsk,
              child: const Text('Ask'),
            ),
    );
  }
}
