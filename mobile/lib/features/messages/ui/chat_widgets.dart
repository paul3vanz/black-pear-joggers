import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/units/pace_spec.dart';
import '../../groups/ui/group_format.dart';
import '../../groups/ui/groups_providers.dart';
import '../../members/ui/member_avatar.dart';
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

/// Whether the message at [i] of [items] (newest first) ends a run by its
/// author, i.e. the next newer row is not another message from the same
/// member (a day heading also ends a run). Only the last bubble of a run shows
/// the avatar (D70).
bool endsAuthorRun(List<ChatItem> items, int i) {
  final item = items[i];
  if (item is! MessageItem) return false;
  if (i == 0) return true;
  final newer = items[i - 1];
  return newer is! MessageItem ||
      item.message.memberId.isEmpty ||
      newer.message.memberId != item.message.memberId;
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

const _avatarSize = 28.0;

/// Width reserved left of another member's bubble: avatar plus a gap.
const _avatarSlot = _avatarSize + 6;

/// A chat bubble. Own messages sit on the right; others show the author's
/// tappable name, role badge and (last of a run) avatar. A tombstone reads
/// "Message deleted"; an unsent one says "Sending..." and a refused one says to
/// tap for Retry / Delete.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = false,
    this.onTap,
    this.onLongPress,
    this.units = const UnitPrefs(),
    this.onLead,
  });

  final GroupMessage message;
  final bool isMine;

  /// Show the author's avatar beside this bubble (others' messages only). The
  /// list shows it on the LAST bubble of a run by the same author and leaves
  /// an empty gap of the same width on the earlier ones so the bubbles line up.
  final bool showAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The viewer's units, for the pace of a leaders-thread ask.
  final UnitPrefs units;

  /// "I can lead" on an ask (null: not offered, e.g. your own ask).
  final VoidCallback? onLead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = message;
    final ask = m.ask;
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
    final bubble = ConstrainedBox(
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
                        MemberNameLink(
                          memberId: m.memberId,
                          name: m.authorName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                        if (badge != null) _RoleBadge(badge),
                      ],
                    ),
                  ),
                if (ask != null)
                  AskContent(
                    ask: ask,
                    units: units,
                    color: foreground,
                    onLead: onLead,
                  )
                else
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
    );
    if (isMine) return Align(alignment: Alignment.centerRight, child: bubble);
    // Others: an avatar slot (filled on the last bubble of a run, empty on the
    // rest so bubbles line up) then the bubble, like WhatsApp or Messenger.
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: _avatarSlot,
            child: showAvatar
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 2, right: 6),
                    child: MemberAvatar(
                      key: ValueKey('message-avatar-${m.id}'),
                      memberId: m.memberId,
                      name: m.authorName,
                      size: _avatarSize,
                    ),
                  )
                : null,
          ),
          Flexible(child: bubble),
        ],
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

/// "8:25-10:05/mi" for an ask's range in [units], or null for any pace.
String? askPaceText(AskBody ask, UnitPrefs units) {
  if (!ask.hasPace) return null;
  return paceText(
    PaceSpec.fromFields(unit: 'km', fromS: ask.fastSPerKm, toS: ask.slowSPerKm),
    units,
  );
}

/// The inside of a leaders-thread ask bubble: what is wanted, the committee's
/// note and, for someone who could answer, **I can lead**.
class AskContent extends StatelessWidget {
  const AskContent({
    super.key,
    required this.ask,
    required this.units,
    required this.color,
    this.onLead,
  });

  final AskBody ask;
  final UnitPrefs units;
  final Color color;
  final VoidCallback? onLead;

  @override
  Widget build(BuildContext context) {
    final pace = askPaceText(ask, units);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                pace == null ? 'Can anyone lead?' : 'Can anyone lead $pace?',
                key: const ValueKey('ask-title'),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (ask.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(ask.note, style: TextStyle(color: color)),
          ),
        if (onLead != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FilledButton.tonal(
              key: const ValueKey('ask-lead'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onLead,
              child: const Text('I can lead'),
            ),
          ),
      ],
    );
  }
}
