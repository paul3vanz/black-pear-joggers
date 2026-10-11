import 'package:flutter/material.dart';

import '../data/group_dtos.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// One group of a session: kind, pace and distance in the viewer's units,
/// label, description, leaders, a "Needs a leader" badge, the going count and
/// the actions the caller may take. An action whose callback is null is not
/// shown, so the card itself holds no permission logic.
class GroupCard extends StatefulWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.units,
    this.isMine = false,
    this.isLeading = false,
    this.joinLabel = 'Join this group',
    this.onJoin,
    this.onLeave,
    this.onLeadToo,
    this.onStepDown,
    this.onEdit,
    this.onDelete,
    this.footer,
  });

  final Group group;
  final UnitPrefs units;

  /// The caller has chosen this group.
  final bool isMine;

  /// The caller leads this group (shows "You're leading this group").
  final bool isLeading;
  final String joinLabel;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onLeadToo;
  final VoidCallback? onStepDown;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Extra content under the going count (the pace spread on route cards).
  final Widget? footer;

  /// Descriptions longer than this collapse behind "Show more".
  static const collapseAfter = 140;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pace = paceText(g.pace, widget.units);
    final distance = distanceText(g.distance, widget.units);
    final description = g.description;
    final long =
        description != null && description.length > GroupCard.collapseAfter;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: widget.isMine
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(groupKindIcon(g.kind), color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groupKindLabel(g.kind),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (g.needsLeader)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      'Needs a leader',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                    backgroundColor: scheme.errorContainer,
                  ),
                if (widget.onEdit != null || widget.onDelete != null)
                  _Menu(onEdit: widget.onEdit, onDelete: widget.onDelete),
              ],
            ),
            if (g.label != null)
              Text(
                g.label!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (pace.isNotEmpty)
              Text(
                pace,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (distance != null)
              Text(distance, style: theme.textTheme.bodyLarge),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: long && !_expanded ? 3 : null,
                overflow: long && !_expanded ? TextOverflow.ellipsis : null,
              ),
              if (long)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Show more'),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              g.leaders.isEmpty
                  ? 'No leader yet'
                  : 'Led by ${leadersText(g.leaders)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              goingText(g.goingCount, g.maybeCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            ?widget.footer,
            if (widget.isMine || widget.isLeading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.isLeading
                      ? "You're leading this group"
                      : "You're in this group",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
            if (widget.onJoin != null ||
                widget.onLeave != null ||
                widget.onLeadToo != null ||
                widget.onStepDown != null)
              const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.onJoin != null)
                  FilledButton.tonal(
                    onPressed: widget.onJoin,
                    child: Text(widget.joinLabel),
                  ),
                if (widget.onLeave != null)
                  OutlinedButton(
                    onPressed: widget.onLeave,
                    child: const Text('Leave group'),
                  ),
                if (widget.onLeadToo != null)
                  TextButton(
                    onPressed: widget.onLeadToo,
                    child: const Text("I'll lead this group too"),
                  ),
                if (widget.onStepDown != null)
                  TextButton(
                    onPressed: widget.onStepDown,
                    child: const Text('Step down'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Group options',
    onSelected: (v) => v == 'edit' ? onEdit?.call() : onDelete?.call(),
    itemBuilder: (_) => [
      if (onEdit != null)
        const PopupMenuItem(value: 'edit', child: Text('Edit group')),
      if (onDelete != null)
        const PopupMenuItem(value: 'delete', child: Text('Delete group')),
    ],
  );
}
