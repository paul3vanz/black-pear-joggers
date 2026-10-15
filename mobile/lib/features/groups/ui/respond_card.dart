import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/util/clock.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/pace_spec.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/attendance_repository.dart';
import 'attendance_actions.dart';
import 'group_access.dart';
import 'groups_providers.dart';
import 'pace_override_sheet.dart';
import 'pick_group_sheet.dart';

/// "Are you coming?" at the top of the run: I'm coming / Maybe / Can't come,
/// written optimistically. For a cancelled or finished run it explains why
/// there is nothing to answer.
class RespondCard extends ConsumerWidget {
  const RespondCard({super.key, required this.session, this.showPace = true});

  final Session session;

  /// Whether to include the "My pace for this run" row (routes sessions show
  /// it next to the route list instead).
  final bool showPace;

  /// Sends the answer; after "I'm coming" it may offer the pace group sheet
  /// (D50). A rejected answer (run cancelled or finished) offers nothing.
  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    String status,
    String? groupId,
  ) async {
    final outcome = await respondToRun(
      context,
      ref,
      session: session,
      status: status,
      groupId: status == 'not_going' ? null : groupId,
    );
    if (status != 'going' ||
        outcome == null ||
        outcome == AttendanceOutcome.rejected ||
        !context.mounted) {
      return;
    }
    await maybePromptPickGroup(context, ref, session);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(nowProvider);
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
                  unawaited(_answer(context, ref, s.first, resp.groupId));
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

/// The pace line of the "Are you coming?" card (D89). It always says which pace
/// the club will see for you on this run:
///
/// - **a pace for this run** (set with the sheet): "Running at 9:30/mi this
///   run" and a small **Change** link;
/// - **your usual pace** from the profile: "Usual pace: 9:00-9:30/mi" and
///   "Change for this run";
/// - **neither**: "No usual pace set", with links to set the usual pace in the
///   Profile tab or a pace for this run only.
///
/// All paces are in the viewer's units. Nothing shows when you said you can't
/// come (a pace means nothing then). Saving a pace also marks you as coming
/// when you had not answered.
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
    final resp = myResponse(ref, session.id);
    if (resp.status == 'not_going') return const SizedBox.shrink();
    final theme = Theme.of(context);
    final units = ref.watch(unitPrefsProvider);
    // The usual pace is the same cached row the Profile tab edits, so a pace
    // saved there shows up here at once. Null only until Drift's first emit.
    final usual = ref
        .watch(runPreferencesProvider(ref.watch(activeClubIdProvider)))
        .value
        ?.usualPace;
    final pace = resp.pace;
    // Small text buttons that sit inline with the text.
    final linkStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    void edit() => unawaited(_edit(context, ref, resp, units));

    final Widget line;
    if (pace is! NoPace) {
      line = Row(
        children: [
          Expanded(
            child: Text(
              'Running at ${pace.display(units.paceUnit)} this run',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            key: const ValueKey('pace-change'),
            style: linkStyle,
            onPressed: edit,
            child: const Text('Change'),
          ),
        ],
      );
    } else if (usual != null && !usual.isNone) {
      line = Row(
        children: [
          Expanded(
            child: Text(
              'Usual pace: ${usual.display(units.paceUnit)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            key: const ValueKey('pace-change'),
            style: linkStyle,
            onPressed: edit,
            child: const Text('Change for this run'),
          ),
        ],
      );
    } else {
      line = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (usual != null)
            Text('No usual pace set', style: theme.textTheme.bodyMedium),
          Wrap(
            children: [
              if (usual != null)
                TextButton(
                  key: const ValueKey('pace-set-usual'),
                  style: linkStyle,
                  // The pace boxes are on the Profile tab (D88).
                  onPressed: () => context.go('/profile'),
                  child: const Text('Set your usual pace'),
                ),
              TextButton(
                key: const ValueKey('pace-change'),
                style: linkStyle,
                onPressed: edit,
                child: const Text('Set pace for this run'),
              ),
            ],
          ),
        ],
      );
    }
    return Padding(padding: const EdgeInsets.only(top: 8), child: line);
  }
}
