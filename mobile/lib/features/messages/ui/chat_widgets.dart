import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../runs/data/runs_repository.dart';
import '../data/message_dtos.dart';

/// One row of the chat list: a day heading or a message.
sealed class ChatItem {
  const ChatItem();
}

class DayItem extends ChatItem {
  const DayItem(this.label);

  final String label;
}

class MessageItem extends ChatItem {
  const MessageItem(this.message);

  final GroupMessage message;
}

/// "Today", "Yesterday" or "Mon 12 Oct".
String chatDayLabel(DateTime day, DateTime now) {
  final d = localDateString(day);
  if (d == localDateString(now)) return 'Today';
  if (d == localDateString(now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return DateFormat('EEE d MMM').format(day);
}

/// Turns [messages] (oldest first) into list rows with a day heading before
/// the first message of each day, newest row FIRST. The chat list is a
/// `reverse: true` ListView, which keeps the newest message at the bottom and
/// stays there as messages arrive (like `flex-direction: column-reverse`).
List<ChatItem> chatItems(List<GroupMessage> messages, DateTime now) {
  final items = <ChatItem>[];
  String? lastDay;
  for (final m in messages) {
    final day = localDateString(m.createdAt);
    if (day != lastDay) {
      items.add(DayItem(chatDayLabel(m.createdAt, now)));
      lastDay = day;
    }
    items.add(MessageItem(m));
  }
  return items.reversed.toList();
}

/// Badge text for an author's role in the thread; null for a plain member.
String? roleBadge(String role) => switch (role) {
  'leader' => 'Leader',
  'coordinator' => 'Coordinator',
  'committee' => 'Committee',
  _ => null,
};

class DayHeading extends StatelessWidget {
  const DayHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A chat bubble. Own messages sit on the right; others show the author's
/// name and role badge. A tombstone reads "Message deleted"; an unsent one says
/// "Sending..." and a refused one says to tap for Retry / Delete.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onTap,
    this.onLongPress,
  });

  final GroupMessage message;
  final bool isMine;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = message;
    final deleted = m.isDeleted;
    final badge = roleBadge(m.authorRole);
    final background = m.isFailed
        ? scheme.errorContainer
        : isMine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = m.isFailed
        ? scheme.onErrorContainer
        : isMine
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final status = m.isFailed
        ? 'Failed - tap to retry or delete'
        : m.isPending
        ? 'Sending...'
        : DateFormat('HH:mm').format(m.createdAt);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Card(
          key: ValueKey('message-${m.id}'),
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: background,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            m.authorName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          if (badge != null) _RoleBadge(badge),
                        ],
                      ),
                    ),
                  Text(
                    deleted ? 'Message deleted' : m.body,
                    style: TextStyle(
                      color: foreground,
                      fontStyle: deleted ? FontStyle.italic : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: m.isFailed
                          ? scheme.error
                          : foreground.withValues(alpha: 0.7),
                      fontWeight: m.isFailed ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
