import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../data/notification_settings_repository.dart';
import 'settings_providers.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "Tuesday 19:00 · Tuesday run" (weekday is ISO, 1 = Monday).
String seriesLabel(SeriesReminder s) {
  final day = _weekdays[(s.weekday - 1).clamp(0, 6)];
  final time = s.localStartTime.isEmpty ? '' : ' ${s.localStartTime}';
  return '$day$time · ${s.title}';
}

typedef _Merge = NotificationSettings Function(
  NotificationSettings current,
  NotificationSettings other,
);

/// The two sections under the category switches on the Notification settings
/// screen: "Daily push limit" and "Run reminders". Each change is applied to the
/// UI at once and saved straight away (reverted with a snackbar if it fails).
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

  /// Controls with a save in flight: `'cap'` or a series id.
  final _saving = <String>{};

  /// Applies [optimistic] now, sends it, then merges the server's answer for
  /// just this control ([adopt]) or puts the old value back ([revert]). Merging
  /// per control keeps two quick changes from overwriting each other.
  Future<void> _save({
    required String key,
    required NotificationSettings optimistic,
    required Future<NotificationSettings> Function(
      NotificationSettingsRepository repo,
    )
    send,
    required _Merge adopt,
    required _Merge revert,
    required NotificationSettings before,
  }) async {
    final repo = ref.read(notificationSettingsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _current = optimistic;
      _saving.add(key);
    });
    try {
      final server = await send(repo);
      if (mounted) setState(() => _current = adopt(_current ?? server, server));
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      setState(() => _current = revert(_current ?? before, before));
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
      if (mounted) setState(() => _saving.remove(key));
    }
  }

  void _setCap(NotificationSettings now, int cap) {
    if (cap == now.dailyPushCap) return;
    unawaited(
      _save(
        key: 'cap',
        before: now,
        optimistic: now.copyWith(dailyPushCap: cap),
        send: (repo) => repo.update(widget.clubId, dailyPushCap: cap),
        adopt: (cur, server) => cur.copyWith(dailyPushCap: server.dailyPushCap),
        revert: (cur, before) =>
            cur.copyWith(dailyPushCap: before.dailyPushCap),
      ),
    );
  }

  void _setReminders(
    NotificationSettings now,
    SeriesReminder series,
    ReminderMode mode,
  ) {
    if (mode == series.reminders) return;
    final id = series.seriesId;
    // One series' mode out of a settings object, as a copyWith argument.
    Map<String, ReminderMode> only(NotificationSettings s) => {
      for (final r in s.series.where((r) => r.seriesId == id)) id: r.reminders,
    };
    unawaited(
      _save(
        key: id,
        before: now,
        optimistic: now.copyWith(series: {id: mode}),
        send: (repo) => repo.update(widget.clubId, series: {id: mode}),
        adopt: (cur, server) => cur.copyWith(series: only(server)),
        revert: (cur, before) => cur.copyWith(series: only(before)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationSettingsProvider(widget.clubId));
    final settings = _current ?? async.value;
    if (settings == null) {
      if (async.hasError) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text("Couldn't load your push limit and reminders."),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(notificationSettingsProvider(widget.clubId)),
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // 3 / 6 / 12 / No limit, plus the current value if it's something else
    // (set elsewhere). 0 means "no limit" so it sorts last.
    final caps = {3, 6, 12, 0, settings.dailyPushCap}.toList()
      ..sort((a, b) => (a == 0 ? 999 : a).compareTo(b == 0 ? 999 : b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
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
                  onSelectionChanged: _saving.contains('cap')
                      ? null
                      : (s) => _setCap(settings, s.first),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Run reminders', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Automatic reminds you about runs you usually come to. '
                'Choose Always or Never for a particular run.',
                style: muted,
              ),
              const SizedBox(height: 8),
              if (settings.series.isEmpty)
                Text('No regular runs yet.', style: muted),
              for (final s in settings.series)
                Padding(
                  key: ValueKey('series-${s.seriesId}'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seriesLabel(s)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ReminderMode>(
                          key: ValueKey('reminders-${s.seriesId}'),
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: ReminderMode.auto,
                              label: Text('Automatic'),
                            ),
                            ButtonSegment(
                              value: ReminderMode.on,
                              label: Text('Always'),
                            ),
                            ButtonSegment(
                              value: ReminderMode.off,
                              label: Text('Never'),
                            ),
                          ],
                          selected: {s.reminders},
                          onSelectionChanged: _saving.contains(s.seriesId)
                              ? null
                              : (m) => _setReminders(settings, s, m.first),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
