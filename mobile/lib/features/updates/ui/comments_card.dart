import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../membership/ui/membership_providers.dart';
import '../../messages/data/message_dtos.dart';
import '../../messages/data/messages_repository.dart';
import '../../messages/ui/messages_providers.dart';
import 'updates_providers.dart';

/// "Comments" under an update (D126): how many there are, whether any are
/// unread or comments are closed, and the way into the thread where members
/// ask and the committee replies. The thread is refreshed quietly when the
/// update opens, so the count shows offline from the cache.
class CommentsCard extends ConsumerStatefulWidget {
  const CommentsCard({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<CommentsCard> createState() => _CommentsCardState();
}

class _CommentsCardState extends ConsumerState<CommentsCard> {
  String get _threadId => postThreadId(widget.post.id);

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      await ref
          .read(messagesRepositoryProvider)
          .refresh(ref.read(activeClubIdProvider), _threadId);
    } on Object {
      // Offline, or not allowed: the cache (or nothing) is shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(threadMessagesProvider(_threadId)).value;
    final state = ref.watch(threadStateProvider(_threadId)).value;
    final committee = ref.watch(canPostProvider);
    final count = messages?.where((m) => !m.isDeleted).length ?? 0;
    final closed = state?.closed ?? false;
    final unread = state?.unreadCount ?? 0;
    // Nothing to ask or read on a closed update with no comments (the
    // committee still sees it, to reopen or reply).
    if (closed && count == 0 && !committee) return const SizedBox.shrink();
    final subtitle = count == 0
        ? 'Ask a question or leave a comment'
        : '${count == 1 ? '1 comment' : '$count comments'}'
              '${closed ? ' · closed' : ''}';
    return Card(
      key: const ValueKey('commentsCard'),
      margin: const EdgeInsets.only(top: 24),
      child: ListTile(
        leading: Badge(
          isLabelVisible: unread > 0,
          smallSize: 9,
          child: const Icon(Icons.chat_bubble_outline),
        ),
        title: Text(
          'Comments',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            unawaited(context.push('/updates/${widget.post.id}/comments')),
      ),
    );
  }
}
