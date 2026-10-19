import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../data/notification_settings_repository.dart';
import 'settings_providers.dart';

/// The two sections under the category switches on the Notification settings
/// screen: "Daily push limit", applied to the UI at once and saved straight
/// away (reverted with a snackbar if it fails), and "Run reminders", one row
/// that opens Runs I follow (D117), where reminders are chosen with the feed.
class PushLimitAndReminders extends ConsumerStatefulWidget {
  const PushLimitAndReminders({required this.clubId, super.key});

  final int clubId;

  @override
  ConsumerState<PushLimitAndReminders> createState() =>
      _PushLimitAndRemindersState();
}

class _PushLimitAndRemindersState extends ConsumerState<PushLimitAndReminders> {
  /// Local copy of the settings, updated optimistically; falls back to the GET.
  NotificationSettings? _current;
  bool _saving = false;

  Future<void> _setCap(NotificationSettings now, int cap) async {
    if (cap == now.dailyPushCap) return;
    final repo = ref.read(notificationSettingsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _current = now.copyWith(dailyPushCap: cap);
      _saving = true;
    });
    try {
      final server = await repo.update(widget.clubId, dailyPushCap: cap);
      if (mounted) setState(() => _current = server);
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      setState(() => _current = now);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ApiException.from(e).isNetworkError
                ? "You're offline. Try again when you're connected."
                : "Couldn't save that change.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationSettingsProvider(widget.clubId));
    final settings = _current ?? async.value;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final Widget cap;
    if (settings == null) {
      cap = async.hasError
          ? Row(
              children: [
                const Expanded(child: Text("Couldn't load your push limit.")),
                TextButton(
                  onPressed: () => ref.invalidate(
                    notificationSettingsProvider(widget.clubId),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            )
          : const SizedBox.shrink();
    } else {
      // 3 / 6 / 12 / No limit, plus the current value if it's something else
      // (set elsewhere). 0 means "no limit" so it sorts last.
      final caps = {3, 6, 12, 0, settings.dailyPushCap}.toList()
        ..sort((a, b) => (a == 0 ? 999 : a).compareTo(b == 0 ? 999 : b));
      cap = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily push limit', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            settings.dailyPushCap == 0
                ? 'No limit: every notification can buzz your phone. '
                      'Everything still arrives in your inbox.'
                : 'At most ${settings.dailyPushCap} notifications a day '
                      'will buzz your phone (important club news and '
                      'changes to your own runs always do). Everything '
                      'still arrives in your inbox.',
            style: muted,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              key: const ValueKey('push-cap'),
              showSelectedIcon: false,
              segments: [
                for (final c in caps)
                  ButtonSegment(
                    value: c,
                    label: Text(c == 0 ? 'No limit' : '$c'),
                  ),
              ],
              selected: {settings.dailyPushCap},
              // Null disables the control while its save is in flight.
              onSelectionChanged: _saving
                  ? null
                  : (s) => unawaited(_setCap(settings, s.first)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: cap,
        ),
        const Divider(height: 32),
        ListTile(
          key: const ValueKey('runsIFollowRow'),
          minTileHeight: 56,
          leading: const Icon(Icons.notifications_none),
          title: const Text('Run reminders'),
          subtitle: const Text(
            "You're reminded about the runs you follow. Choose them in "
            'Runs I follow.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(context.push('/follows')),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
