import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../data/group_dtos.dart';
import '../data/small_kv_store.dart';
import 'attendance_actions.dart';
import 'group_access.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// Shown instead of the sheet when a run has no pace groups yet (D50).
const noGroupsYetNote =
    "Pace groups are confirmed at the start. We'll let you know if one is "
    'added that suits you.';

/// After the viewer answers "I'm coming" on the run page (D50, app half):
///
/// - no active groups: a short SnackBar (nothing to pick);
/// - the viewer already leads a group or is in one: nothing;
/// - otherwise a bottom sheet "Pick your pace group?" listing the groups,
///   once per run per device (remembered in the small key/value table).
///
/// Not used for the notification buttons and never after "Can't come".
Future<void> maybePromptPickGroup(
  BuildContext context,
  WidgetRef ref,
  Session session,
) async {
  if (session.groupMode == 'routes') return; // routes are not pace groups
  if (!isRunOpen(session, ref.read(groupsClockProvider)())) return;
  final groups = [
    for (final g in await ref.read(sessionGroupsProvider(session.id).future))
      if (g.status == 'active') g,
  ];
  if (!context.mounted) return;
  final myId = ref.read(myMemberIdProvider);
  final summary = ref.read(sessionSummaryProvider(session.id)).value;
  final row = ref.read(myAttendanceProvider(session.id)).value;
  final leading =
      (summary?.myLeading ?? false) ||
      (myId != null && groups.any((g) => g.isLedBy(myId)));
  final inGroup = (row?.groupId ?? summary?.myGroupId) != null;
  if (leading || inGroup) return;
  if (groups.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(noGroupsYetNote)));
    return;
  }
  final store = ref.read(smallKvStoreProvider);
  final key = SmallKvStore.pickGroupKey(session.clubId, session.id);
  if (await store.get(key) != null || !context.mounted) return;
  // Remember before showing: dismissing the sheet counts as "asked".
  await store.set(key, '1');
  if (!context.mounted) return;
  final groupId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        PickGroupSheet(groups: groups, units: ref.read(unitPrefsProvider)),
  );
  if (groupId == null || !context.mounted) return;
  await respondToRun(
    context,
    ref,
    session: session,
    status: 'going',
    groupId: groupId,
  );
}

/// The sheet body. Pops with the chosen group's id, or null for "I'll decide
/// on the day".
class PickGroupSheet extends StatelessWidget {
  const PickGroupSheet({super.key, required this.groups, required this.units});

  final List<Group> groups;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pick your pace group?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('You can change this any time on the run page.', style: muted),
            const SizedBox(height: 8),
            for (final g in groups) _GroupRow(group: g, units: units),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text("I'll decide on the day"),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.units});

  final Group group;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final heading = groupHeading(group, units);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (heading.subtitle != null)
                    Text(heading.subtitle!, style: muted),
                  if (group.leaders.isNotEmpty)
                    Text('Led by ${leadersText(group.leaders)}', style: muted),
                  Text(
                    goingText(group.goingCount, group.maybeCount),
                    style: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(group.id),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
