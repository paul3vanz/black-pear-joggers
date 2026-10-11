import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/units/pace_spec.dart';
import 'attendance_actions.dart';
import 'group_access.dart';
import 'groups_providers.dart';
import 'pace_override_sheet.dart';

/// "Are you coming?" at the top of the run: I'm coming / Maybe / Can't come,
/// written optimistically. For a cancelled or finished run it explains why
/// there is nothing to answer.
class RespondCard extends ConsumerWidget {
  const RespondCard({super.key, required this.session, this.showPace = true});

  final Session session;

  /// Whether to include the "My pace for this run" row (routes sessions show
  /// it next to the route list instead).
  final bool showPace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(groupsClockProvider)();
    final closed = runClosedReason(session, now);
    final resp = myResponse(ref, session.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (closed != null)
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "$closed You can't respond to it any more.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            else ...[
              Text('Are you coming?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'going', label: Text("I'm coming")),
                  ButtonSegment(value: 'maybe', label: Text('Maybe')),
                  ButtonSegment(value: 'not_going', label: Text("Can't come")),
                ],
                selected: {?resp.status},
                onSelectionChanged: (s) {
                  if (s.isEmpty || s.first == resp.status) return;
                  unawaited(
                    respondToRun(
                      context,
                      ref,
                      session: session,
                      status: s.first,
                      groupId: s.first == 'not_going' ? null : resp.groupId,
                    ),
                  );
                },
              ),
              if (resp.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Waiting to sync',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              if (showPace) MyPaceTile(session: session),
            ],
          ],
        ),
      ),
    );
  }
}

/// "My pace for this run": shows the per-run override (in the viewer's units)
/// or "Using my usual pace", and opens the pace sheet. Saving also marks you
/// as coming when you had not answered or said you can't come.
class MyPaceTile extends ConsumerWidget {
  const MyPaceTile({super.key, required this.session});

  final Session session;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MyResponse resp,
    UnitPrefs units,
  ) async {
    final chosen = await showPaceOverrideSheet(
      context,
      current: resp.pace,
      viewerUnit: units.paceUnit,
    );
    if (chosen == null || !context.mounted) return;
    final coming = resp.status == 'going' || resp.status == 'maybe';
    await respondToRun(
      context,
      ref,
      session: session,
      status: coming ? resp.status! : 'going',
      groupId: coming ? resp.groupId : null,
      paceOverride: chosen,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resp = myResponse(ref, session.id);
    final units = ref.watch(unitPrefsProvider);
    final pace = resp.pace;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              pace is NoPace
                  ? 'Using my usual pace'
                  : 'My pace: ${pace.display(units.paceUnit)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => unawaited(_edit(context, ref, resp, units)),
            child: const Text('My pace for this run'),
          ),
        ],
      ),
    );
  }
}
