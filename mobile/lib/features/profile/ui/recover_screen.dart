import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/recovery.dart';
import '../../../core/diagnostics/diagnostics_report.dart';
import 'diagnostics_screen.dart';

/// `/recover` (D101): shown when the saved data can't be opened even after the
/// automatic repair. Outside the app shell and with no database access, so it
/// works when nothing else does.
class RecoverScreen extends ConsumerStatefulWidget {
  const RecoverScreen({super.key});

  @override
  ConsumerState<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends ConsumerState<RecoverScreen> {
  bool _busy = false;

  Future<void> _reset() async {
    final recovery = ref.read(recoveryProvider);
    setState(() => _busy = true);
    try {
      // Deletes the files without opening them. Re-runs the check, and the
      // router leaves this screen when it passes.
      await recovery.resetLocalData(clearRows: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final text = await ref.read(reportTextProvider)(touchDatabase: false);
    if (!mounted) return;
    await copyReportToClipboard(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "The app couldn't load its saved data",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Resetting clears what the app saved on this phone and '
                    'downloads it again. You stay signed in.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('reset-and-retry'),
                    onPressed: _busy ? null : _reset,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reset and try again'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('copy-diagnostics'),
                    onPressed: _copy,
                    child: const Text('Copy diagnostics'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
