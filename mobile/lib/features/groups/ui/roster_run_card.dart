import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../runs/ui/run_format.dart';
import '../../runs/data/session_changes.dart';
import '../data/group_dtos.dart';
import '../data/last_group_store.dart';
import '../data/groups_repository.dart';
import '../../../core/util/clock_time.dart';
import 'attendance_actions.dart';
import 'group_access.dart';
import 'group_actions.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// One run in the leader roster: when and where, the groups already offered
/// with their leaders, and the ways to lead: "Offer to lead", "Same as last
/// time", co-lead a group or, if you lead one, edit it or step down.
class RosterRunCard extends ConsumerWidget {
  const RosterRunCard({super.key, required this.session, this.venueName});

  final Session session;
  final String? venueName;

  Future<void> _sameAsLast(
    BuildContext context,
    WidgetRef ref,
    LastGroupSpec last,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final store = ref.read(lastGroupStoreProvider);
    Group? created;
    final ok = await groupWrite(context, ref, (repo) async {
      created = await repo.createGroup(
        session.id,
        kind: last.kind,
        label: last.label,
        description: last.description,
        pace: last.pace,
        distance: last.distance,
      );
      await rememberLastGroup(store, session, created!);
      return created;
    });
    final group = created;
    if (!ok || group == null) return;
    final repo = ref.read(groupsRepositoryProvider);
    messenger.showSnackBar(
      SnackBar(
        content: const Text("You're leading a group for this run"),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => unawaited(
            repo.deleteGroup(session.id, group.id).catchError((Object _) {
              messenger.showSnackBar(
                const SnackBar(content: Text("Couldn't undo. Try again.")),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(sessionGroupsProvider(session.id)).value ?? [];
    final units = ref.watch(unitPrefsProvider);
    final myId = ref.watch(myMemberIdProvider);
    final last = ref.watch(lastGroupSpecProvider(session.id)).value;
    final leading = [
      if (myId != null)
        for (final g in groups)
          if (g.isLedBy(myId)) g,
    ];
    final single = session.groupMode == 'single';
    final canOffer = leading.isEmpty && !(single && groups.isNotEmpty);
    final declined =
        leading.isEmpty && myResponse(ref, session.id).status == 'not_going';
    if (declined) return _declinedCard(context, theme, ref);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => unawaited(context.push('/runs/${session.id}')),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${dayHeader(session.localDate, ref.watch(groupsClockProvider)())}, '
                '${timeRange(session.localStartTime, session.localEndTime)}'
                '${venueName == null ? '' : ' · $venueName'}',
              ),
              Text(
                groupModeLabel(session.groupMode),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (groups.isEmpty)
                Text(
                  'No groups yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              for (final g in groups)
                _GroupLine(
                  group: g,
                  units: units,
                  mine: myId != null && g.isLedBy(myId),
                  onEdit: () => unawaited(
                    context.push('/runs/${session.id}/groups/${g.id}/edit'),
                  ),
                  onStepDown: () =>
                      unawaited(stepDownFrom(context, ref, session, g)),
                  onJoin: () =>
                      unawaited(joinAsLeaderWithRole(context, ref, session, g)),
                ),
              if (canOffer)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => unawaited(
                          context.push(
                            '/runs/${session.id}/groups/new?lead=true',
                          ),
                        ),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Offer to lead'),
                      ),
                      if (last != null)
                        ActionChip(
                          avatar: const Icon(Icons.replay, size: 18),
                          label: Text(
                            'Same as last time'
                            '${_lastLine(last, units)}',
                          ),
                          onPressed: () =>
                              unawaited(_sameAsLast(context, ref, last)),
                        ),
                    ],
                  ),
                ),
              // Not leading here: let the viewer say they can't, so the list
              // is only the runs still to decide. Same optimistic answer as
              // "Can't come" on the run page (D23).
              if (leading.isEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => unawaited(
                      respondToRun(
                        context,
                        ref,
                        session: session,
                        status: 'not_going',
                      ),
                    ),
                    child: const Text("Can't attend"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The one-line card for a run the viewer can't attend. It keeps its place
  /// in the date order. The API has no way to clear an answer, so there is no
  /// "Undo"; "Change" opens the run, where the answer can be changed (D57).
  Widget _declinedCard(BuildContext context, ThemeData theme, WidgetRef ref) {
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final when =
        '${dayHeader(session.localDate, ref.watch(groupsClockProvider)())}, '
        '${formatClock(session.localStartTime)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => unawaited(context.push('/runs/${session.id}')),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
              Text("Can't attend", style: muted),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => unawaited(context.push('/runs/${session.id}')),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lastLine(LastGroupSpec last, UnitPrefs units) {
    final line = specLine(last.pace, last.distance, units);
    return line.isEmpty ? '' : ': $line';
  }
}

class _GroupLine extends StatelessWidget {
  const _GroupLine({
    required this.group,
    required this.units,
    required this.mine,
    required this.onEdit,
    required this.onStepDown,
    required this.onJoin,
  });

  final Group group;
  final UnitPrefs units;
  final bool mine;
  final VoidCallback onEdit;
  final VoidCallback onStepDown;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = specLine(group.pace, group.distance, units);
    final title = [?group.label, if (spec.isNotEmpty) spec].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? groupKindLabel(group.kind) : title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (group.needsLeader)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    'Needs a leader',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  backgroundColor: theme.colorScheme.errorContainer,
                ),
            ],
          ),
          Text(
            group.leaders.isEmpty
                ? 'No leader yet'
                : 'Led by ${leadersText(group.leaders)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              if (mine) ...[
                OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
                TextButton(
                  onPressed: onStepDown,
                  child: const Text('Step down'),
                ),
              ] else
                TextButton(
                  onPressed: onJoin,
                  child: Text(
                    group.leaders.isEmpty
                        ? 'Lead this group'
                        : 'Join as co-leader',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
