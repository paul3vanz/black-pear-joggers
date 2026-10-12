import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/db/app_database.dart';
import '../data/event_locations_repository.dart';

// Hand-written (not @riverpod): riverpod_generator can't see Drift's row types.

/// Live event locations of a club, ordered by name (all kinds).
final eventLocationsProvider = StreamProvider.family<List<EventLocation>, int>(
  (ref, clubId) => ref.watch(eventLocationsRepositoryProvider).watch(clubId),
);

/// Friendly text for a failed event location write.
String eventLocationErrorMessage(Object error) {
  final api = ApiException.from(error);
  if (api.isNetworkError) return 'You need a connection to do that.';
  if (api.statusCode == 403) return 'Only the committee can do that.';
  return api.message;
}
