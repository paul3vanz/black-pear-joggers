import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/data/runs_repository.dart';
import '../../runs/logic/run_modes.dart';
import '../../runs/ui/session_actions.dart';
import '../data/group_dtos.dart';
import '../data/groups_repository.dart';
import 'group_access.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// A group write with the friendly group error messages.
///
/// With [sessionId], a 409 `already_leading` also gets an **Open it** action
/// (see [groupErrorAction]).
Future<bool> groupWrite(
  BuildContext context,
  WidgetRef ref,
  Future<Object?> Function(GroupsRepository repo) action, {
  String? success,
  String? sessionId,
}) {
  // Only looked up when an action is wanted (some callers have no router).
  final router = sessionId == null ? null : GoRouter.maybeOf(context);
  return runWrite(
    context,
    ref,
    () => action(ref.read(groupsRepositoryProvider)),
    success: success,
    errorMessage: groupErrorMessage,
    errorAction: router == null || sessionId == null
        ? null
        : (e) => groupErrorAction(router, sessionId, e),
  );
}

/// The snackbar action for a failed group write: **Open it** for a server 409
/// `already_leading`, which names the group the member leads (`groupId`).
SnackBarAction? groupErrorAction(
  GoRouter router,
  String sessionId,
  Object error,
) {
  final api = ApiException.from(error);
  final id = api.body['groupId'];
  if (api.code != 'already_leading' || id is! String) return null;
  return SnackBarAction(
    label: 'Open it',
    onPressed: () => unawaited(router.push('/runs/$sessionId/groups/$id/edit')),
  );
}

/// "You're already leading a group on this run" with an **Open it** action
/// that opens [groupId]'s editor (a leader may edit their own group). Used when
/// the app blocks a second led group (D108) and for a server 409
/// `already_leading` (whose body names the group). [groupId] may be null when
/// the server did not say which; then there is no action.
void showAlreadyLeading(
  BuildContext context,
  Session session,
  String? groupId,
) {
  final router = GoRouter.maybeOf(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(alreadyLeadingMessage),
      action: groupId == null || router == null
          ? null
          : SnackBarAction(
              label: 'Open it',
              onPressed: () => unawaited(
                router.push('/runs/${session.id}/groups/$groupId/edit'),
              ),
            ),
    ),
  );
}

/// What the "How will you help lead?" dialog hands back.
typedef _JoinResult = ({bool joined, String? alreadyLeadingGroupId});

/// Asks how the caller will help lead [group], then joins it.
Future<void> joinAsLeaderWithRole(
  BuildContext context,
  WidgetRef ref,
  Session session,
  Group group,
) async {
  // Event groups have no leaders (D79).
  if (isEventLikeMode(session.groupMode)) return;
  // One group per leader per run (D108): never offer a second one.
  final groups = ref.read(sessionGroupsProvider(session.id)).value ?? const [];
  final mine = groupLedBy(groups, ref.read(myMemberIdProvider));
  if (mine != null && mine.id != group.id) {
    showAlreadyLeading(context, session, mine.id);
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<_JoinResult>(
    context: context,
    builder: (_) => _RoleDialog(session: session, group: group),
  );
  if (result == null) return;
  if (result.joined) {
    messenger.showSnackBar(
      const SnackBar(content: Text("You're leading this group")),
    );
  } else if (context.mounted) {
    showAlreadyLeading(context, session, result.alreadyLeadingGroupId);
  }
}

/// "How will you help lead?". The join happens inside the dialog so a server
/// refusal can be shown right here: a 409 `leader_exists` (someone became the
/// group's leader meanwhile) says so, refreshes the run and drops the "Leader"
/// option, leaving co-leader and backmarker.
class _RoleDialog extends ConsumerStatefulWidget {
  const _RoleDialog({required this.session, required this.group});

  final Session session;
  final Group group;

  @override
  ConsumerState<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends ConsumerState<_RoleDialog> {
  bool _busy = false;
  bool _leaderTaken = false;
  String? _error;

  Future<void> _join(String role) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(groupsRepositoryProvider)
          .joinAsLeader(widget.session.id, widget.group.id, role: role);
      if (mounted) navigator.pop((joined: true, alreadyLeadingGroupId: null));
    } on Object catch (e) {
      final sub = ref.read(activeSubProvider);
      if (sub != null && await ref.read(sessionExpiryHandlerProvider)(sub, e)) {
        if (mounted) navigator.pop();
        return;
      }
      if (!mounted) return;
      final api = ApiException.from(e);
      if (api.code == 'already_leading') {
        final id = api.body['groupId'];
        navigator.pop((
          joined: false,
          alreadyLeadingGroupId: id is String ? id : null,
        ));
        return;
      }
      if (api.code == 'leader_exists') {
        setState(() {
          _busy = false;
          _leaderTaken = true;
          _error = api.body['message'] is String
              ? api.body['message']! as String
              : 'This group already has a leader. Join as co-leader or '
                    'backmarker.';
        });
        // Bring the cached group up to date; a failure is fine, the local
        // flag above already hides "Leader".
        unawaited(
          ref
              .read(runsRepositoryProvider)
              .refreshSessions(ref.read(activeClubIdProvider))
              .then<void>((_) {}, onError: (Object _) {}),
        );
        return;
      }
      setState(() {
        _busy = false;
        _error = groupErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the cached group so a refresh that brings in a leader updates the
    // options (in React terms: the dialog subscribes to the query).
    final live = ref
        .watch(sessionGroupsProvider(widget.session.id))
        .value
        ?.where((g) => g.id == widget.group.id)
        .firstOrNull;
    final options = roleOptionsFor(
      live ?? widget.group,
      leaderTaken: _leaderTaken,
    );
    return SimpleDialog(
      title: const Text('How will you help lead?'),
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (final (value, label) in options)
          SimpleDialogOption(
            onPressed: _busy ? null : () => unawaited(_join(value)),
            child: Text(label),
          ),
      ],
    );
  }
}

/// Confirms, then steps the caller down as a leader of [group] (D109). The
/// dialog says they are removed from the group (or that an unused group they
/// made will be deleted) and offers "I can't make this run at all".
Future<void> stepDownFrom(
  BuildContext context,
  WidgetRef ref,
  Session session,
  Group group,
) async {
  if (isEventLikeMode(session.groupMode)) return;
  final deletes = stepDownDeletesGroup(group, ref.read(myMemberIdProvider));
  final messenger = ScaffoldMessenger.of(context);
  final notGoing = await showDialog<bool>(
    context: context,
    builder: (_) => _StepDownDialog(deletesGroup: deletes),
  );
  if (notGoing == null || !context.mounted) return;
  Group? result;
  final ok = await groupWrite(context, ref, (repo) async {
    result = await repo.withdrawAsLeader(
      session.id,
      group.id,
      notGoing: notGoing,
    );
    return result;
  });
  if (!ok) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result?.isDeleted ?? false ? 'Group deleted' : 'You stepped down',
      ),
    ),
  );
}

/// Pops `true` when the member ticked "I can't make this run at all", `false`
/// when not, and null when they keep leading.
class _StepDownDialog extends StatefulWidget {
  const _StepDownDialog({required this.deletesGroup});

  final bool deletesGroup;

  @override
  State<_StepDownDialog> createState() => _StepDownDialogState();
}

class _StepDownDialogState extends State<_StepDownDialog> {
  bool _notGoing = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Step down?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("You'll be removed from this group."),
        if (widget.deletesGroup) ...[
          const SizedBox(height: 8),
          const Text('Nobody else has joined, so this group will be deleted.'),
        ],
        CheckboxListTile(
          key: const ValueKey('stepDownNotGoing'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text("I can't make this run at all"),
          value: _notGoing,
          onChanged: (v) => setState(() => _notGoing = v ?? false),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Keep'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_notGoing),
        child: const Text('Step down'),
      ),
    ],
  );
}
