import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../membership/ui/membership_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ui/offline_banner.dart';
import '../../runs/data/runs_repository.dart';
import '../../runs/ui/runs_providers.dart';
import '../logic/roster.dart';
import 'group_access.dart';
import 'roster_run_card.dart';

/// `/runs/lead`: the next six weeks of runs grouped by week, so a member can
/// see which need a leader and offer to lead. Reads the Drift cache; pull to
/// refresh runs the normal sessions refresh.
class LeaderRosterScreen extends ConsumerStatefulWidget {
  const LeaderRosterScreen({super.key});

  @override
  ConsumerState<LeaderRosterScreen> createState() => _LeaderRosterScreenState();
}

class _LeaderRosterScreenState extends ConsumerState<LeaderRosterScreen> {
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    var failed = false;
    try {
      await repo.refreshSessions(clubId);
    } on Object {
      failed = true;
    }
    if (mounted) setState(() => _refreshFailed = failed);
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final sessions = ref.watch(upcomingSessionsProvider(clubId)).value;
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final venueNames = {for (final v in venues) v.id: v.name};
    final now = ref.watch(groupsClockProvider)();
    final weeks = buildRoster(sessions ?? const [], now);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lead a run')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'Runs in the next $rosterWeeks weeks. Offer to lead a group, or '
                'help lead one that is already there.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              if (_refreshFailed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: OfflineBanner(
                    "You're offline. Showing saved runs; changes need a "
                    'connection.',
                  ),
                ),
              if (sessions != null && weeks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No runs coming up that need leaders.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final week in weeks) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    week.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final s in week.sessions)
                  RosterRunCard(
                    key: ValueKey(s.id),
                    session: s,
                    venueName: s.venueId == null ? null : venueNames[s.venueId],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
