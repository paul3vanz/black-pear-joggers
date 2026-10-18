import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/diagnostics/recovery.dart';
import '../../profile/ui/diagnostics_screen.dart';
import 'membership_providers.dart';

/// Shown when the very first `/app/me` call failed and nothing is cached yet, so we
/// can't tell whether the user needs to link. Once there's a cache the app works
/// offline and never shows this.
class UnavailableScreen extends ConsumerWidget {
  const UnavailableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: account == null
                ? null
                : () => ref
                      .read(accountsControllerProvider.notifier)
                      .remove(account.sub),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              Text(
                "Couldn't load your membership",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
                onPressed: () => ref.read(meSyncProvider.notifier).retry(),
                child: const Text('Try again'),
              ),
              // Online and still stuck? The saved data may be the problem (D101).
              TextButton(
                key: const ValueKey('unavailable-reset'),
                onPressed: () async {
                  final recovery = ref.read(recoveryProvider);
                  if (await confirmResetLocalData(context)) {
                    await recovery.resetLocalData();
                  }
                },
                child: const Text('Still stuck? Reset local data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
