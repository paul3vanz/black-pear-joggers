import 'package:flutter/material.dart';

import '../../groups/data/plan_dtos.dart';
import '../../groups/ui/group_format.dart';
import '../../members/ui/member_avatar.dart';

/// One event of an `events` run (a parkrun, a race) or the single card of a
/// `race` run: name, distance, the note (meeting point, car-share seats), the
/// going count, the people you are going with, and the actions the caller may
/// take. Like `GroupCard`, an action whose callback is null is not shown, so
/// the card holds no permission logic (a bit like a presentational React
/// component that gets its handlers as props).
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.title,
    this.distance,
    this.note,
    required this.going,
    this.maybe = 0,
    this.isMine = false,
    this.fellowAttendees = const [],
    this.statusNote,
    this.joinLabel = "I'm going",
    this.onJoin,
    this.onLeave,
    this.onDecline,
    this.onChat,
    this.chatUnread = false,
    this.onEditNote,
    this.onRemove,
  });

  /// The event name (or "Who's going?" on a race).
  final String title;

  /// Already formatted, e.g. "5 km"; null for none.
  final String? distance;

  /// The group description: meeting point, seats spare...
  final String? note;
  final int going;
  final int maybe;

  /// The caller is in this event.
  final bool isMine;

  /// Others going to this event, from the plan. Only given when the caller may
  /// see names (they are in it); empty hides the row.
  final List<PlanAttendee> fellowAttendees;

  /// A muted line for the caller's own state, e.g. "You can't make it."
  final String? statusNote;
  final String joinLabel;
  final VoidCallback? onJoin;

  /// "Leave": back to going without an event (events page).
  final VoidCallback? onLeave;

  /// "Can't go" (race page only).
  final VoidCallback? onDecline;

  /// Opens the chat; null hides the button. [chatUnread] adds the dot.
  final VoidCallback? onChat;
  final bool chatUnread;

  /// In the overflow menu; both null hides the menu.
  final VoidCallback? onEditNote;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final note = this.note;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: isMine
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.flag_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [title, ?distance].join(' · '),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(goingText(going, maybe), style: muted),
                    ],
                  ),
                ),
                if (onEditNote != null || onRemove != null)
                  PopupMenuButton<String>(
                    tooltip: 'Event options',
                    onSelected: (v) =>
                        v == 'note' ? onEditNote?.call() : onRemove?.call(),
                    itemBuilder: (_) => [
                      if (onEditNote != null)
                        const PopupMenuItem(
                          value: 'note',
                          child: Text('Edit note'),
                        ),
                      if (onRemove != null)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove event'),
                        ),
                    ],
                  ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note, style: muted),
            ],
            if (fellowAttendees.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Also going', style: theme.textTheme.labelLarge),
              const SizedBox(height: 2),
              Wrap(
                spacing: 12,
                runSpacing: 2,
                children: [
                  for (final a in fellowAttendees)
                    MemberLink(
                      memberId: a.memberId.isEmpty ? null : a.memberId,
                      name: a.displayName,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ],
            if (isMine)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text("You're going", style: theme.textTheme.labelLarge),
                  ],
                ),
              )
            else if (statusNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(statusNote!, style: muted),
              ),
            if (onJoin != null ||
                onLeave != null ||
                onDecline != null ||
                onChat != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (onJoin != null)
                      FilledButton.tonal(
                        onPressed: onJoin,
                        child: Text(joinLabel),
                      ),
                    if (onLeave != null)
                      OutlinedButton(
                        onPressed: onLeave,
                        child: const Text('Leave'),
                      ),
                    if (onDecline != null)
                      OutlinedButton(
                        onPressed: onDecline,
                        child: const Text("Can't go"),
                      ),
                    if (onChat != null)
                      FilledButton.tonalIcon(
                        onPressed: onChat,
                        icon: Badge(
                          key: const ValueKey('chat-unread'),
                          smallSize: 9,
                          isLabelVisible: chatUnread,
                          child: const Icon(Icons.chat_bubble_outline),
                        ),
                        label: const Text('Chat'),
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
