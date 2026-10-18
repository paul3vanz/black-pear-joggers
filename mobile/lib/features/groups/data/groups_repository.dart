import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/json.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/distance.dart';
import '../../../core/units/pace_spec.dart';
import 'group_dtos.dart';
import 'session_local.dart';
import 'summary_dtos.dart';

part 'groups_repository.g.dart';

/// Group and leader writes. They are online-only (D16, D19): each throws
/// `ApiException` when offline or refused (403 `forbidden`, 409
/// `session_cancelled` / `session_past`, 422 `validation_failed`...). On success
/// the returned group is merged into the cached session's `groupsJson` and the
/// stored summary counts are recomputed as well as possible; the next sessions
/// refresh is authoritative.
class GroupsRepository {
  GroupsRepository(
    this._db,
    this._dio, {
    String Function()? newId,
    DateTime Function()? now,
  }) : _newId = newId ?? (() => const Uuid().v4()),
       _now = now ?? DateTime.now,
       _local = SessionLocalStore(_db);

  final AppDatabase _db;
  final Dio _dio;
  final String Function() _newId;
  final DateTime Function() _now;
  final SessionLocalStore _local;

  /// The cached embedded groups of a session, fastest pace first.
  Stream<List<Group>> watchGroups(String sessionId) =>
      _local.watchGroups(sessionId);

  Future<int> _clubOf(String sessionId) async {
    final session = await _local.session(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId is not cached');
    }
    return session.clubId;
  }

  Future<String?> _me(int clubId) async => (await (_db.select(
    _db.memberships,
  )..where((m) => m.clubId.equals(clubId))).getSingleOrNull())?.memberId;

  Map<String, Object?> _fields({
    required String kind,
    String? label,
    String? description,
    required PaceSpec pace,
    Distance? distance,
  }) => {
    'kind': kind,
    'label': label,
    'description': description,
    ...pace.toJson(),
    'distanceValue': distance?.value,
    'distanceUnit': distance?.unit.code,
  };

  Future<Group> _merge(int clubId, Response<Object?> response) async {
    final group = Group.fromJson(jsonObject(response));
    await _local.mergeGroup(group, myMemberId: await _me(clubId));
    return group;
  }

  /// Mirrors the server rule (D30): leading a group (creating it with `lead`,
  /// or joining as a leader) also marks the caller going in it. The merged
  /// group already counts them (the server counted), so only the session
  /// summary and any other group they were in are adjusted. A per-run pace
  /// override is kept. Stepping down does the reverse (D109): it removes them
  /// from the group again, see [withdrawAsLeader].
  Future<void> _markLeaderGoing(int clubId, Group group) async {
    final sessionId = group.sessionId;
    final existing = await (_db.select(
      _db.myAttendance,
    )..where((a) => a.sessionId.equals(sessionId))).getSingleOrNull();
    await _db
        .into(_db.myAttendance)
        .insertOnConflictUpdate(
          MyAttendanceCompanion.insert(
            sessionId: sessionId,
            clubId: clubId,
            status: 'going',
            groupId: Value(group.id),
            paceUnit: Value(existing?.paceUnit),
            paceFromS: Value(existing?.paceFromS),
            paceToS: Value(existing?.paceToS),
            pending: const Value(false),
            updatedAt: _now(),
          ),
        );
    await _local.applyAttendance(
      sessionId,
      status: 'going',
      groupId: group.id,
      serverCountedGroupId: group.id,
    );
  }

  /// Creates a group in [sessionId]. With [lead] the caller becomes its leader
  /// (any linked member); a leaderless group needs the committee or the
  /// coordinator. The client UUID makes a replay idempotent.
  Future<Group> createGroup(
    String sessionId, {
    String kind = 'run',
    String? label,
    String? description,
    PaceSpec pace = const NoPace(),
    Distance? distance,
    bool lead = true,
    String? id,
  }) async {
    final clubId = await _clubOf(sessionId);
    final group = await _merge(
      clubId,
      await guardApi(
        () => _dio.post<Object?>(
          '/app/clubs/$clubId/sessions/$sessionId/groups',
          data: {
            'id': id ?? _newId(),
            ..._fields(
              kind: kind,
              label: label,
              description: description,
              pace: pace,
              distance: distance,
            ),
            'lead': lead,
          },
        ),
      ),
    );
    if (lead) await _markLeaderGoing(clubId, group);
    return group;
  }

  /// Adds an event (kind `event`) to an `events` run, by any linked member
  /// (Phase 8): a club event location ([locationId]) or a free-text [label].
  /// The server marks the caller going in it and de-duplicates by location:
  /// a 200 (not 201) means that event already existed, so [existed] is true
  /// and the caller simply joined it (D78). No pace and no `lead` are sent
  /// (events have none). Online-only like other group writes.
  Future<({Group group, bool existed})> addEventGroup(
    String sessionId, {
    String? locationId,
    String? label,
    String? id,
  }) async {
    final clubId = await _clubOf(sessionId);
    final response = await guardApi(
      () => _dio.post<Object?>(
        '/app/clubs/$clubId/sessions/$sessionId/groups',
        data: {
          'id': id ?? _newId(),
          'kind': 'event',
          'locationId': ?locationId, // `?x` in a map literal: only if not null
          'label': ?label,
        },
      ),
    );
    final group = await _merge(clubId, response);
    await _markLeaderGoing(clubId, group); // same effect: going in [group]
    return (group: group, existed: response.statusCode == 200);
  }

  /// Edits a group (its leaders, the coordinator or the committee). Every
  /// field is sent, so a pace or distance left out is cleared.
  Future<Group> updateGroup(
    String sessionId,
    String groupId, {
    String kind = 'run',
    String? label,
    String? description,
    PaceSpec pace = const NoPace(),
    Distance? distance,
  }) async {
    final clubId = await _clubOf(sessionId);
    return _merge(
      clubId,
      await guardApi(
        () => _dio.patch<Object?>(
          '/app/clubs/$clubId/groups/$groupId',
          data: _fields(
            kind: kind,
            label: label,
            description: description,
            pace: pace,
            distance: distance,
          ),
        ),
      ),
    );
  }

  /// Deletes a group; its attendees become unassigned.
  Future<void> deleteGroup(String sessionId, String groupId) async {
    final clubId = await _clubOf(sessionId);
    await guardApi(
      () => _dio.delete<Object?>('/app/clubs/$clubId/groups/$groupId'),
    );
    await _local.removeGroup(sessionId, groupId, myMemberId: await _me(clubId));
    await (_db.update(_db.myAttendance)..where(
          (a) => a.sessionId.equals(sessionId) & a.groupId.equals(groupId),
        ))
        .write(const MyAttendanceCompanion(groupId: Value(null)));
  }

  /// The caller joins [groupId] as `leader`, `co_leader` or `backmarker`.
  Future<Group> joinAsLeader(
    String sessionId,
    String groupId, {
    String role = 'leader',
  }) async {
    final clubId = await _clubOf(sessionId);
    final group = await _merge(
      clubId,
      await guardApi(
        () => _dio.post<Object?>(
          '/app/clubs/$clubId/groups/$groupId/leaders',
          data: {'role': role},
        ),
      ),
    );
    await _markLeaderGoing(clubId, group);
    return group;
  }

  /// The caller steps down as a leader of [groupId] (D109, replacing D30's
  /// "stay going in the group"). The server also removes them from the group
  /// (still going, or `not_going` when [notGoing]) and soft-deletes a group they
  /// created that nobody else joined: that response carries `deletedAt`. Mirror
  /// both locally: drop the deleted group, or merge the returned one, then
  /// clear the caller's group and set their status.
  Future<Group> withdrawAsLeader(
    String sessionId,
    String groupId, {
    bool notGoing = false,
  }) async {
    final clubId = await _clubOf(sessionId);
    final group = Group.fromJson(
      jsonObject(
        await guardApi(
          () => _dio.delete<Object?>(
            '/app/clubs/$clubId/groups/$groupId/leaders/me',
            data: {'notGoing': notGoing},
          ),
        ),
      ),
    );
    final me = await _me(clubId);
    if (group.isDeleted) {
      await _local.removeGroup(sessionId, groupId, myMemberId: me);
    } else {
      await _local.mergeGroup(group, myMemberId: me);
    }
    await _leaveGroupLocally(
      clubId,
      sessionId,
      notGoing: notGoing,
      // A kept group's counts came from the server and already exclude me.
      serverCountedGroupId: group.isDeleted ? null : group.id,
    );
    return group;
  }

  /// After stepping down: the caller's row has no group (their per-run pace
  /// is kept) and is still going, or `not_going` when [notGoing]. Also moves
  /// the cached summary (`myGroupId` null, counts).
  Future<void> _leaveGroupLocally(
    int clubId,
    String sessionId, {
    required bool notGoing,
    String? serverCountedGroupId,
  }) async {
    final existing = await (_db.select(
      _db.myAttendance,
    )..where((a) => a.sessionId.equals(sessionId))).getSingleOrNull();
    final cached = decodeSummary(
      (await _local.session(sessionId))?.summaryJson,
    );
    // Still going (or whatever they answered); nothing to move without an answer.
    final status = notGoing
        ? 'not_going'
        : (existing?.status ?? cached?.myStatus);
    if (status == null) return;
    if (existing != null || notGoing) {
      await _db
          .into(_db.myAttendance)
          .insertOnConflictUpdate(
            MyAttendanceCompanion.insert(
              sessionId: sessionId,
              clubId: clubId,
              status: status,
              groupId: const Value(null),
              paceUnit: Value(existing?.paceUnit),
              paceFromS: Value(existing?.paceFromS),
              paceToS: Value(existing?.paceToS),
              pending: const Value(false),
              updatedAt: _now(),
            ),
          );
    }
    await _local.applyAttendance(
      sessionId,
      status: status,
      groupId: null,
      serverCountedGroupId: serverCountedGroupId,
    );
  }
}

@Riverpod(keepAlive: true)
GroupsRepository groupsRepository(Ref ref) => GroupsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(apiClientProvider),
);
