import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../groups/data/group_dtos.dart';
import '../../groups/data/plan_dtos.dart';
import '../../groups/ui/attendance_actions.dart';
import '../../groups/ui/group_access.dart';
import '../../groups/ui/group_format.dart';
import '../../groups/ui/groups_providers.dart';
import '../../messages/ui/messages_providers.dart';
import '../../runs/ui/runs_providers.dart';
import 'event_card.dart';

/// "Who's going?" on a `race` run: one card for the race's single group (the
/// server creates it with the run): the going count, the people you are going
/// with once you are in, I'm going / Can't go, and Chat. No add button and no
/// remove (the server refuses both, `race_group_fixed`).
///
/// If the group is somehow missing from the cached run, the card falls back to
/// a plain going / not going answer with the run-level count.
class RaceSection extends ConsumerWidget {
  const RaceSection({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(sessionGroupsProvider(session.id)).value ?? [];
    final group = groups.isEmpty ? null : groups.first;
    final resp = myResponse(ref, session.id);
    final summary = ref.watch(sessionSummaryProvider(session.id)).value;
    final myId = ref.watch(myMemberIdProvider);
    final isCommittee = ref.watch(canManageRunsProvider);
    final open = isRunOpen(session, ref.watch(nowProvider));
    // Names come from the plan (online-only, cached): the load fetches it.
    ref.watch(planLoadProvider(session.id));
    final plan = ref.watch(sessionPlanProvider(session.id)).value;

    final coming = resp.status == 'going' || resp.status == 'maybe';
    // In the race group (so in its chat) rather than just "going" on the run.
    final mine = group == null ? resp.status == 'going' : _inGroup(resp, group);
    final names = group != null && mine
        ? [
            for (final a
                in plan?.forGroup(group.id)?.attendees ?? <PlanAttendee>[])
              if (a.memberId != myId) a,
          ]
        : <PlanAttendee>[];

    void answer(String status, {String? groupId}) => unawaited(
      respondToRun(
        context,
        ref,
        session: session,
        status: status,
        groupId: groupId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        EventCard(
          title: groupsHeading(session.groupMode),
          going: group?.goingCount ?? summary?.goingCount ?? 0,
          maybe: group?.maybeCount ?? summary?.maybeCount ?? 0,
          isMine: mine,
          fellowAttendees: names,
          statusNote: resp.status == 'not_going' ? "You can't make it." : null,
          onJoin: open && !mine
              ? () => answer('going', groupId: group?.id)
              : null,
          // "Can't go" is the only way out of a race (there is no event to
          // leave), so it shows until you have said so.
          onDecline: open && resp.status != 'not_going'
              ? () => answer('not_going')
              : null,
          onChat:
              group != null &&
                  canChatIn(
                    group: group,
                    session: session,
                    myMemberId: myId,
                    inGroup: mine && coming,
                    isCommittee: isCommittee,
                  )
              ? () => unawaited(
                  context.push('/runs/${session.id}/groups/${group.id}/chat'),
                )
              : null,
          chatUnread:
              group != null &&
              (ref.watch(threadStateProvider(group.id)).value?.unreadCount ??
                      0) >
                  0,
        ),
      ],
    );
  }

  bool _inGroup(MyResponse resp, Group group) =>
      resp.groupId == group.id && resp.status != 'not_going';
}
