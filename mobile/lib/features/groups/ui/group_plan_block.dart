import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_dtos.dart';
import '../data/plan_dtos.dart';
import '../logic/pace_spread.dart';
import 'attendee_list.dart';
import 'group_format.dart' show goingText;
import 'groups_providers.dart';
import 'pace_strip.dart';

/// The pace spread of one group and the people going: an expandable list of
/// photo, name and pace, open by default to encourage others to join (D140).
/// Before a plan has been fetched it falls back to the plain "N going" count.
class GroupPlanBlock extends ConsumerWidget {
  const GroupPlanBlock({
    super.key,
    required this.sessionId,
    required this.groupId,
    required this.going,
    required this.maybe,
    this.withCounts = true,
    this.countStyle,
  });

  final String sessionId;
  final String groupId;
  final int going;
  final int maybe;

  /// Repeat "N going" before the pace range (off on cards that show it).
  final bool withCounts;

  /// Style of the plain "N going" fallback.
  final TextStyle? countStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(sessionPlanProvider(sessionId)).value;
    final entry = plan?.forGroup(groupId);
    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(goingText(going, maybe), style: countStyle),
      );
    }
    final units = ref.watch(unitPrefsProvider);
    // Backmarkers are left off the group card, so their role shows against
    // their name in the who's-in-this-group list instead.
    final group = ref
        .watch(sessionGroupsProvider(sessionId))
        .value
        ?.where((g) => g.id == groupId)
        .firstOrNull;
    final block = PlanBlock(
      spread: buildPaceSpread(entry.paces, units.paceUnit),
      going: going,
      maybe: maybe,
      withCounts: withCounts,
      names: entry.attendees,
      namesTitle: "Who's in this group",
      namesCountText: goingText(going, maybe),
      initiallyExpanded: true,
      units: units,
      roles: {
        for (final l in group?.leaders ?? const <GroupLeader>[])
          if (l.memberId.isNotEmpty) l.memberId: l.role,
      },
    );
    // Nobody to list (an older server, or an event run): keep the count.
    if (withCounts || (entry.attendees?.isNotEmpty ?? false)) return block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(goingText(going, maybe), style: countStyle),
        ),
        block,
      ],
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
    this.namesCountText,
    this.initiallyExpanded = false,
    required this.units,
    this.roles = const {},
  });

  final PaceSpread spread;
  final int going;
  final int maybe;
  final bool withCounts;
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
              initiallyExpanded: initiallyExpanded,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                namesCountText ?? '$namesTitle (${names.length})',
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
