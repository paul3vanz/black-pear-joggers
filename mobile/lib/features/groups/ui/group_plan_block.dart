import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import 'attendee_list.dart';
import 'group_format.dart' show goingText;
import 'groups_providers.dart';

/// The people going to one group: photo, name and pace for each, open by
/// default to encourage others to join (D140). There is no pace chart: the
/// paces beside the names are enough. Before a plan has been fetched it falls
/// back to the plain "N going" count. Used where a group has no card of its own
/// (the shared list of a run with no groups).
class GroupPlanBlock extends ConsumerWidget {
  const GroupPlanBlock({
    super.key,
    required this.sessionId,
    required this.groupId,
    required this.going,
    required this.maybe,
    this.countStyle,
  });

  final String sessionId;
  final String groupId;
  final int going;
  final int maybe;

  /// Style of the plain "N going" fallback.
  final TextStyle? countStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(sessionPlanProvider(sessionId)).value;
    final entry = plan?.forGroup(groupId);
    final names = entry?.attendees;
    if (names == null || names.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(goingText(going, maybe), style: countStyle),
      );
    }
    final group = ref
        .watch(sessionGroupsProvider(sessionId))
        .value
        ?.where((g) => g.id == groupId)
        .firstOrNull;
    return PlanBlock(
      names: names,
      namesTitle: "Who's in this group",
      namesCountText: goingText(going, maybe),
      initiallyExpanded: true,
      units: ref.watch(unitPrefsProvider),
      roles: {
        for (final l in group?.leaders ?? const <GroupLeader>[])
          if (l.memberId.isNotEmpty) l.memberId: l.role,
      },
    );
  }
}

/// An expandable list of the people going (photo, name, pace).
class PlanBlock extends StatelessWidget {
  const PlanBlock({
    super.key,
    required this.names,
    required this.namesTitle,
    this.namesCountText,
    this.initiallyExpanded = false,
    required this.units,
    this.roles = const {},
  });

  final List<PlanAttendee>? names;
  final String namesTitle;

  /// Replaces "[namesTitle] (n)" as the list's heading, e.g. "5 going".
  final String? namesCountText;
  final bool initiallyExpanded;
  final UnitPrefs units;

  /// Member id => leader role, for the names list.
  final Map<String, String> roles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = this.names;
    if (names == null || names.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          namesCountText ?? '$namesTitle (${names.length})',
          style: theme.textTheme.labelLarge,
        ),
        children: [AttendeeList(attendees: names, units: units, roles: roles)],
      ),
    );
  }
}
