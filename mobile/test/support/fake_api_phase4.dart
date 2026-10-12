import 'dart:convert';

import 'package:bpj/core/db/app_database.dart';
import 'package:bpj/core/units/dist_unit.dart';
import 'package:drift/drift.dart';

import 'fake_api_phase3.dart';

/// Phase 4 fixtures matching docs/api-contract.md.
Map<String, Object?> groupJson(
  String id, {
  String sessionId = 'a',
  String kind = 'run',
  String? label,
  String? description,
  String? paceUnit = 'mi',
  int? paceFromS = 570,
  int? paceToS = 600,
  int? paceFromSPerKm = 354,
  int? paceToSPerKm = 373,
  double? distanceValue,
  String? distanceUnit,
  String status = 'active',
  List<Map<String, Object?>> leaders = const [],
  int goingCount = 0,
  int maybeCount = 0,
}) => {
  'id': id,
  'sessionId': sessionId,
  'kind': kind,
  'label': label,
  'description': description,
  'paceUnit': paceUnit,
  'paceFromS': paceFromS,
  'paceToS': paceToS,
  'paceFromSPerKm': paceFromSPerKm,
  'paceToSPerKm': paceToSPerKm,
  'distanceValue': distanceValue,
  'distanceUnit': distanceUnit,
  'distanceM': null,
  'status': status,
  'sortOrder': 0,
  'leaders': leaders,
  'goingCount': goingCount,
  'maybeCount': maybeCount,
  'updatedAt': '2026-10-05T10:00:00.000Z',
  'deletedAt': null,
};

Map<String, Object?> leaderJson(
  String memberId, {
  String name = 'Jo Bloggs',
  String role = 'leader',
}) => {'memberId': memberId, 'displayName': name, 'role': role};

Map<String, Object?> summaryJson({
  int groupCount = 0,
  int leaderCount = 0,
  int goingCount = 0,
  int maybeCount = 0,
  String? myStatus,
  String? myGroupId,
  bool myLeading = false,
}) => {
  'groupCount': groupCount,
  'leaderCount': leaderCount,
  'goingCount': goingCount,
  'maybeCount': maybeCount,
  'myStatus': myStatus,
  'myGroupId': myGroupId,
  'myLeading': myLeading,
};

/// A sessions-payload item carrying Phase 4 `groups` and `summary`.
Map<String, Object?> sessionWithGroups(
  String id, {
  required String localDate,
  List<Map<String, Object?>> groups = const [],
  Map<String, Object?>? summary,
}) => {
  ...sessionJson(id, localDate: localDate),
  'groups': groups,
  'summary': ?summary,
};

Map<String, Object?> attendanceJson(
  String sessionId, {
  String status = 'going',
  String? groupId,
  String? paceUnit,
  int? paceFromS,
  int? paceToS,
}) => {
  'sessionId': sessionId,
  'status': status,
  'groupId': groupId,
  'paceUnit': paceUnit,
  'paceFromS': paceFromS,
  'paceToS': paceToS,
  'updatedAt': '2026-10-07T12:00:00.000Z',
};

/// Inserts a cached session row (club 1) directly, optionally with the
/// Phase 4 JSON columns, without going through a refresh.
Future<void> seedSession(
  AppDatabase db,
  String id, {
  String localDate = '2026-10-12',
  List<Map<String, Object?>>? groups,
  Map<String, Object?>? summary,
  String groupMode = 'paced',
  String status = 'scheduled',
  String? coordinatorMemberId,
}) async {
  final dto = sessionWithGroups(
    id,
    localDate: localDate,
    groups: groups ?? const [],
    summary: summary,
  );
  await db
      .into(db.sessions)
      .insert(
        SessionsCompanion.insert(
          id: id,
          clubId: 1,
          title: dto['title']! as String,
          startsAt: DateTime.utc(2026, 10, 12, 18),
          endsAt: DateTime.utc(2026, 10, 12, 19, 30),
          localDate: localDate,
          localStartTime: '19:00',
          localEndTime: const Value('20:30'),
          groupMode: groupMode,
          status: Value(status),
          coordinatorMemberId: Value(coordinatorMemberId),
          updatedAt: DateTime.utc(2026, 10, 5),
        ),
      );
  if (groups != null || summary != null) {
    await (db.update(db.sessions)..where((s) => s.id.equals(id))).write(
      SessionsCompanion(
        groupsJson: groups == null
            ? const Value.absent()
            : Value(_json(groups)),
        summaryJson: summary == null
            ? const Value.absent()
            : Value(_json(summary)),
      ),
    );
  }
}

String _json(Object o) => jsonEncode(o);

/// The caller's membership row for club 1 (what the repositories read for
/// their own member id).
Future<void> seedMembership(AppDatabase db, {String memberId = 'me'}) => db
    .into(db.memberships)
    .insert(
      MembershipsCompanion.insert(
        memberId: memberId,
        clubId: 1,
        clubName: 'Black Pear Joggers',
        clubSlug: 'bpj',
        status: 'active',
        updatedAt: DateTime.utc(2026, 10, 1),
      ),
    );

/// Stores the caller's pace and distance units (default is mi / mi).
Future<void> seedUnits(
  AppDatabase db, {
  DistUnit pace = DistUnit.mi,
  DistUnit distance = DistUnit.mi,
}) => db
    .into(db.preferences)
    .insert(
      PreferencesCompanion.insert(
        clubId: const Value(1),
        paceUnit: pace.code,
        distanceUnit: distance.code,
      ),
    );

Map<String, Object?> planPaceJson(int from, [int? to]) => {
  'fromSPerKm': from,
  'toSPerKm': to,
};

Map<String, Object?> attendeeJson(
  String memberId,
  String name, {
  String status = 'going',
  String? paceUnit = 'mi',
  int? paceFromS = 570,
  int? paceToS,
}) => {
  'memberId': memberId,
  'displayName': name,
  'status': status,
  'paceUnit': paceUnit,
  'paceFromS': paceFromS,
  'paceToS': paceToS,
};

/// A `GET …/plan` body. A group's `attendees` and `members` are omitted
/// (as the server does) when null.
Map<String, Object?> planJson(
  String sessionId, {
  List<Map<String, Object?>> groups = const [],
  int unassignedGoing = 0,
  int unassignedMaybe = 0,
  List<Map<String, Object?>> unassignedPaces = const [],
  List<Map<String, Object?>>? unassignedMembers,
}) => {
  'sessionId': sessionId,
  'groups': groups,
  'unassigned': {
    'goingCount': unassignedGoing,
    'maybeCount': unassignedMaybe,
    'paces': unassignedPaces,
    'members': ?unassignedMembers,
  },
};

Map<String, Object?> groupPlanJson(
  String groupId, {
  List<Map<String, Object?>> paces = const [],
  List<Map<String, Object?>>? attendees,
}) => {'groupId': groupId, 'paces': paces, 'attendees': ?attendees};

/// A `…/members` item (committee tools).
Map<String, Object?> memberItemJson(
  String memberId,
  String name, {
  String status = 'active',
  List<String> roles = const [],
}) => {
  'memberId': memberId,
  'displayName': name,
  'status': status,
  'roles': roles,
};

Map<String, Object?> membersListJson(List<Map<String, Object?>> items) => {
  'items': items,
};
