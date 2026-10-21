import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../membership/ui/membership_providers.dart';
import '../../messages/data/messages_repository.dart';

/// What the sheet is asking about: a pace range in seconds per km, or none for
/// "anyone who could lead this run", and how to say it ("8:25-10:05/mi").
typedef AskTarget = ({int? fastSPerKm, int? slowSPerKm, String? paceLabel});

/// The committee's "can anyone lead?" sheet (D125). **Send** posts an ask in the
/// run's leaders thread and notifies the members who could lead that pace, then
/// opens the thread. Needs a connection.
Future<void> showAskLeadersSheet(
  BuildContext context,
  WidgetRef ref, {
  required Session session,
  required AskTarget target,
}) async {
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final notified = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AskSheet(session: session, target: target),
  );
  if (notified == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        notified == 0
            ? 'Nobody else could be asked for that. It is in the leaders '
                  'thread for the committee.'
            : notified == 1
            ? 'Asked 1 leader'
            : 'Asked $notified leaders',
      ),
    ),
  );
  unawaited(router.push('/runs/${session.id}/leaders-chat'));
}

class _AskSheet extends ConsumerStatefulWidget {
  const _AskSheet({required this.session, required this.target});

  final Session session;
  final AskTarget target;

  @override
  ConsumerState<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends ConsumerState<_AskSheet> {
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    try {
      final notified = await ref
          .read(messagesRepositoryProvider)
          .askForLeader(
            ref.read(activeClubIdProvider),
            widget.session.id,
            fastSPerKm: widget.target.fastSPerKm,
            slowSPerKm: widget.target.slowSPerKm,
            note: _note.text,
          );
      if (mounted) navigator.pop(notified);
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) {
        if (mounted) navigator.pop();
        return;
      }
      final api = ApiException.from(e);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = api.isNetworkError
            ? 'You need a connection to ask leaders.'
            : api.statusCode == 403
            ? 'Only the committee can ask for leaders.'
            : api.code == 'thread_closed'
            ? api.message
            : "Couldn't send that. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pace = widget.target.paceLabel;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask leaders',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pace == null
                  ? 'Ask anyone who could lead ${widget.session.title}.'
                  : 'Ask the leaders who could lead $pace on '
                        '${widget.session.title}.',
            ),
            const SizedBox(height: 4),
            Text(
              'They get a notification and answer in the leaders thread, '
              "which you're all in. If nobody has stepped up after a day "
              "they're nudged once more.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('ask-note'),
              controller: _note,
              maxLength: 200,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('ask-send'),
                  onPressed: _busy ? null : () => unawaited(_send()),
                  child: const Text('Send to leaders'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
