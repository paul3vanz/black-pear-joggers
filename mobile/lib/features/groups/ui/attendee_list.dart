import 'package:flutter/material.dart';

import '../../members/ui/member_avatar.dart';
import '../data/plan_dtos.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// Names with status (going / maybe) and each person's pace for this run in
/// the viewer's units. Only built when the plan carries names (the caller
/// leads the group, or is committee, admin or the coordinator).
///
/// [roles] maps a member id to their leader role in this group. Leaders sort
/// to the top and a co-leader or backmarker gets a tag after their name (the
/// group card itself leaves backmarkers out).
class AttendeeList extends StatelessWidget {
  const AttendeeList({
    super.key,
    required this.attendees,
    required this.units,
    this.roles = const {},
  });

  final List<PlanAttendee> attendees;
  final UnitPrefs units;
  final Map<String, String> roles;

  /// Leader, co-leader, backmarker, then everyone else, keeping the server's
  /// order within each band.
  List<PlanAttendee> get _ordered {
    if (roles.isEmpty) return attendees;
    int rank(PlanAttendee a) => switch (roles[a.memberId]) {
      'leader' => 0,
      'co_leader' => 1,
      'backmarker' => 2,
      _ => 3,
    };
    // List.sort is not stable, so break ties on the original position.
    final indexed =
        [for (var i = 0; i < attendees.length; i++) (i, attendees[i])]
          ..sort((a, b) {
            final byRole = rank(a.$2).compareTo(rank(b.$2));
            return byRole != 0 ? byRole : a.$1.compareTo(b.$1);
          });
    return [for (final (_, a) in indexed) a];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in _ordered)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  // Align keeps the tap target to the name, not the whole row.
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: MemberLink(
                            memberId: a.memberId.isEmpty ? null : a.memberId,
                            name: a.displayName,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (leaderRoleTag(roles[a.memberId] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '(${leaderRoleTag(roles[a.memberId]!)})',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
