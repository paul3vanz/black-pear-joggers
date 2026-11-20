import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/safety_repository.dart';

String _failure(Object e, String what) {
  final api = ApiException.from(e);
  return api.isNetworkError
      ? 'You need a connection to $what.'
      : api.statusCode == 429
      ? api.message
      : "Couldn't $what. ${api.message}";
}

/// Asks why, then sends the report to the committee. [targetId] is the message
/// or comment, null when reporting a profile card.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReportKind kind,
  required String reportedMemberId,
  required String name,
  String? targetId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(safetyRepositoryProvider);
  final clubId = ref.read(activeClubIdProvider);
  final result = await showDialog<({ReportReason reason, String details})>(
    context: context,
    builder: (_) => _ReportDialog(
      title: kind == ReportKind.profile
          ? "Report $name's profile"
          : 'Report this message',
    ),
  );
  if (result == null) return;
  try {
    await repo.report(
      clubId,
      kind: kind,
      reportedMemberId: reportedMemberId,
      reason: result.reason,
      targetId: targetId,
      details: result.details,
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Thanks. The committee has been told and will look at it.',
        ),
      ),
    );
  } on Object catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_failure(e, 'send a report'))),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.title});

  final String title;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Why are you reporting it? The committee will see this.'),
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(
              children: [
                for (final r in ReportReason.values)
                  RadioListTile<ReportReason>(
                    key: ValueKey('reason-${r.api}'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(r.label),
                    value: r,
                  ),
              ],
            ),
          ),
          TextField(
            key: const ValueKey('report-details'),
            controller: _details,
            maxLength: 500,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Anything else? (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('report-send'),
        onPressed: _reason == null
            ? null
            : () => Navigator.pop(context, (
                reason: _reason!,
                details: _details.text,
              )),
        child: const Text('Report'),
      ),
    ],
  );
}

/// Confirms, then blocks. Returns true when the member is now blocked.
Future<bool> confirmBlock(
  BuildContext context,
  WidgetRef ref, {
  required String memberId,
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(safetyRepositoryProvider);
  final clubId = ref.read(activeClubIdProvider);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Block $name?'),
      content: const Text(
        "You won't see their messages or profile card any more. They aren't "
        'told. You can unblock them in Profile > About & privacy > Blocked '
        'members.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('block-confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await repo.block(clubId, memberId, name);
    messenger.showSnackBar(SnackBar(content: Text('$name is blocked')));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_failure(e, 'block someone'))),
    );
    return false;
  }
}

/// Unblocks (no confirmation needed). Returns true when it worked.
Future<bool> unblockMember(
  BuildContext context,
  WidgetRef ref, {
  required String memberId,
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(safetyRepositoryProvider)
        .unblock(ref.read(activeClubIdProvider), memberId);
    messenger.showSnackBar(SnackBar(content: Text('$name is unblocked')));
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_failure(e, 'unblock someone'))),
    );
    return false;
  }
}

/// The sheet behind a long-press on someone else's message.
Future<void> showMessageActions(
  BuildContext context,
  WidgetRef ref, {
  required ReportKind kind,
  required String messageId,
  required String memberId,
  required String name,
  VoidCallback? onDelete,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('action-report'),
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report message'),
            subtitle: const Text('Tell the committee'),
            onTap: () => Navigator.pop(ctx, 'report'),
          ),
          ListTile(
            key: const ValueKey('action-block'),
            leading: const Icon(Icons.block),
            title: Text('Block $name'),
            subtitle: const Text("Hide this person's messages and card"),
            onTap: () => Navigator.pop(ctx, 'block'),
          ),
          if (onDelete != null)
            ListTile(
              key: const ValueKey('action-delete'),
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete message'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'report':
      await showReportDialog(
        context,
        ref,
        kind: kind,
        reportedMemberId: memberId,
        name: name,
        targetId: messageId,
      );
    case 'block':
      await confirmBlock(context, ref, memberId: memberId, name: name);
    case 'delete':
      onDelete?.call();
  }
}
