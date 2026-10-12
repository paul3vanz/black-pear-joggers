/// Phase 8 fixtures matching docs/api-contract.md ("Event locations").
Map<String, Object?> eventLocationJson(
  String id, {
  String kind = 'parkrun',
  String name = 'Worcester parkrun',
  String? slug,
  String? region,
  double? lat,
  double? lng,
  String? url,
  String source = 'import',
  String? deletedAt,
  String updatedAt = '2026-10-01T10:00:00.000Z',
}) => {
  'id': id,
  'kind': kind,
  'name': name,
  'slug': slug,
  'country': 'GB',
  'region': region,
  'lat': lat,
  'lng': lng,
  'url': url,
  'source': source,
  'updatedAt': updatedAt,
  'deletedAt': deletedAt,
};

/// A list response for `GET /event-locations`.
Map<String, Object?> eventLocationsResponse(
  List<Map<String, Object?>> items, {
  String serverTime = '2026-10-07T12:00:00.000Z',
}) => {'items': items, 'serverTime': serverTime};

/// An event group (kind `event`): no pace, optionally tied to a location.
Map<String, Object?> eventGroupJson(
  String id, {
  String sessionId = 'a',
  String? locationId,
  String? label,
  String? description,
  int goingCount = 0,
  int maybeCount = 0,
  String? createdByMemberId,
}) => {
  'id': id,
  'sessionId': sessionId,
  'kind': 'event',
  'label': label,
  'description': description,
  'paceUnit': null,
  'paceFromS': null,
  'paceToS': null,
  'paceFromSPerKm': null,
  'paceToSPerKm': null,
  'distanceValue': null,
  'distanceUnit': null,
  'distanceM': null,
  'status': 'active',
  'sortOrder': 0,
  'leaders': <Object?>[],
  'locationId': locationId,
  'createdByMemberId': createdByMemberId,
  'goingCount': goingCount,
  'maybeCount': maybeCount,
  'updatedAt': '2026-10-05T10:00:00.000Z',
  'deletedAt': null,
};
