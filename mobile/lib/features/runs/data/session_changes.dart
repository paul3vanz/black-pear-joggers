import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/util/clock_time.dart';

/// What the series says about a session that was edited away from it
/// (the contract's `original` block).
class SessionOriginal {
  const SessionOriginal({this.localStartTime, this.venueId, this.title});

  final String? localStartTime;
  final String? venueId;
  final String? title;

  /// Decodes the stored JSON; null when absent or malformed.
  static SessionOriginal? decode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json);
      if (map is! Map) return null;
      return SessionOriginal(
        localStartTime: map['localStartTime'] as String?,
        venueId: map['venueId'] as String?,
        title: map['title'] as String?,
      );
    } on Object {
      return null;
    }
  }
}

/// Human labels for how [session] differs from its series, e.g.
/// `Moved from Perdiswell`, `Starts at 18:30 (usually 19:00)`,
/// `Renamed (usually "Monday club run")`. Empty when nothing differs, there is
/// no `original`, or the run is cancelled (the Cancelled badge says enough).
///
/// [venueName] resolves a venue id to its name (null if unknown/not cached).
List<String> sessionChanges(
  Session session, {
  String? Function(String venueId)? venueName,
}) {
  if (session.status == 'cancelled') return const [];
  final original = SessionOriginal.decode(session.originalJson);
  if (original == null) return const [];
  final labels = <String>[];
  if (original.venueId != session.venueId) {
    final from = original.venueId == null
        ? null
        : venueName?.call(original.venueId!);
    labels.add(from == null ? 'Venue changed' : 'Moved from $from');
  }
  final usual = original.localStartTime;
  if (usual != null && usual != session.localStartTime) {
    labels.add(
      'Starts at ${formatClock(session.localStartTime)} '
      '(usually ${formatClock(usual)})',
    );
  }
  final usualTitle = original.title;
  if (usualTitle != null && usualTitle != session.title) {
    labels.add('Renamed (usually "$usualTitle")');
  }
  return labels;
}

/// Explainer text for a session's group mode.
String groupModeExplainer(String mode) => switch (mode) {
  'paced' => 'Pace groups: everyone runs with a group at their own pace.',
  'single' => 'A coached session for everyone together.',
  'open' => 'Open run: everyone runs together.',
  'routes' => 'Routes: the coordinator sets the routes on the day.',
  'events' =>
    'Events: everyone picks the event they are running that day, '
        'such as a parkrun.',
  'race' => 'One race: people say they are going.',
  _ => '',
};

/// Short label for a group mode (list rows, form dropdowns).
String groupModeLabel(String mode) => switch (mode) {
  'paced' => 'Pace groups',
  'single' => 'Coached session',
  'open' => 'Open run',
  'routes' => 'Routes',
  'events' => 'Events (e.g. parkrun)',
  'race' => 'Race (one event)',
  _ => mode,
};
