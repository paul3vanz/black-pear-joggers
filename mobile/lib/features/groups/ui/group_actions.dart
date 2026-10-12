import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../runs/logic/run_modes.dart';
import '../../runs/ui/session_actions.dart';
import '../data/group_dtos.dart';
import '../data/groups_repository.dart';
import 'group_format.dart';

/// A group write with the friendly group error messages.
Future<bool> groupWrite(
  BuildContext context,
  WidgetRef ref,
  Future<Object?> Function(GroupsRepository repo) action, {
  String? success,
}) => runWrite(
  context,
  ref,
  () => action(ref.read(groupsRepositoryProvider)),
  success: success,
  errorMessage: groupErrorMessage,
);

/// Asks how the caller will help lead [group], then joins it.
Future<void> joinAsLeaderWithRole(
  BuildContext context,
  WidgetRef ref,
  Session session,
  Group group,
) async {
  // Event groups have no leaders (D79).
  if (isEventLikeMode(session.groupMode)) return;
  final role = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('How will you help lead?'),
      children: [
        for (final (value, label) in const [
          ('leader', 'Leader'),
          ('co_leader', 'Co-leader'),
          ('backmarker', 'Backmarker'),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(value),
            child: Text(label),
          ),
      ],
    ),
  );
  if (role == null || !context.mounted) return;
  await groupWrite(
    context,
    ref,
    (repo) => repo.joinAsLeader(session.id, group.id, role: role),
    success: "You're leading this group",
  );
}

/// Confirms, then withdraws the caller as a leader of [group].
Future<void> stepDownFrom(
  BuildContext context,
  WidgetRef ref,
  Session session,
  Group group,
) async {
  if (isEventLikeMode(session.groupMode)) return;
  final expects = session.groupMode == 'paced' || session.groupMode == 'single';
  final ok = await confirm(
    context,
    title: 'Step down?',
    message: expects
        ? "If you're the last leader, this group will be marked as needing "
              'a leader.'
        : 'You will no longer be listed as a leader of this group.',
    action: 'Step down',
  );
  if (!ok || !context.mounted) return;
  await groupWrite(
    context,
    ref,
    (repo) => repo.withdrawAsLeader(session.id, group.id),
    success: 'You stepped down',
  );
}
