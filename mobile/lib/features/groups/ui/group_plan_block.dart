import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import '../logic/pace_spread.dart';
import 'attendee_list.dart';
import 'groups_providers.dart';
import 'pace_strip.dart';

/// The anonymous pace spread of one group and, when the plan carries names for
/// it, an expandable "Who's in this group" list. Renders nothing until a plan
/// has been fetched, and nothing extra when `attendees` is null (not allowed).
class GroupPlanBlock extends ConsumerWidget {
  const GroupPlanBlock({
    super.key,
    required this.sessionId,
    required this.groupId,
    required this.going,
    required this.maybe,
    this.withCounts = true,
  });

  final String sessionId;
  final String groupId;
  final int going;
  final int maybe;

  /// Repeat "N going" before the pace range (off on cards that show it).
  final bool withCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(sessionPlanProvider(sessionId)).value;
    final entry = plan?.forGroup(groupId);
    if (entry == null) return const SizedBox.shrink();
    final units = ref.watch(unitPrefsProvider);
    // Backmarkers are left off the group card, so their role shows against
    // their name in the who's-in-this-group list instead.
    final group = ref
        .watch(sessionGroupsProvider(sessionId))
        .value
        ?.where((g) => g.id == groupId)
        .firstOrNull;
    return PlanBlock(
      spread: buildPaceSpread(entry.paces, units.paceUnit),
      going: going,
      maybe: maybe,
      withCounts: withCounts,
      names: entry.attendees,
      namesTitle: "Who's in this group",
      units: units,
      roles: {
        for (final l in group?.leaders ?? const <GroupLeader>[])
          if (l.memberId.isNotEmpty) l.memberId: l.role,
      },
    );
  }
}

/// Spread strip, "5 going · usually …" text and optional names.
class PlanBlock extends StatelessWidget {
  const PlanBlock({
    super.key,
    required this.spread,
    required this.going,
    required this.maybe,
    this.withCounts = true,
    required this.names,
    required this.namesTitle,
    required this.units,
    this.roles = const {},
  });

  final PaceSpread spread;
  final int going;
  final int maybe;
  final bool withCounts;
  final List<PlanAttendee>? names;
  final String namesTitle;
  final UnitPrefs units;

  /// Member id => leader role, for the names list.
  final Map<String, String> roles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = this.names;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!spread.isEmpty) ...[
          const SizedBox(height: 8),
          PaceStrip(spread: spread),
          const SizedBox(height: 4),
          Text(
            withCounts
                ? spreadSummary(spread, going: going, maybe: maybe)
                : spreadRange(spread),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (names != null && names.isNotEmpty)
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '$namesTitle (${names.length})',
                style: theme.textTheme.labelLarge,
              ),
              children: [
                AttendeeList(attendees: names, units: units, roles: roles),
              ],
            ),
          ),
      ],
    );
  }
}
