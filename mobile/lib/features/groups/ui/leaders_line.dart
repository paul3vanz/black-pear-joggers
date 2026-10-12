import 'package:flutter/material.dart';

import '../../members/ui/member_avatar.dart';
import '../data/group_dtos.dart';
import 'group_format.dart';

/// "Led by" followed by each leader as a small avatar + tappable name (D69),
/// with their role tag ("co-leader") after the name. A [Wrap] so several
/// leaders flow onto a second line on a narrow phone instead of overflowing
/// (like `flex-wrap: wrap` in CSS). With no leaders it is the plain
/// "No leader yet" text; a leader without a member id is not tappable.
class LeadersLine extends StatelessWidget {
  const LeadersLine({super.key, required this.leaders, this.style});

  final List<GroupLeader> leaders;

  /// Style of "Led by" and the role tags (defaults to a muted `bodyMedium`).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted =
        style ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
    if (leaders.isEmpty) return Text('No leader yet', style: muted);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 2,
      children: [
        Text('Led by', style: muted),
        for (final l in leaders)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flexible so one very long name ellipsizes instead of overflowing.
              Flexible(
                child: MemberLink(
                  memberId: l.memberId.isEmpty ? null : l.memberId,
                  name: l.displayName,
                  avatarSize: 24,
                  style: muted?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (leaderRoleTag(l.role).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('(${leaderRoleTag(l.role)})', style: muted),
                ),
            ],
          ),
      ],
    );
  }
}
