import 'dart:convert';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/distance.dart';

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// A route set for one run (D130), e.g. a 10 mile and a 14 mile route for a
/// long run. A group of that run may pick one instead of giving its own link.
class SessionRoute {
  const SessionRoute({
    required this.id,
    required this.sessionId,
    required this.label,
    required this.url,
    this.distanceValue,
    this.distanceUnit,
    this.sortOrder = 0,
  });

  final String id;
  final String sessionId;
  final String label;

  /// Full http(s) link, opened in the device browser.
  final String url;
  final double? distanceValue;
  final String? distanceUnit;
  final int sortOrder;

  factory SessionRoute.fromJson(Map<String, Object?> json) => SessionRoute(
    id: json['id']! as String,
    sessionId: json['sessionId'] as String? ?? '',
    label: json['label'] as String? ?? '',
    url: json['url'] as String? ?? '',
    distanceValue: (json['distanceValue'] as num?)?.toDouble(),
    distanceUnit: _str(json['distanceUnit']),
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'label': label,
    'url': url,
    'distanceValue': distanceValue,
    'distanceUnit': distanceUnit,
    'sortOrder': sortOrder,
  };

  /// The distance as entered, or null.
  Distance? get distance {
    final unit = DistUnit.fromCode(distanceUnit);
    final value = distanceValue;
    return unit == null || value == null ? null : Distance(value, unit);
  }
}

/// Decodes a stored `routesJson`; an empty list when absent or malformed.
List<SessionRoute> decodeRoutes(String? json) {
  if (json == null || json.isEmpty) return <SessionRoute>[];
  try {
    final list = jsonDecode(json);
    if (list is! List) return <SessionRoute>[];
    return [
      for (final r in list)
        if (r is Map && r['id'] is String)
          SessionRoute.fromJson(Map<String, Object?>.from(r)),
    ];
  } on Object {
    return <SessionRoute>[];
  }
}

String encodeRoutes(List<SessionRoute> routes) =>
    jsonEncode([for (final r in routes) r.toJson()]);
