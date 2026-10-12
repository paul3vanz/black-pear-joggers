import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// A string (or null) from JSON, treating empty strings as null.
String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// The `kind` values of an event location.
const eventLocationKinds = ['parkrun', 'race', 'other'];

/// Chip/label text for a location `kind`.
String eventKindLabel(String kind) => switch (kind) {
  'parkrun' => 'parkrun',
  'race' => 'Race',
  'other' => 'Other',
  _ => kind,
};

/// One item of `GET /app/clubs/{clubId}/event-locations` (or the object the
/// POST and PATCH return). A non-null [deletedAt] is a tombstone.
class EventLocationDto {
  const EventLocationDto({
    required this.id,
    required this.kind,
    required this.name,
    this.slug,
    this.country,
    this.region,
    this.lat,
    this.lng,
    this.url,
    this.source = 'manual',
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String kind;
  final String name;
  final String? slug;
  final String? country;
  final String? region;
  final double? lat;
  final double? lng;
  final String? url;
  final String source;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory EventLocationDto.fromJson(Map<String, Object?> json) =>
      EventLocationDto(
        id: json['id']! as String,
        kind: _str(json['kind']) ?? 'other',
        name: json['name'] as String? ?? '',
        slug: _str(json['slug']),
        country: _str(json['country']),
        region: _str(json['region']),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        url: _str(json['url']),
        source: _str(json['source']) ?? 'manual',
        updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
        deletedAt: _date(json['deletedAt']),
      );

  EventLocationsCompanion toCompanion(int clubId) =>
      EventLocationsCompanion.insert(
        id: id,
        clubId: clubId,
        kind: kind,
        name: name,
        slug: Value(slug),
        country: Value(country),
        region: Value(region),
        lat: Value(lat),
        lng: Value(lng),
        url: Value(url),
        source: Value(source),
        updatedAt: updatedAt,
        deletedAt: Value(deletedAt),
      );
}
