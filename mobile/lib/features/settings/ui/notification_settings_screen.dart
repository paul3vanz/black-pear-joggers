import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/notifications/push_service.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/preferences_repository.dart';
import 'push_limit_and_reminders.dart';
import 'settings_providers.dart';

/// Profile > Notification settings (`/profile/notifications`). Online-only: the
/// switches are the server's preferences, so offline we show a friendly message
/// instead of stale toggles. Also shows the OS permission state.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// Latest list from a PUT; takes precedence over the first GET.
  List<NotificationCategoryPref>? _current;
  final _saving = <String>{};

  Future<void> _toggle(
    int clubId,
    List<NotificationCategoryPref> prefs,
    NotificationCategoryPref pref,
    bool value,
  ) async {
    final repo = ref.read(preferencesRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _current = [
        for (final p in prefs)
          p.category == pref.category ? p.copyWith(pushEnabled: value) : p,
      ];
      _saving.add(pref.category);
    });
    try {
      final updated = await repo.update(clubId, {pref.category: value});
      if (mounted) setState(() => _current = updated);
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      setState(() => _current = prefs); // revert
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
      if (mounted) setState(() => _saving.remove(pref.category));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final async = ref.watch(preferencesProvider(clubId));
    final prefs = _current ?? async.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: SafeArea(
        child: ListView(
          children: [
            const _PermissionCard(),
            if (prefs != null)
              for (final pref in prefs)
                _CategoryTile(
                  pref: pref,
                  busy: _saving.contains(pref.category),
                  onChanged: (v) => _toggle(clubId, prefs, pref, v),
                )
            else if (async.hasError)
              _OfflineMessage(
                error: async.error!,
                onRetry: () => ref.invalidate(preferencesProvider(clubId)),
              )
            else
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (prefs != null) PushLimitAndReminders(clubId: clubId),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.pref,
    required this.busy,
    required this.onChanged,
  });

  final NotificationCategoryPref pref;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: ValueKey('pref-${pref.category}'),
      title: Text(pref.label),
      subtitle: Text(
        pref.locked
            ? '${pref.description}\nAlways on: you can\'t turn these off.'
            : pref.description,
      ),
      isThreeLine: pref.locked,
      value: pref.locked || pref.pushEnabled,
      // Null disables the switch (locked categories, or a save in progress).
      onChanged: pref.locked || busy ? null : onChanged,
    );
  }
}

class _OfflineMessage extends StatelessWidget {
  const _OfflineMessage({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final api = ApiException.from(error);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            api.isNetworkError
                ? 'Notification settings need an internet connection. '
                      'Connect and try again.'
                : "Couldn't load your notification settings.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Shows whether the OS lets us show notifications, with the right next step.
class _PermissionCard extends ConsumerWidget {
  const _PermissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(pushPermissionProvider).value;
    final service = ref.read(pushServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    if (permission == null) return const SizedBox.shrink();

    final (icon, text, action) = switch (permission) {
      PushPermission.unavailable => (
        Icons.notifications_off_outlined,
        'Push notifications aren\'t set up in this build. '
            'You\'ll still see everything in your Inbox.',
        null,
      ),
      PushPermission.granted => (
        Icons.notifications_active_outlined,
        'Notifications are allowed on this device.',
        null,
      ),
      PushPermission.notDetermined => (
        Icons.notifications_none,
        'Allow notifications to get club updates as they happen.',
        ('Allow notifications', service.requestPermission),
      ),
      PushPermission.denied => (
        Icons.notifications_off_outlined,
        'Notifications are blocked for this app. Turn them on in system '
            'settings to get pushes.',
        (
          'Open settings',
          () async {
            await service.openSystemSettings();
            return PushPermission.denied;
          },
        ),
      ),
    };

    return Card(
      margin: const EdgeInsets.all(16),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () async {
                    await action.$2();
                    ref.invalidate(pushPermissionProvider);
                  },
                  child: Text(action.$1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
