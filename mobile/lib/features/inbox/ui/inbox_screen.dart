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
import '../../messages/ui/messages_providers.dart';
import '../../messages/ui/threads_section.dart';
import '../data/inbox_repository.dart';
import '../logic/inbox_folders.dart';
import 'inbox_providers.dart';

/// The Inbox tab (`/inbox`): every notification the server sent this member, so a
/// missed or muted push isn't lost. Unread rows are bold with a dot. Tapping marks
/// the row read (locally first) and opens its `data.route`, if any.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  bool _refreshing = true;
  bool _refreshFailed = false;

  /// The smart view (All, Chats, Updates, Runs). Screen state only, like the
  /// My runs / All runs switch: not remembered.
  late final TabController _tabs = TabController(
    length: InboxFolder.values.length,
    vsync: this,
  )..addListener(() => setState(() {}));

  InboxFolder get _folder => InboxFolder.values[_tabs.index];

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
    final threads = ref.watch(threadsProvider(clubId)).value ?? const [];
    final showBanner = _refreshFailed && !_refreshing;
    final folder = _folder;
    final inFolder = [
      for (final i in items ?? const <InboxItem>[])
        if (folder.holds(i.category, route: routeOf(i))) i,
    ];
    final unreadHere = [
      for (final i in inFolder)
        if (i.readAt == null) i.id,
    ];
    // A dot on a tab with anything unread in it (chats also count threads).
    bool unreadIn(InboxFolder f) =>
        (items ?? const <InboxItem>[]).any(
          (i) => i.readAt == null && f.holds(i.category, route: routeOf(i)),
        ) ||
        threads.any((t) => t.unreadCount > 0 && f.holdsThread(t.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          TextButton(
            onPressed: unreadHere.isEmpty
                ? null
                : () {
                    final repo = ref.read(inboxRepositoryProvider);
                    unawaited(
                      _guard(
                        () => folder == InboxFolder.all
                            ? repo.markAllRead(clubId)
                            : repo.markRead(clubId, unreadHere),
                      ),
                    );
                  },
            child: const Text('Mark all read'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            for (final f in InboxFolder.values)
              Tab(
                key: ValueKey('inbox-tab-${f.name}'),
                child: Badge(
                  key: ValueKey('inbox-tab-dot-${f.name}'),
                  smallSize: 8,
                  isLabelVisible: unreadIn(f),
                  alignment: AlignmentDirectional.topEnd,
                  offset: const Offset(6, -2),
                  child: Text(f.label),
                ),
              ),
          ],
        ),
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
              if (folder.showsThreads)
                GroupChatsSection(
                  include: folder.holdsThread,
                  title: folder == InboxFolder.leaders
                      ? 'Leaders threads'
                      : 'Group chats',
                ),
              if (showBanner)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: OfflineBanner('Offline — showing saved notifications'),
                ),
              if (items != null &&
                  inFolder.isEmpty &&
                  !_refreshing &&
                  !showBanner &&
                  // Chats shows the threads above even with no notifications.
                  !threads.any((t) => folder.holdsThread(t.groupId)))
                _EmptyInbox(text: folder.emptyText),
              for (final item in inFolder)
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
  const _EmptyInbox({required this.text});

  final String text;

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
          Text(text, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
