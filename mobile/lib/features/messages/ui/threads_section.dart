import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/run_format.dart';
import 'messages_providers.dart';

/// "Group chats" at the top of the Inbox tab: the caller's threads (from
/// `GET …/threads`, cached) with the run date, the last message, an unread
/// badge and a muted icon. Renders nothing while there are none.
class GroupChatsSection extends ConsumerWidget {
  const GroupChatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(activeClubIdProvider);
    final threads = ref.watch(threadsProvider(clubId)).value ?? const [];
    if (threads.isEmpty) return const SizedBox.shrink();
    final now = ref.watch(clubTodayProvider).now;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Group chats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final t in threads) _ThreadTile(thread: t, now: now),
        const Divider(),
      ],
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.now});

  final ThreadState thread;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = thread.unreadCount;
    final date = thread.localDate == null
        ? null
        : dayHeader(thread.localDate!, now);
    final last = thread.lastBody == null
        ? null
        : '${thread.lastAuthor == null ? '' : '${thread.lastAuthor}: '}'
              '${thread.lastBody}';
    return ListTile(
      key: ValueKey('thread-${thread.groupId}'),
      leading: const Icon(Icons.forum_outlined),
      title: Text(
        [thread.label ?? 'Group chat', ?date].join(' · '),
        style: TextStyle(fontWeight: unread > 0 ? FontWeight.w700 : null),
      ),
      subtitle: last == null
          ? null
          : Text(last, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (thread.muted)
            Icon(
              Icons.notifications_off_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: 'Muted',
            ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Badge(label: Text(unread > 99 ? '99+' : '$unread')),
          ],
        ],
      ),
      onTap: thread.sessionId == null
          ? null
          : () => unawaited(
              context.push(
                '/runs/${thread.sessionId}/groups/${thread.groupId}/chat',
              ),
            ),
    );
  }
}
