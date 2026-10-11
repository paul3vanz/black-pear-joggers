import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

/// A string (or null) from JSON, treating empty strings as null.
String? _str(Object? v) {
  final s = v as String?;
  return (s == null || s.isEmpty) ? null : s;
}

/// One item of `GET /app/clubs/{clubId}/venues`.
class VenueDto {
  const VenueDto({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.notes,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String? notes;
  final DateTime updatedAt;

  /// Non-null for a tombstone: remove the row locally.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory VenueDto.fromJson(Map<String, Object?> json) => VenueDto(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    address: _str(json['address']),
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    notes: _str(json['notes']),
    updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    deletedAt: _date(json['deletedAt']),
  );

  VenuesCompanion toCompanion(int clubId) => VenuesCompanion.insert(
    id: id,
    clubId: clubId,
    name: name,
    address: Value(address),
    lat: Value(lat),
    lng: Value(lng),
    notes: Value(notes),
    updatedAt: updatedAt,
  );
}

/// One item of `GET /app/clubs/{clubId}/series`.
class SeriesDto {
  const SeriesDto({
    required this.id,
    required this.title,
    required this.description,
    required this.venueId,
    required this.weekday,
    required this.startTime,
    required this.durationMin,
    required this.intervalWeeks,
    required this.validFrom,
    required this.validUntil,
    required this.groupMode,
    required this.cmsSlug,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? venueId;
  final int weekday;
  final String startTime;
  final int durationMin;
  final int intervalWeeks;
  final String validFrom;
  final String? validUntil;
  final String groupMode;
  final String? cmsSlug;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory SeriesDto.fromJson(Map<String, Object?> json) => SeriesDto(
    id: json['id']! as String,
    title: json['title'] as String? ?? '',
    description: _str(json['description']),
    venueId: _str(json['venueId']),
    weekday: (json['weekday'] as num?)?.toInt() ?? 1,
    startTime: json['startTime'] as String? ?? '00:00',
    durationMin: (json['durationMin'] as num?)?.toInt() ?? 60,
    intervalWeeks: (json['intervalWeeks'] as num?)?.toInt() ?? 1,
    validFrom: json['validFrom'] as String? ?? '',
    validUntil: _str(json['validUntil']),
    groupMode: json['groupMode'] as String? ?? 'open',
    cmsSlug: _str(json['cmsSlug']),
    updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    deletedAt: _date(json['deletedAt']),
  );

  SessionSeriesCompanion toCompanion(int clubId) =>
      SessionSeriesCompanion.insert(
        id: id,
        clubId: clubId,
        title: title,
        description: Value(description),
        venueId: Value(venueId),
        weekday: weekday,
        startTime: startTime,
        durationMin: durationMin,
        intervalWeeks: Value(intervalWeeks),
        validFrom: validFrom,
        validUntil: Value(validUntil),
        groupMode: groupMode,
        cmsSlug: Value(cmsSlug),
        updatedAt: updatedAt,
      );
}

/// One item of `GET /app/clubs/{clubId}/sessions`.
class SessionDto {
  const SessionDto({
    required this.id,
    required this.seriesId,
    required this.occurrenceDate,
    required this.title,
    required this.venueId,
    required this.notes,
    required this.startsAt,
    required this.endsAt,
    required this.localDate,
    required this.localStartTime,
    required this.localEndTime,
    required this.groupMode,
    required this.status,
    required this.cancelReason,
    required this.coordinatorMemberId,
    required this.coordinatorName,
    required this.isDetached,
    required this.original,
    this.groupsJson,
    this.summaryJson,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String? seriesId;
  final String? occurrenceDate;
  final String title;
  final String? venueId;
  final String? notes;
  final DateTime startsAt;
  final DateTime endsAt;
  final String localDate;
  final String localStartTime;
  final String localEndTime;
  final String groupMode;
  final String status;
  final String? cancelReason;
  final String? coordinatorMemberId;
  final String? coordinatorName;
  final bool isDetached;

  /// The contract's `original` block, kept as raw JSON-able map.
  final Map<String, Object?>? original;

  /// Phase 4: the embedded `groups` / `summary` re-encoded as JSON, or null when
  /// the payload had none (an older server). A null leaves a stored value alone.
  final String? groupsJson;
  final String? summaryJson;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory SessionDto.fromJson(Map<String, Object?> json) {
    final startsAt = _date(json['startsAt']) ?? DateTime.now();
    final rawOriginal = json['original'];
    return SessionDto(
      id: json['id']! as String,
      seriesId: _str(json['seriesId']),
      occurrenceDate: _str(json['occurrenceDate']),
      title: json['title'] as String? ?? '',
      venueId: _str(json['venueId']),
      notes: _str(json['notes']),
      startsAt: startsAt,
      endsAt: _date(json['endsAt']) ?? startsAt,
      localDate: json['localDate'] as String? ?? '',
      localStartTime: json['localStartTime'] as String? ?? '',
      localEndTime: json['localEndTime'] as String? ?? '',
      groupMode: json['groupMode'] as String? ?? 'open',
      status: json['status'] as String? ?? 'scheduled',
      cancelReason: _str(json['cancelReason']),
      coordinatorMemberId: _str(json['coordinatorMemberId']),
      coordinatorName: _str(json['coordinatorName']),
      isDetached: json['isDetached'] as bool? ?? false,
      original: rawOriginal is Map
          ? Map<String, Object?>.from(rawOriginal)
          : null,
      groupsJson: json['groups'] is List ? jsonEncode(json['groups']) : null,
      summaryJson: json['summary'] is Map ? jsonEncode(json['summary']) : null,
      updatedAt: _date(json['updatedAt']) ?? startsAt,
      deletedAt: _date(json['deletedAt']),
    );
  }

  SessionsCompanion toCompanion(int clubId) => SessionsCompanion.insert(
    id: id,
    clubId: clubId,
    seriesId: Value(seriesId),
    occurrenceDate: Value(occurrenceDate),
    title: title,
    venueId: Value(venueId),
    notes: Value(notes),
    startsAt: startsAt,
    endsAt: endsAt,
    localDate: localDate,
    localStartTime: localStartTime,
    localEndTime: localEndTime,
    groupMode: groupMode,
    status: Value(status),
    cancelReason: Value(cancelReason),
    coordinatorMemberId: Value(coordinatorMemberId),
    coordinatorName: Value(coordinatorName),
    isDetached: Value(isDetached),
    originalJson: Value(original == null ? null : jsonEncode(original)),
    groupsJson: groupsJson == null ? const Value.absent() : Value(groupsJson),
    summaryJson: summaryJson == null
        ? const Value.absent()
        : Value(summaryJson),
    updatedAt: updatedAt,
  );
}
