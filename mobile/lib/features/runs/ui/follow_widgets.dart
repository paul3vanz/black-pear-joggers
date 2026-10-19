import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../logic/follow_resolver.dart';
import '../logic/run_feed.dart';

/// The two views of the Runs tab (D117). View-only: switching never saves.
enum RunsView { mine, all }

/// **My runs | All runs**: a 48dp pill. The selected side is orange with a
/// check, so the state never relies on colour alone, and each side tells a
/// screen reader whether it is selected.
class RunsViewSwitch extends StatelessWidget {
  const RunsViewSwitch({
    required this.view,
    required this.onChanged,
    super.key,
  });

  final RunsView view;
  final ValueChanged<RunsView> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The border is painted on top, so each half's tap area is the full 48dp.
    return Container(
      height: 48,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final (v, label) in [
            (RunsView.mine, 'My runs'),
            (RunsView.all, 'All runs'),
          ])
            Expanded(
              child: _PillSegment(
                key: ValueKey('view-${v.name}'),
                label: label,
                selected: view == v,
                onTap: () => onChanged(v),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? BpjColors.black : theme.colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // The orange pill sits 3dp inside the outline; the whole half taps.
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: selected ? BpjColors.orange : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check, size: 18, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status chip on a run card: 22dp high, 12sp label, an icon where the plan
/// gives one. Not tappable.
class RunStatusChip extends StatelessWidget {
  const RunStatusChip(this.status, {super.key});

  final RunStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == RunStatus.oneOff) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final colors = RunFeedColors.of(context);
    final (
      String label,
      IconData? icon,
      Color? fill,
      Color border,
      Color fg,
    ) = switch (status) {
      RunStatus.going => (
        'Going',
        Icons.check,
        BpjColors.orange,
        BpjColors.orange,
        BpjColors.black,
      ),
      RunStatus.maybe => (
        'Maybe',
        Icons.help_outline,
        scheme.primaryContainer,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      RunStatus.following => (
        'Following',
        Icons.notifications_none,
        null,
        colors.followingOutline,
        scheme.onSurface,
      ),
      RunStatus.cantCome => (
        "Can't come",
        Icons.close,
        null,
        scheme.outline,
        scheme.onSurfaceVariant,
      ),
      RunStatus.notFollowing => (
        'Not following',
        null,
        null,
        scheme.outline,
        scheme.onSurfaceVariant,
      ),
      RunStatus.hidden => (
        'Hidden',
        Icons.visibility_off_outlined,
        null,
        scheme.outline,
        scheme.onSurfaceVariant,
      ),
      RunStatus.oneOff => (
        '',
        null,
        null,
        Colors.transparent,
        Colors.transparent,
      ),
    };
    return Container(
      key: ValueKey('status-${status.name}'),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// The All runs banner: dashed border (the cue for "temporary") and an eye.
class JustLookingBanner extends StatelessWidget {
  const JustLookingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = RunFeedColors.of(context);
    return CustomPaint(
      painter: _DashedBorderPainter(color: colors.bannerBorder, radius: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bannerFill,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, color: colors.bannerText, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Just looking. This doesn't change which runs you follow.",
                style: TextStyle(color: colors.bannerText, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.75),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// **Follow | Auto | Hide** for one series (Runs I follow): 44dp (the plan drew 42dp,
/// but every control must be at least 44dp), the selected segment with a check
/// icon. Selected colours differ in lightness as well as
/// hue (Follow solid orange, Auto the tonal container, Hide dark grey).
/// Announced as a group of three toggles, one of them selected.
class FollowModeControl extends StatelessWidget {
  const FollowModeControl({
    required this.mode,
    required this.onChanged,
    required this.seriesLabel,
    super.key,
  });

  final FollowMode mode;

  /// Null disables the control.
  final ValueChanged<FollowMode>? onChanged;

  /// For the screen reader, e.g. "Monday Club Run".
  final String seriesLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final link = theme.brightness == Brightness.dark
        ? BpjColors.orange
        : BpjColors.orangeText;
    // The outline is painted on top so each segment taps over the full height.
    return Container(
      height: 44,
      decoration: const ShapeDecoration(shape: StadiumBorder()),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final (m, label) in [
            (FollowMode.follow, 'Follow'),
            (FollowMode.auto, 'Auto'),
            (FollowMode.hide, 'Hide'),
          ])
            Expanded(
              child: Builder(
                builder: (context) {
                  final selected = m == mode;
                  final (Color bg, Color fg) = !selected
                      ? (Colors.transparent, link)
                      : switch (m) {
                          FollowMode.follow => (
                            BpjColors.orange,
                            BpjColors.black,
                          ),
                          FollowMode.auto => (
                            scheme.primaryContainer,
                            scheme.onPrimaryContainer,
                          ),
                          FollowMode.hide => (
                            theme.brightness == Brightness.dark
                                ? BpjColors.neutral600
                                : BpjColors.neutral700,
                            BpjColors.white,
                          ),
                        };
                  return Semantics(
                    button: true,
                    selected: selected,
                    inMutuallyExclusiveGroup: true,
                    enabled: onChanged != null,
                    excludeSemantics: true,
                    label: '$label, $seriesLabel',
                    child: Material(
                      color: bg,
                      child: InkWell(
                        key: ValueKey('mode-${m.name}'),
                        onTap: onChanged == null || selected
                            ? null
                            : () => onChanged!(m),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                Icon(Icons.check, size: 16, color: fg),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
