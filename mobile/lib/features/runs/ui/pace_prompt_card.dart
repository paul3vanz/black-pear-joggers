import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../groups/data/small_kv_store.dart';
import '../../groups/ui/groups_providers.dart';
import '../../membership/ui/membership_providers.dart';

/// How long "Not now" hides [PacePromptCard] before it asks again.
const pacePromptSnooze = Duration(days: 7);

/// A nudge at the top of the Runs tab for a member with no usual pace: leaders
/// and the committee plan groups from members' paces, and the app matches you
/// to a group with it (D120). **Set pace** opens the Profile tab where the pace
/// is edited; **Not now** hides the card for a week, then it comes back.
///
/// Renders nothing until the preferences and the snooze flag have loaded, so it
/// never flashes up for someone who has already set a pace.
class PacePromptCard extends ConsumerStatefulWidget {
  const PacePromptCard({super.key});

  @override
  ConsumerState<PacePromptCard> createState() => _PacePromptCardState();
}

class _PacePromptCardState extends ConsumerState<PacePromptCard> {
  /// Null until the snooze flag has been read.
  bool? _snoozed;

  late final SmallKvStore _store = ref.read(smallKvStoreProvider);
  late final String _key = SmallKvStore.pacePromptSnoozeKey(
    ref.read(activeClubIdProvider),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    bool snoozed;
    try {
      final until = DateTime.tryParse(await _store.get(_key) ?? '');
      snoozed = until != null && DateTime.now().isBefore(until);
    } on Object {
      snoozed = false;
    }
    if (mounted) setState(() => _snoozed = snoozed);
  }

  Future<void> _snooze() async {
    setState(() => _snoozed = true);
    try {
      await _store.set(
        _key,
        DateTime.now().add(pacePromptSnooze).toIso8601String(),
      );
    } on Object {
      // Only a convenience: it just shows again next time.
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref
        .watch(runPreferencesProvider(ref.watch(activeClubIdProvider)))
        .value;
    // No updatedAt means nothing is cached yet (the defaults), so a saved pace
    // may simply not have arrived.
    if (prefs == null ||
        prefs.updatedAt == null ||
        !prefs.usualPace.isNone ||
        _snoozed != false) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      key: const ValueKey('pacePrompt'),
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.speed, color: scheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set your usual pace',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'It helps leaders plan the right groups and gets you '
                        'matched to one that suits you. You can change it for '
                        'any run.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                children: [
                  TextButton(
                    key: const ValueKey('pacePromptLater'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: scheme.onSecondaryContainer,
                    ),
                    onPressed: () => unawaited(_snooze()),
                    child: const Text('Not now'),
                  ),
                  FilledButton(
                    key: const ValueKey('pacePromptSet'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    // The pace boxes are on the Profile tab (D88).
                    onPressed: () => context.go('/profile'),
                    child: const Text('Set pace'),
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
