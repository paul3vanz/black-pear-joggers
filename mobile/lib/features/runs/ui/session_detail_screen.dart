import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/club_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/util/open_link.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/session_changes.dart';
import '../../groups/ui/groups_providers.dart';
import '../../groups/ui/groups_section.dart';
import '../../groups/ui/respond_card.dart';
import '../../groups/ui/whos_coming_section.dart';
import '../data/runs_repository.dart';
import 'run_format.dart';
import 'series_image.dart';
import 'runs_providers.dart';
import 'session_actions.dart';

/// `/runs/:id`: one run with its venue, notes and (for the committee) edit,
/// cancel and restore actions. Reads the Drift cache only.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Run')),
      body: SafeArea(
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text("Couldn't load this run.")),
          data: (s) => s == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "This run isn't available. It may have been removed. "
                      'Pull to refresh on the Runs tab, or check your '
                      'connection.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _Body(session: s),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clubId = ref.watch(activeClubIdProvider);
    ref.watch(attendanceBackfillProvider(session.id));
    final venue = session.venueId == null
        ? null
        : ref.watch(venueProvider(session.venueId!)).value;
    final series = session.seriesId == null
        ? null
        : ref.watch(seriesProvider(session.seriesId!)).value;
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final venueNames = {for (final v in venues) v.id: v.name};
    final cancelled = session.status == 'cancelled';
    final changes = sessionChanges(session, venueName: (id) => venueNames[id]);
    final slug = series?.cmsSlug;
    final map = venue == null ? null : mapsUrl(venue);
    return RefreshIndicator(
      onRefresh: () => _refresh(ref, clubId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Series banner (D49): only takes space once the image has loaded.
          SeriesImage(url: session.imageUrl, roundBottom: true, gapBelow: 12),
          if (cancelled)
            _Banner(
              icon: Icons.event_busy,
              background: scheme.errorContainer,
              foreground: scheme.onErrorContainer,
              title: 'This run is cancelled',
              lines: [if (session.cancelReason != null) session.cancelReason!],
            ),
          if (changes.isNotEmpty)
            _Banner(
              icon: Icons.edit_calendar,
              background: scheme.tertiaryContainer,
              foreground: scheme.onTertiaryContainer,
              title: 'Changed from the usual',
              lines: changes,
            ),
          Text(
            session.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule,
            text:
                '${longDate(session.localDate)}, '
                '${timeRange(session.localStartTime, session.localEndTime)}',
          ),
          RespondCard(
            session: session,
            showPace: session.groupMode != 'routes',
          ),
          if (venue != null) ...[
            _InfoRow(
              icon: Icons.place_outlined,
              text: venue.name,
              // The address is secondary: the name and the map link are enough.
              detail: venue.address,
            ),
            if (map != null)
              Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => openLink(context, ref, map),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in maps'),
                  ),
                ),
              ),
            if (venue.notes != null)
              _InfoRow(icon: Icons.info_outline, text: venue.notes!),
          ],
          if (session.coordinatorName != null)
            _InfoRow(
              icon: Icons.person_outline,
              text: 'Coordinator: ${session.coordinatorName}',
            ),
          GroupsSection(session: session),
          WhosComingSection(session: session),
          if (session.notes != null) ...[
            const SizedBox(height: 8),
            Text('Notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(session.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (slug != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => openLink(
                    context,
                    ref,
                    ref
                        .read(clubConfigProvider)
                        .website
                        .resolve('club-runs/$slug'),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('More about this run'),
                ),
              ),
            ),
          if (ref.watch(canManageRunsProvider))
            SessionActions(session: session, clubId: clubId),
        ],
      ),
    );
  }

  /// Pull-to-refresh: the sessions feed (offline is fine) and the plan.
  Future<void> _refresh(WidgetRef ref, int clubId) async {
    try {
      await ref.read(runsRepositoryProvider).refreshSessions(clubId);
    } on Object {
      // Offline: the cached run stays.
    }
    await refreshPlanFor(ref, session.id);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;

  /// Smaller, muted second line (e.g. a venue address).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyLarge),
                if (detail != null)
                  Text(
                    detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: foreground);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: style.copyWith(fontWeight: FontWeight.w700)),
                for (final l in lines) Text(l, style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
