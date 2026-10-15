import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/db/app_database.dart';
import '../../../core/util/clock.dart';
import '../../updates/ui/updates_providers.dart';
import '../data/runs_repository.dart';

// Hand-written (not @riverpod): riverpod_generator can't see Drift's row types.

/// Upcoming sessions (today onward), ordered by date and start time. Watches
/// the club-local date, so at midnight the query restarts with the new day and
/// yesterday's runs drop out without a refresh (D87).
final upcomingSessionsProvider = StreamProvider.family<List<Session>, int>(
  (ref, clubId) => ref
      .watch(runsRepositoryProvider)
      .watchUpcomingSessions(clubId, since: ref.watch(clubTodayProvider).date),
);

final sessionProvider = StreamProvider.family<Session?, String>(
  (ref, id) => ref.watch(runsRepositoryProvider).watchSession(id),
);

final venueProvider = StreamProvider.family<Venue?, String>(
  (ref, id) => ref.watch(runsRepositoryProvider).watchVenue(id),
);

final venuesProvider = StreamProvider.family<List<Venue>, int>(
  (ref, clubId) => ref.watch(runsRepositoryProvider).watchVenues(clubId),
);

final seriesListProvider = StreamProvider.family<List<RunSeries>, int>(
  (ref, clubId) => ref.watch(runsRepositoryProvider).watchSeriesList(clubId),
);

final seriesProvider = StreamProvider.family<RunSeries?, String>(
  (ref, id) => ref.watch(runsRepositoryProvider).watchSeries(id),
);

/// Committee/admin may edit runs, series and venues (same rule as posting
/// updates). The server enforces it too (403).
final canManageRunsProvider = Provider<bool>(
  (ref) => ref.watch(canPostProvider),
);

/// Friendly text for a failed committee write.
String runsErrorMessage(Object error) {
  final api = ApiException.from(error);
  if (api.isNetworkError) return 'You need a connection to do that.';
  if (api.statusCode == 403) return 'Only the committee can do that.';
  return switch (api.code) {
    'in_use' =>
      'That venue is still used by a series or an upcoming run. Change '
          'those first.',
    'series_session' =>
      'This run belongs to a weekly series, so it can only be cancelled, '
          'not deleted.',
    _ => api.message,
  };
}
