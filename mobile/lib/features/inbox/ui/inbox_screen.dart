import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/notifications/notification_categories.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/relative_time.dart';
import '../../membership/ui/membership_providers.dart';
import '../../messages/data/messages_repository.dart';
import '../../messages/ui/threads_section.dart';
import '../data/inbox_repository.dart';
import 'inbox_providers.dart';

/// The Inbox tab (`/inbox`): every notification the server sent this member, so a
/// missed or muted push isn't lost. Unread rows are bold with a dot. Tapping marks
/// the row read (locally first) and opens its `data.route`, if any.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _refreshing = true;
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  /// Runs [action]; a dead session is handled like everywhere else, other API
  /// errors are ignored (the local state is already updated and retried later).
  Future<bool> _guard(Future<void> Function() action) async {
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await action();
      return true;
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return true;
      return false;
    }
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(inboxRepositoryProvider);
    if (!_refreshing && mounted) setState(() => _refreshing = true);
    final ok = await _guard(() => repo.refresh(clubId));
    // The group chats list above the notifications (best effort).
    await _guard(
      () => ref.read(messagesRepositoryProvider).refreshThreadsQuietly(clubId),
    );
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _refreshFailed = !ok;
    });
  }

  Future<void> _open(InboxItem item) async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(inboxRepositoryProvider);
    final route = routeOf(item);
    final router = GoRouter.of(context);
    if (route != null) unawaited(router.push(route));
    if (item.readAt == null) {
      await _guard(() => repo.markRead(clubId, [item.id]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final items = ref.watch(inboxProvider(clubId)).value;
    final unread = ref.watch(unreadCountProvider(clubId)).value ?? 0;
    final showBanner = _refreshFailed && !_refreshing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          TextButton(
            onPressed: unread == 0
                ? null
                : () {
                    final repo = ref.read(inboxRepositoryProvider);
                    unawaited(_guard(() => repo.markAllRead(clubId)));
                  },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_refreshing && (items?.isEmpty ?? true))
                const LinearProgressIndicator(),
              const GroupChatsSection(),
              if (showBanner)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: OfflineBanner('Offline — showing saved notifications'),
                ),
              if (items != null && items.isEmpty && !_refreshing && !showBanner)
                const _EmptyInbox(),
              if (items != null)
                for (final item in items)
                  _InboxTile(item: item, onTap: () => _open(item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unread = item.readAt == null;
    final category = notificationCategoryFor(item.category).name;
    return ListTile(
      key: ValueKey('inbox-${item.id}'),
      tileColor: unread
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      leading: unread
          ? Icon(Icons.circle, size: 12, color: theme.colorScheme.primary)
          : const SizedBox(width: 12),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        '${item.body}\n$category · ${relativeTime(item.createdAt, now: ref.watch(nowProvider))}',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      onTap: onTap,
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No notifications yet', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
