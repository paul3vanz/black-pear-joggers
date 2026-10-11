import 'package:flutter/material.dart';

import '../data/plan_dtos.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// Names with status (going / maybe) and each person's pace for this run in
/// the viewer's units. Only built when the plan carries names (the caller
/// leads the group, or is committee, admin or the coordinator).
class AttendeeList extends StatelessWidget {
  const AttendeeList({super.key, required this.attendees, required this.units});

  final List<PlanAttendee> attendees;
  final UnitPrefs units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in attendees)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(a.displayName, style: theme.textTheme.bodyLarge),
                ),
                if (a.status == 'maybe')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('maybe', style: theme.textTheme.labelMedium),
                  ),
                Text(
                  a.pace.isNone ? 'no pace set' : paceText(a.pace, units),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
