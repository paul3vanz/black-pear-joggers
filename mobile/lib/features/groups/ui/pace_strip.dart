import 'package:flutter/material.dart';

import '../../../core/units/pace.dart';
import '../logic/coverage_report.dart';
import '../logic/pace_spread.dart';

/// A compact histogram of [spread]: one bar per pace bucket, fastest on the
/// left, with the outer buckets labelled. Anonymous: it only shows counts.
class PaceStrip extends StatelessWidget {
  const PaceStrip({super.key, required this.spread, this.height = 36});

  final PaceSpread spread;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (spread.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = spread.maxCount;
    final first = spread.buckets.first;
    final last = spread.buckets.last;
    final code = spread.unit.code;
    return Semantics(
      label: 'Pace spread, ${spread.total} with a pace',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in spread.buckets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: b.count == 0
                              ? 2
                              : 6 + (height - 6) * b.count / max,
                          decoration: BoxDecoration(
                            color: b.count == 0
                                ? scheme.outlineVariant
                                : scheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mmss(first.fromS)}/$code',
                style: theme.textTheme.labelSmall,
              ),
              Text(
                '${mmss(last.toS)}/$code',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pace axis of a [CoverageReport]: covered bands filled, gaps outlined
/// (red for a problem, grey for information), the two window ends labelled.
/// Fastest on the left, like [PaceStrip].
class CoverageStrip extends StatelessWidget {
  const CoverageStrip({super.key, required this.report, this.height = 22});

  final CoverageReport report;
  final double height;

  String _end(double secPerKm) {
    final s = (secPerKm * report.unit.kmPerUnit / 5).round() * 5;
    return '${Pace(s, report.unit).format()}/${report.unit.code}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final span = report.windowSlowS - report.windowFastS;
    if (span <= 0) return const SizedBox.shrink();
    return Semantics(
      label:
          'Pace coverage from ${_end(report.windowFastS)} to '
          '${_end(report.windowSlowS)}, ${report.bands.length} covered '
          'stretches, ${report.gaps.length} gaps',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                double x(double s) =>
                    ((s - report.windowFastS) / span).clamp(0.0, 1.0) * w;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    for (final g in report.gaps)
                      Positioned(
                        key: ValueKey('coverage-gap-${g.fastS.round()}'),
                        left: x(g.fastS),
                        width: x(g.slowS) - x(g.fastS),
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: (g.softened ? scheme.outline : scheme.error)
                                .withValues(alpha: 0.12),
                            border: Border.all(
                              color: g.softened ? scheme.outline : scheme.error,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    for (final b in report.bands)
                      Positioned(
                        left: x(b.fastS),
                        width: x(b.slowS) - x(b.fastS),
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_end(report.windowFastS), style: theme.textTheme.labelSmall),
              Text(_end(report.windowSlowS), style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
