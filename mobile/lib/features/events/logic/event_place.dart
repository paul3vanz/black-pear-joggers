import '../../../core/db/app_database.dart';

/// What the app can show about where an event is held, taken from the cached
/// `event_locations` row of a group's `locationId` (so it works offline). A
/// plain value with pure link builders, easy to test.
class EventPlace {
  const EventPlace({
    required this.kind,
    this.slug,
    this.country,
    this.region,
    this.lat,
    this.lng,
    this.url,
  });

  factory EventPlace.fromLocation(EventLocation l) => EventPlace(
    kind: l.kind,
    slug: l.slug,
    country: l.country,
    region: l.region,
    lat: l.lat,
    lng: l.lng,
    url: l.url,
  );

  final String kind;
  final String? slug;
  final String? country;
  final String? region;
  final double? lat;
  final double? lng;
  final String? url;

  /// "Worcester, West Midlands" (the API's location). In the UK the country
  /// adds nothing, so it is only appended for other countries; null when the
  /// API has no location.
  String? get regionLine {
    final r = region?.trim();
    final hasRegion = r != null && r.isNotEmpty;
    final inUk = country == null || country!.toUpperCase() == 'GB';
    final c = inUk ? null : countryName(country);
    final parts = [if (hasRegion) r, ?c];
    return parts.isEmpty ? null : parts.join(', ');
  }

  bool get hasCoordinates => lat != null && lng != null;

  /// The event's own page: the stored url, else (parkrun with a slug, UK or
  /// unknown country) the UK parkrun site, the same convention as
  /// `app:import-event-locations`.
  Uri? get pageUri {
    final u = url?.trim();
    if (u != null && u.isNotEmpty) {
      final uri = Uri.tryParse(u);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return uri;
      }
    }
    final s = slug?.trim();
    if (kind == 'parkrun' &&
        s != null &&
        s.isNotEmpty &&
        (country == null || country == 'GB')) {
      return Uri.https('www.parkrun.org.uk', '/${Uri.encodeComponent(s)}/');
    }
    return null;
  }

  /// "parkrun page" for parkruns, "Event website" otherwise.
  String get pageLabel => kind == 'parkrun' ? 'parkrun page' : 'Event website';

  /// Directions in the phone's maps app (a universal link), from lat/lng.
  Uri? get directionsUri => hasCoordinates
      ? Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': '$lat,$lng',
        })
      : null;

  /// Anything worth expanding the card for.
  bool get hasDetails =>
      regionLine != null || pageUri != null || directionsUri != null;
}

/// A readable country for the ISO code the API stores (only the few we know).
String? countryName(String? code) => switch (code?.toUpperCase()) {
  null || '' => null,
  'GB' => 'United Kingdom',
  final c => c,
};
