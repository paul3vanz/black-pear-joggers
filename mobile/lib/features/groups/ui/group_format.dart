import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/units/distance.dart';
import '../../../core/units/pace_spec.dart';
import '../data/group_dtos.dart';
import 'groups_providers.dart';

/// Card label for a group `kind` ("Pace group", "Jog/walk", ...).
String groupKindLabel(String kind) => switch (kind) {
  'jog_walk' => 'Jog/walk',
  'efforts' => 'Efforts',
  'route' => 'Route',
  'social' => 'Social',
  'other' => 'Other',
  _ => 'Pace group',
};

/// Dropdown label for a `kind` in the group editor.
String groupKindEditorLabel(String kind) =>
    kind == 'run' ? 'Run' : groupKindLabel(kind);

IconData groupKindIcon(String kind) => switch (kind) {
  'jog_walk' => Icons.directions_walk,
  'efforts' => Icons.bolt,
  'route' => Icons.route,
  'social' => Icons.people_outline,
  'other' => Icons.more_horiz,
  _ => Icons.directions_run,
};

/// Tag shown after a leader's name; empty for a plain leader.
String leaderRoleTag(String role) => switch (role) {
  'co_leader' => 'co-leader',
  'backmarker' => 'backmarker',
  _ => '',
};

/// "Jo Bloggs, Sam Lapsed (co-leader)".
String leadersText(List<GroupLeader> leaders) => [
  for (final l in leaders)
    leaderRoleTag(l.role).isEmpty
        ? l.displayName
        : '${l.displayName} (${leaderRoleTag(l.role)})',
].join(', ');

/// The pace of a group in the viewer's pace unit, e.g. `5:36/km (9:00/mi)` for
/// a km viewer and `9:00/mi` for a mile viewer. Empty with no pace.
String paceText(PaceSpec pace, UnitPrefs units) => pace.display(units.paceUnit);

/// The distance in the viewer's distance unit, e.g. `4.8 km (3 mi)`. Null with
/// no distance.
String? distanceText(Distance? distance, UnitPrefs units) =>
    distance?.display(units.distanceUnit);

/// Pace and distance as one line (the editor preview), e.g.
/// `9:00-9:30/mi · 3 mi`. Empty when a group has neither.
String specLine(PaceSpec pace, Distance? distance, UnitPrefs units) => [
  paceText(pace, units),
  ?distanceText(distance, units),
].where((p) => p.isNotEmpty).join(' · ');

/// "1 group" / "3 groups".
String countLabel(int n, String one, String many) =>
    n == 1 ? '1 $one' : '$n $many';

/// "5 going" or "5 going, 1 maybe".
String goingText(int going, int maybe) =>
    maybe > 0 ? '$going going, $maybe maybe' : '$going going';

/// Heading of the Groups section for a session's group mode.
String groupsHeading(String mode) => switch (mode) {
  'paced' => 'Pace groups',
  'single' => 'Coached session',
  'routes' => 'Routes',
  _ => 'Groups',
};

/// The sentence under the heading.
String groupsIntro(String mode) => switch (mode) {
  'paced' => 'Pick the group that suits your pace, or offer to lead one.',
  'single' => 'One group for everyone, together.',
  'open' =>
    'Everyone starts together; you can say what pace you will run and '
        'others can join you.',
  'routes' => 'The coordinator sets the routes. Pick the one you will do.',
  _ => '',
};

/// Friendly text for a failed group or attendance write.
String groupErrorMessage(Object error) {
  final api = ApiException.from(error);
  if (api.isNetworkError) return 'You need a connection to do that.';
  return switch (api.code) {
    'session_cancelled' => 'This run has been cancelled.',
    'session_past' => 'This run has finished.',
    _ => api.statusCode == 403 ? "You can't do that." : api.message,
  };
}
