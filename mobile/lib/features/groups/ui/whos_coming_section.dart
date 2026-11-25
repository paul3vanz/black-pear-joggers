import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/relative_time.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import '../../runs/logic/run_modes.dart';
import '../logic/pace_spread.dart';
import 'coverage_card.dart';
import 'group_access.dart';
import 'group_format.dart';
import 'group_plan_block.dart';
import 'groups_providers.dart';
import 'attendance_actions.dart';

/// "Who's coming" on the session detail. Each group card shows its own people
/// (D140), so this lists the ones with no group yet, and the committee's group
/// coverage view. A run with no groups (`everyone`) shows its one shared list
/// here, with the group chat. Driven by the cached plan; the fetch never blocks
/// the screen.
class WhosComingSection extends ConsumerWidget {
  const WhosComingSection({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(sessionPlanProvider(session.id)).value;
    final load = ref.watch(planLoadProvider(session.id));
    final groups = ref.watch(sessionGroupsProvider(session.id)).value ?? [];
    final units = ref.watch(unitPrefsProvider);
    final isManager = canCreateLeaderless(
      session: session,
      myMemberId: ref.watch(myMemberIdProvider),
      isCommittee: ref.watch(canManageRunsProvider),
    );
    // Routes, events and races have no pace spread or coverage (D79).
    final routes = !usesPaceGroups(session.groupMode);
    final everyone = isEveryoneMode(session.groupMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          "Who's coming",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _Status(sessionId: session.id, hasPlan: plan != null, load: load),
        if (everyone)
          _EveryoneCard(session: session, group: groups.firstOrNull),
        if (plan != null) _Unassigned(plan: plan, units: units),
        // Leader coverage works from the groups alone, so it shows before the
        // plan loads; the people part appears once names are available.
        if (isManager && !routes)
          CoverageCard(
            session: session,
            plan: plan,
            groups: groups,
            units: units,
          ),
      ],
    );
  }
}

class _Status extends ConsumerWidget {
  const _Status({
    required this.sessionId,
    required this.hasPlan,
    required this.load,
  });

  final String sessionId;
  final bool hasPlan;
  final AsyncValue<PlanLoad> load;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(nowProvider);
    final value = load.value;
    final at = value?.fetchedAt;
    final offline = value?.offline ?? false;
    final children = <Widget>[
      if (offline)
        OfflineBanner(
          hasPlan
              ? "You're offline. This is the last plan we saved"
                    '${at == null ? '' : ', updated ${relativeTime(at, now: now)}'}.'
              : "You're offline, so who's coming isn't available yet.",
        )
      else if (load.hasError && !load.isLoading)
        Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't load who's coming.",
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(planLoadProvider(sessionId)),
              child: const Text('Retry'),
            ),
          ],
        )
      else if (load.isLoading && !hasPlan)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(),
        )
      else if (hasPlan && at != null)
        Text(
          'Updated ${relativeTime(at, now: now)}',
          style: theme.textTheme.bodySmall,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// The one shared group of a run with no pace groups: who is coming with their
/// pace, and the group chat.
class _EveryoneCard extends ConsumerWidget {
  const _EveryoneCard({required this.session, required this.group});

  final Session session;
  final Group? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final g = group;
    final myId = ref.watch(myMemberIdProvider);
    final resp = myResponse(ref, session.id);
    final canChat =
        g != null &&
        canChatIn(
          group: g,
          session: session,
          myMemberId: myId,
          inGroup: resp.groupId == g.id && resp.status != 'not_going',
          isCommittee: ref.watch(canManageRunsProvider),
        );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (g == null || g.goingCount + g.maybeCount == 0)
              Text(
                "Nobody has said they're coming yet.",
                style: theme.textTheme.bodyMedium,
              )
            else
              GroupPlanBlock(
                sessionId: session.id,
                groupId: g.id,
                going: g.goingCount,
                maybe: g.maybeCount,
              ),
            if (canChat)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('everyone-chat'),
                  onPressed: () => unawaited(
                    context.push('/runs/${session.id}/groups/${g.id}/chat'),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Group chat'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Unassigned extends StatelessWidget {
  const _Unassigned({required this.plan, required this.units});

  final SessionPlan plan;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    final u = plan.unassigned;
    if (u.goingCount + u.maybeCount == 0) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming, no group yet',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            PlanBlock(
              spread: buildPaceSpread(u.paces, units.paceUnit),
              going: u.goingCount,
              maybe: u.maybeCount,
              names: u.members,
              namesTitle: 'Waiting for a group',
              initiallyExpanded: true,
              units: units,
            ),
            if (u.paces.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(goingText(u.goingCount, u.maybeCount)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Re-fetches the plan (pull-to-refresh) and waits for it, never throwing:
/// the section shows its own error row.
Future<void> refreshPlanFor(WidgetRef ref, String sessionId) async {
  ref.invalidate(planLoadProvider(sessionId));
  try {
    await ref.read(planLoadProvider(sessionId).future);
  } on Object {
    // The section shows the error row; a refresh never throws.
  }
}
