import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/diagnostics/diagnostics.dart';
import '../../../core/diagnostics/diagnostics_report.dart';
import '../../../core/diagnostics/recovery.dart';

/// Copies [text] and says where to send it. `Clipboard.setData` is
/// `navigator.clipboard.writeText`.
Future<void> copyReportToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copied. Paste it into an email to webmaster@bpj.org.uk'),
    ),
  );
}

/// A Cancel / action dialog. Returns true only if the action button was tapped.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// The "Reset local data?" confirmation, shared by every place that offers it.
Future<bool> confirmResetLocalData(BuildContext context) => confirmAction(
  context,
  title: 'Reset local data?',
  body:
      'This clears everything the app has saved on this phone and '
      'downloads it again. You stay signed in. Anything you changed while '
      'offline and has not been sent yet will be lost.',
  action: 'Reset',
);

/// Profile > About & privacy > Diagnostics (`/profile/about/diagnostics`, D100).
///
/// Shows the report (versions, sign-in state, recent errors and request
/// outcomes) so a member can copy it into an email, and the two self-service
/// repairs for "every screen fails" (D101).
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  bool _busy = false;

  Future<void> _resetLocal() async {
    final router = GoRouter.of(context);
    if (!await confirmResetLocalData(context)) return;
    // Everything needed is read first: the router may replace this screen.
    final recovery = ref.read(recoveryProvider);
    setState(() => _busy = true);
    try {
      await recovery.resetLocalData();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    router.go('/');
  }

  Future<void> _fullReset() async {
    if (!await confirmAction(
      context,
      title: 'Sign out and clear everything?',
      body:
          'This signs you out and removes all saved data from this phone. '
          'Your membership and account are not touched. Anything not sent '
          'yet will be lost.',
      action: 'Sign out and clear',
    )) {
      return;
    }
    final recovery = ref.read(recoveryProvider);
    setState(() => _busy = true);
    try {
      // The router sends the user to the sign-in screen when this finishes.
      await recovery.fullReset();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final report = ref.watch(diagnosticsReportProvider);

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Diagnostics')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'If something is not working, copy this report and email it '
                'to webmaster@bpj.org.uk. It lists recent errors and request '
                'outcomes only. No personal data is included.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('diagnostics-report'),
                constraints: const BoxConstraints(maxHeight: 320),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: report.when(
                      data: (text) => SelectableText(
                        text,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Could not build the report: $e'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('copy-report'),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy report'),
                    onPressed: report.hasValue
                        ? () => copyReportToClipboard(context, report.value!)
                        : null,
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('clear-log'),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear log'),
                    onPressed: () {
                      ref.read(diagnosticsProvider).clear();
                      ref.invalidate(diagnosticsReportProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Fix problems',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('reset-local'),
                enabled: !_busy,
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset local data'),
                subtitle: const Text(
                  'Clear what the app saved on this phone and download it '
                  'again. You stay signed in.',
                ),
                onTap: _resetLocal,
              ),
              ListTile(
                key: const ValueKey('full-reset'),
                enabled: !_busy,
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text(
                  'Sign out and clear everything on this phone',
                  style: TextStyle(color: scheme.error),
                ),
                subtitle: const Text(
                  'Use this if resetting local data did not help.',
                ),
                onTap: _fullReset,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
