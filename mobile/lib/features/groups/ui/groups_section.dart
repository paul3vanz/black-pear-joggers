import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../messages/ui/messages_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../../runs/ui/session_actions.dart';
import '../data/group_dtos.dart';
import '../data/groups_repository.dart';
import 'attendance_actions.dart';
import 'group_access.dart';
import 'group_actions.dart';
import 'group_card.dart';
import 'group_format.dart';
import 'group_plan_block.dart';
import 'groups_providers.dart';
import 'respond_card.dart';

/// The "Groups" section of the session detail screen: a card per group
/// (fastest first), the caller's choices and the buttons to offer to lead one.
/// For a cancelled or finished run it is read-only.
class GroupsSection extends ConsumerWidget {
  const GroupsSection({super.key, required this.session});

  final Session session;

  String get _base => '/runs/${session.id}/groups';

  Future<void> _write(
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

  Future<void> _delete(BuildContext context, WidgetRef ref, Group g) async {
    final ok = await confirm(
      context,
      title: 'Delete this group?',
      message: "People who chose it will be moved to 'no group yet'.",
      action: 'Delete',
    );
    if (!ok || !context.mounted) return;
    await _write(
      context,
      ref,
      (repo) => repo.deleteGroup(session.id, g.id),
      success: 'Group deleted',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(sessionGroupsProvider(session.id)).value ?? [];
    final units = ref.watch(unitPrefsProvider);
    final resp = myResponse(ref, session.id);
    final myId = ref.watch(myMemberIdProvider);
    final isCommittee = ref.watch(canManageRunsProvider);
    final open = isRunOpen(session, ref.watch(nowProvider));
    final routes = session.groupMode == 'routes';
    final buttons = _Buttons(
      base: _base,
      showAddRoute: open && ref.watch(canAddRoutesProvider(session)),
      showLead: open && !(session.groupMode == 'single' && groups.isNotEmpty),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          groupsHeading(session.groupMode),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(groupsIntro(session.groupMode), style: theme.textTheme.bodyMedium),
        if (open && showsPaceGroupsNote(session.groupMode)) ...[
          const SizedBox(height: 4),
          Text(
            paceGroupsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (routes && open) MyPaceTile(session: session),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No groups yet. Leaders can offer to lead one.'),
                  buttons,
                ],
              ),
            ),
          )
        else ...[
          for (final g in groups)
            _card(context, ref, g, units, resp, myId, isCommittee, open),
          buttons,
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    Group g,
    UnitPrefs units,
    MyResponse resp,
    String? myId,
    bool isCommittee,
    bool open,
  ) {
    final mine = resp.groupId == g.id && resp.status != 'not_going';
    final leading = myId != null && g.isLedBy(myId);
    final canEdit =
        open &&
        canEditGroup(
          group: g,
          session: session,
          myMemberId: myId,
          isCommittee: isCommittee,
        );
    return GroupCard(
      key: ValueKey(g.id),
      group: g,
      units: units,
      isMine: mine,
      isLeading: leading,
      joinLabel: session.groupMode == 'routes' || g.kind == 'route'
          ? "I'm doing this route"
          : 'Join this group',
      // Leaders are already in the group they lead (the server marks them
      // going), so they get no Join / Leave.
      onJoin: open && !mine && !leading
          ? () => unawaited(
              respondToRun(
                context,
                ref,
                session: session,
                status: 'going',
                groupId: g.id,
              ),
            )
          : null,
      onLeave: open && mine && !leading
          ? () => unawaited(
              respondToRun(context, ref, session: session, status: 'going'),
            )
          : null,
      onLeadToo: open && !leading
          ? () => unawaited(joinAsLeaderWithRole(context, ref, session, g))
          : null,
      onStepDown: open && leading
          ? () => unawaited(stepDownFrom(context, ref, session, g))
          : null,
      onEdit: canEdit
          ? () => unawaited(context.push('$_base/${g.id}/edit'))
          : null,
      onDelete: canEdit ? () => unawaited(_delete(context, ref, g)) : null,
      onChat:
          canChatIn(
            group: g,
            session: session,
            myMemberId: myId,
            inGroup: mine,
            isCommittee: isCommittee,
          )
          ? () => unawaited(context.push('$_base/${g.id}/chat'))
          : null,
      chatUnread:
          (ref.watch(threadStateProvider(g.id)).value?.unreadCount ?? 0) > 0,
      footer: session.groupMode == 'routes'
          ? GroupPlanBlock(
              sessionId: session.id,
              groupId: g.id,
              going: g.goingCount,
              maybe: g.maybeCount,
              withCounts: false,
            )
          : null,
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({
    required this.base,
    required this.showAddRoute,
    required this.showLead,
  });

  final String base;
  final bool showAddRoute;
  final bool showLead;

  @override
  Widget build(BuildContext context) {
    if (!showAddRoute && !showLead) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (showAddRoute)
            FilledButton.icon(
              onPressed: () => unawaited(
                context.push('$base/new?kind=route&intent=add&lead=false'),
              ),
              icon: const Icon(Icons.add_road),
              label: const Text('Add route'),
            ),
          if (showLead)
            OutlinedButton.icon(
              onPressed: () => unawaited(context.push('$base/new?intent=lead')),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Lead a group'),
            ),
        ],
      ),
    );
  }
}
