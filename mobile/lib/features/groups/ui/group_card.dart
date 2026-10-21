import 'package:flutter/material.dart';

import '../data/group_dtos.dart';
import 'group_format.dart';
import 'groups_providers.dart';
import 'leaders_line.dart';

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
    this.onChat,
    this.chatUnread = false,
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

  /// Opens the group chat; null (the caller is not a participant) hides the
  /// button. [chatUnread] adds a dot for unread messages.
  final VoidCallback? onChat;
  final bool chatUnread;

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
    final heading = groupHeading(g, widget.units);
    final description = g.description;
    final long =
        description != null && description.length > GroupCard.collapseAfter;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: widget.isMine
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // One heading: pace · distance (or the label when there is no
            // pace), with the label under it as a subtitle.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(groupKindIcon(g.kind), color: scheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heading.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (heading.subtitle != null)
                        Text(heading.subtitle!, style: muted),
                    ],
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
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: long && !_expanded ? 3 : null,
                overflow: long && !_expanded ? TextOverflow.ellipsis : null,
              ),
              if (long)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Show more'),
                ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LeadersLine(leaders: g.leaders, style: muted),
                Text(goingText(g.goingCount, g.maybeCount), style: muted),
              ],
            ),
            ?widget.footer,
            if (widget.isLeading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "You're leading this group",
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              )
            else if (widget.isMine)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "You're in this group",
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            if (widget.onJoin != null ||
                widget.onLeave != null ||
                widget.onLeadToo != null ||
                widget.onStepDown != null ||
                widget.onChat != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Join / Leave and Group chat share one row to keep the
                    // card short.
                    if (widget.onJoin != null ||
                        widget.onLeave != null ||
                        widget.onStepDown != null ||
                        widget.onChat != null)
                      Row(
                        children: [
                          // A leader's "Step down" sits where members have Leave
                          // group, in the error colour so it reads as different
                          // from Join.
                          if (widget.onStepDown != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: _rowButtonStyle.merge(
                                  OutlinedButton.styleFrom(
                                    foregroundColor: scheme.error,
                                    side: BorderSide(color: scheme.error),
                                  ),
                                ),
                                onPressed: widget.onStepDown,
                                icon: const Icon(
                                  Icons.person_remove_outlined,
                                  size: 18,
                                ),
                                label: const Text('Step down'),
                              ),
                            ),
                          if (widget.onJoin != null)
                            Expanded(
                              child: FilledButton.tonal(
                                style: _rowButtonStyle,
                                onPressed: widget.onJoin,
                                child: Text(
                                  widget.joinLabel,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          if (widget.onLeave != null)
                            Expanded(
                              child: OutlinedButton(
                                style: _rowButtonStyle,
                                onPressed: widget.onLeave,
                                child: const Text('Leave group'),
                              ),
                            ),
                          if ((widget.onJoin != null ||
                                  widget.onLeave != null ||
                                  widget.onStepDown != null) &&
                              widget.onChat != null)
                            const SizedBox(width: 8),
                          if (widget.onChat != null)
                            Expanded(
                              child: FilledButton.tonalIcon(
                                style: _rowButtonStyle,
                                onPressed: widget.onChat,
                                icon: Badge(
                                  key: const ValueKey('chat-unread'),
                                  smallSize: 9,
                                  isLabelVisible: widget.chatUnread,
                                  child: const Icon(Icons.chat_bubble_outline),
                                ),
                                label: const Text('Group chat'),
                              ),
                            ),
                        ],
                      ),
                    if (widget.onLeadToo != null)
                      TextButton(
                        onPressed: widget.onLeadToo,
                        child: const Text("I'll lead this group too"),
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

/// Tighter padding so two buttons fit side by side on a narrow phone.
final _rowButtonStyle = ButtonStyle(
  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
);

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
