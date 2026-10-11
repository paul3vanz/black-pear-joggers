import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../../core/util/relative_time.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import '../logic/pace_spread.dart';
import 'coverage_card.dart';
import 'group_access.dart';
import 'group_format.dart';
import 'group_plan_block.dart';
import 'groups_providers.dart';

/// "Who's coming" on the session detail: per group the anonymous pace spread
/// (everyone) and names (leaders of that group, coordinator, committee), the
/// "no group yet" bucket, and the committee's group coverage view. Driven by the cached
/// plan; the fetch never blocks the screen.
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
    final routes = session.groupMode == 'routes';
    final shown = [
      if (!routes)
        for (final g in groups)
          if (g.goingCount + g.maybeCount > 0 && plan?.forGroup(g.id) != null)
            g,
    ];
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
        if (plan != null) ...[
          for (final g in shown) _GroupSpread(group: g, session: session),
          _Unassigned(plan: plan, units: units),
        ],
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
    final now = ref.watch(groupsClockProvider)();
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

class _GroupSpread extends ConsumerWidget {
  const _GroupSpread({required this.group, required this.session});

  final Group group;
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitPrefsProvider);
    final title = [
      ?group.label,
      paceText(group.pace, units),
    ].where((p) => p.isNotEmpty).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? groupKindLabel(group.kind) : title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            GroupPlanBlock(
              sessionId: session.id,
              groupId: group.id,
              going: group.goingCount,
              maybe: group.maybeCount,
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
              namesTitle: 'Who is waiting for a group',
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
