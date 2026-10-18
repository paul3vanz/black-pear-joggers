import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../diagnostics/diagnostics.dart';
import '../diagnostics/health.dart';

/// Wraps the app shell and shows "Something's not working. Tap to fix" above it
/// while the health tracker says everything is failing (D102). Never blocking:
/// the app underneath keeps working, and the close button hides it.
///
/// The child stays at the same spot in the widget tree whether or not the banner
/// shows, so the tabs keep their state (like keeping a component's position in a
/// list stable so React doesn't remount it).
class HealthBannerScope extends ConsumerWidget {
  const HealthBannerScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);
    return ValueListenableBuilder<HealthState>(
      valueListenable: health,
      builder: (context, state, _) => Column(
        children: [
          if (state.unhealthy)
            _Banner(
              onTap: () => context.push('/profile/about/diagnostics'),
              onClose: () => ref.read(diagnosticsProvider).health.reset(),
            ),
          Expanded(
            // The banner already sits under the status bar, so the screens
            // below it must not leave room for it a second time.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: state.unhealthy,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onTap, required this.onClose});

  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('health-banner'),
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Something's not working. Tap to fix",
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
