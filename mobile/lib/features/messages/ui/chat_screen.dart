import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/clock.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../groups/data/group_dtos.dart';
import '../../groups/ui/group_access.dart';
import '../../groups/ui/group_format.dart';
import '../../groups/ui/groups_providers.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../../runs/ui/session_actions.dart' show confirm;
import '../data/message_dtos.dart';
import '../data/messages_repository.dart';
import 'chat_widgets.dart';
import 'messages_providers.dart';

/// How often an open chat asks the server for new messages (D42).
const chatPollInterval = Duration(seconds: 8);

/// Show the character counter once this many characters are typed.
const _counterFrom = 900;

/// `/runs/:sessionId/groups/:groupId/chat`: one group's thread. It reads the
/// Drift cache only; a Timer pulls `?since=` deltas every [pollInterval] while
/// the screen is open (and a push for this group refreshes it at once, see
/// `PushService`). Opening it and new messages arriving mark the thread read.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.sessionId,
    required this.groupId,
    this.pollInterval = chatPollInterval,
  });

  final String sessionId;
  final String groupId;
  final Duration pollInterval;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;
  late final OpenChatGroup _openChat;

  bool _polling = false;
  bool _offline = false;

  /// The server was told the thread is read (false while offline: retried on
  /// the next poll).
  bool _readSynced = false;
  bool _gone = false;
  bool _infoHidden = false;

  String get _groupId => widget.groupId;
  int get _clubId => ref.read(activeClubIdProvider);

  @override
  void initState() {
    super.initState();
    _openChat = ref.read(openChatGroupIdProvider.notifier);
    _input.addListener(() => setState(() {})); // enables Send, shows counter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openChat.open(_groupId);
      unawaited(_markRead());
      unawaited(_poll());
    });
    _timer = Timer.periodic(widget.pollInterval, (_) => unawaited(_poll()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Provider state can't change while the tree is being torn down.
    Future.microtask(() => _openChat.close(_groupId));
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Runs [action]. A dead session is handled like everywhere else; returns
  /// the error otherwise (null on success).
  Future<ApiException?> _guard(Future<void> Function() action) async {
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      await action();
      return null;
    } on Object catch (e) {
      if (sub != null) await handleExpiry(sub, e);
      return ApiException.from(e);
    }
  }

  Future<void> _poll() async {
    if (_polling || _gone || !mounted) return;
    _polling = true;
    final repo = ref.read(messagesRepositoryProvider);
    final error = await _guard(() => repo.refresh(_clubId, _groupId));
    _polling = false;
    if (!mounted) return;
    if (error != null && (error.statusCode == 403 || error.statusCode == 404)) {
      _leave();
      return;
    }
    setState(() => _offline = error != null && !error.isSessionExpired);
    if (error == null && !_readSynced) unawaited(_markRead());
  }

  Future<void> _markRead() async {
    _readSynced = false;
    final repo = ref.read(messagesRepositoryProvider);
    var ok = false;
    await _guard(() async => ok = await repo.markRead(_clubId, _groupId));
    if (mounted) _readSynced = ok;
  }

  /// Access lost (403 `not_in_group`): say so and go back.
  void _leave() {
    _timer?.cancel();
    setState(() => _gone = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You're no longer in this group")),
    );
    unawaited(Navigator.of(context).maybePop());
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(messagesRepositoryProvider);
    SendResult? result;
    final error = await _guard(() async {
      result = await repo.send(_clubId, _groupId, text);
    });
    _scrollToNewest();
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } else if (result?.outcome == SendOutcome.failed) {
      messenger.showSnackBar(SnackBar(content: Text(result!.error!.message)));
    }
  }

  /// A reverse list's offset 0 is its bottom, so this shows the newest message.
  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<void> _delete(GroupMessage m) async {
    final ok = await confirm(
      context,
      title: 'Delete this message?',
      message: 'It will show as "Message deleted" for everyone in the group.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(messagesRepositoryProvider);
    final error = await _guard(() => repo.delete(m.id));
    if (error == null || error.isSessionExpired) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.isNetworkError
              ? 'You need a connection to delete a message.'
              : error.statusCode == 403
              ? "You can't delete that message."
              : error.message,
        ),
      ),
    );
  }

  /// Tap on a message that was refused: Retry or Delete.
  Future<void> _failedActions(GroupMessage m) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry'),
              onTap: () => Navigator.of(ctx).pop('retry'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete message'),
              onTap: () => Navigator.of(ctx).pop('discard'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final repo = ref.read(messagesRepositoryProvider);
    if (choice == 'discard') {
      await repo.discard(m.id);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    SendResult? result;
    final error = await _guard(() async => result = await repo.retry(m.id));
    if (!mounted) return;
    final message = error?.message ?? result?.error?.message;
    if (message != null && result?.outcome != SendOutcome.queued) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _toggleMute(bool muted) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(messagesRepositoryProvider);
    final error = await _guard(() => repo.setMuted(_clubId, _groupId, muted));
    if (error == null || error.isSessionExpired) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.isNetworkError
              ? 'You need a connection to change that.'
              : error.message,
        ),
      ),
    );
  }

  Future<void> _dismissInfo() async {
    setState(() => _infoHidden = true);
    await ref.read(messagesRepositoryProvider).dismissInfo();
    ref.invalidate(chatInfoDismissedProvider);
  }

  /// Number of messages from other people, to spot new arrivals.
  int _incoming(List<GroupMessage>? list, String? me) => list == null
      ? 0
      : list
            .where((m) => m.memberId != me && !m.isDeleted && !m.isPending)
            .length;

  /// The title line under "Group chat": the pace/label and the run.
  String _subtitle(
    ThreadState? thread,
    Group? group,
    Session? session,
    UnitPrefs units,
  ) {
    final label =
        thread?.label ??
        group?.label ??
        (group == null ? null : paceText(group.pace, units));
    return [
      if (label != null && label.isNotEmpty) label,
      ?session?.title,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(myMemberIdProvider);
    final messages = ref.watch(threadMessagesProvider(_groupId)).value;
    final thread = ref.watch(threadStateProvider(_groupId)).value;
    final groups = ref.watch(sessionGroupsProvider(widget.sessionId)).value;
    final session = ref.watch(sessionProvider(widget.sessionId)).value;
    final units = ref.watch(unitPrefsProvider);
    final group = groups?.where((g) => g.id == _groupId).firstOrNull;
    final muted = thread?.muted ?? false;
    final closed = thread?.closed ?? false;
    final dismissed = ref.watch(chatInfoDismissedProvider).value ?? true;

    // New messages from others while the screen is open: mark the thread read.
    ref.listen(threadMessagesProvider(_groupId), (previous, next) {
      final before = previous?.value;
      if (before != null && _incoming(next.value, me) > _incoming(before, me)) {
        unawaited(_markRead());
      }
    });

    final canModerate =
        ref.watch(canManageRunsProvider) ||
        (me != null &&
            ((group?.isLedBy(me) ?? false) ||
                session?.coordinatorMemberId == me));
    final subtitle = _subtitle(thread, group, session, units);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group chat'),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          if (muted)
            const Icon(
              Icons.notifications_off_outlined,
              semanticLabel: 'Muted',
            ),
          PopupMenuButton<bool>(
            tooltip: 'Chat options',
            onSelected: (value) => unawaited(_toggleMute(value)),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: !muted,
                checked: muted,
                child: const Text('Mute notifications'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _gone
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("You're no longer in this group"),
                ),
              )
            : Column(
                children: [
                  if (_offline)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: OfflineBanner(
                        'Offline — showing saved messages. Messages you send '
                        'go out when you are back online.',
                      ),
                    ),
                  if (!dismissed && !_infoHidden)
                    _InfoLine(onDismiss: () => unawaited(_dismissInfo())),
                  Expanded(
                    child: _MessageList(
                      messages: messages,
                      controller: _scroll,
                      now: ref.watch(clubTodayProvider).now,
                      isMine: (m) => m.memberId == me,
                      canDelete: (m) =>
                          !m.isDeleted &&
                          !m.isPending &&
                          !m.isFailed &&
                          (m.memberId == me || canModerate),
                      onFailedTap: _failedActions,
                      onDelete: _delete,
                    ),
                  ),
                  if (closed)
                    const _ClosedBar()
                  else
                    _InputBar(
                      controller: _input,
                      onSend: () => unawaited(_send()),
                    ),
                ],
              ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Everyone in this group can see your name. Committee can read '
              'group chats.',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, color: scheme.onSecondaryContainer),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.controller,
    required this.now,
    required this.isMine,
    required this.canDelete,
    required this.onFailedTap,
    required this.onDelete,
  });

  final List<GroupMessage>? messages;
  final ScrollController controller;
  final DateTime now;
  final bool Function(GroupMessage) isMine;
  final bool Function(GroupMessage) canDelete;
  final void Function(GroupMessage) onFailedTap;
  final void Function(GroupMessage) onDelete;

  @override
  Widget build(BuildContext context) {
    final list = messages;
    if (list == null) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No messages yet. Say hello to your group!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final items = chatItems(list, now);
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, i) => switch (items[i]) {
        DayItem(:final label) => DayHeading(label),
        MessageItem(:final message) => MessageBubble(
          message: message,
          isMine: isMine(message),
          showAvatar: !isMine(message) && endsAuthorRun(items, i),
          onTap: message.isFailed ? () => onFailedTap(message) : null,
          onLongPress: message.isFailed
              ? () => onFailedTap(message)
              : canDelete(message)
              ? () => onDelete(message)
              : null,
        ),
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: maxMessageLength,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message your group',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                // A counter only close to the limit, so it doesn't add noise.
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => currentLength < _counterFrom
                    ? null
                    : Text(
                        '$currentLength/$maxLength',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: currentLength >= maxMessageLength
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
              ),
            ),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: controller.text.trim().isEmpty ? null : onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedBar extends StatelessWidget {
  const _ClosedBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat closed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Posting stops 12 hours after the run, or when it is '
                    'cancelled. You can still read the messages.',
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
