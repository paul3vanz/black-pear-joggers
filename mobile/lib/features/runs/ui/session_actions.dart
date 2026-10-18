import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../data/runs_repository.dart';
import 'runs_providers.dart';

/// Runs a committee write: reports failures in a SnackBar with a friendly
/// message (403, offline, 409) and returns whether it succeeded. A session
/// expiry is handed to the shared handler (which signs the user out).
Future<bool> runWrite(
  BuildContext context,
  WidgetRef ref,
  Future<Object?> Function() action, {
  String? success,
  String Function(Object error)? errorMessage,
  SnackBarAction? Function(Object error)? errorAction,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final sub = ref.read(activeSubProvider);
  final handleExpiry = ref.read(sessionExpiryHandlerProvider);
  try {
    await action();
  } on Object catch (e) {
    if (sub != null && await handleExpiry(sub, e)) return false;
    messenger.showSnackBar(
      SnackBar(
        content: Text((errorMessage ?? runsErrorMessage)(e)),
        action: errorAction?.call(e),
      ),
    );
    return false;
  }
  if (success != null) {
    messenger.showSnackBar(SnackBar(content: Text(success)));
  }
  return true;
}

/// Asks for a yes/no confirmation; true only on an explicit yes.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Committee-only buttons on the session detail screen: edit this run, cancel
/// (with a reason) or restore it, and delete it if it is an ad-hoc run.
class SessionActions extends ConsumerWidget {
  const SessionActions({
    super.key,
    required this.session,
    required this.clubId,
  });

  final Session session;
  final int clubId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await _askReason(context);
    if (reason == null || !context.mounted) return;
    await runWrite(
      context,
      ref,
      () => ref
          .read(runsRepositoryProvider)
          .cancelSession(clubId, session.id, reason),
      success: 'Run cancelled',
    );
  }

  Future<String?> _askReason(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cancel this run'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason (shown to members)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Cancel run'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) => runWrite(
    context,
    ref,
    () => ref.read(runsRepositoryProvider).restoreSession(clubId, session.id),
    success: 'Run restored',
  );

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final ok = await confirm(
      context,
      title: 'Delete this run?',
      message: 'It will be removed for everyone.',
      action: 'Delete',
    );
    if (!ok || !context.mounted) return;
    final done = await runWrite(
      context,
      ref,
      () => ref
          .read(runsRepositoryProvider)
          .deleteAdHocSession(clubId, session.id),
      success: 'Run deleted',
    );
    if (done) router.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancelled = session.status == 'cancelled';
    final adHoc = session.seriesId == null;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Committee', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () =>
                unawaited(context.push('/runs/${session.id}/edit')),
            icon: const Icon(Icons.edit),
            label: const Text('Edit this run'),
          ),
          const SizedBox(height: 8),
          if (cancelled)
            OutlinedButton.icon(
              onPressed: () => unawaited(_restore(context, ref)),
              icon: const Icon(Icons.restore),
              label: const Text('Restore run'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => unawaited(_cancel(context, ref)),
              icon: const Icon(Icons.event_busy),
              label: const Text('Cancel run'),
            ),
          if (adHoc) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => unawaited(_delete(context, ref)),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete run'),
            ),
          ],
        ],
      ),
    );
  }
}
