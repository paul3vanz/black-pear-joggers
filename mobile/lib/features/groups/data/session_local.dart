import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'group_dtos.dart';
import 'summary_dtos.dart';

/// Local-only edits of a cached session's embedded groups and summary
/// (`groupsJson` / `summaryJson`). Repositories use it to reflect their own
/// writes straight away; the next sessions refresh is authoritative and
/// overwrites whatever this computed.
class SessionLocalStore {
  SessionLocalStore(this._db);

  final AppDatabase _db;

  Future<Session?> session(String id) => (_db.select(
    _db.sessions,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  /// The embedded groups of a session, sorted by pace then sort order. Empty
  /// for an unknown session or an older payload without groups.
  Stream<List<Group>> watchGroups(String sessionId) =>
      (_db.select(
        _db.sessions,
      )..where((s) => s.id.equals(sessionId))).watchSingleOrNull().map(
        (row) => row == null
            ? const <Group>[]
            : sortGroups(decodeGroups(row.groupsJson)),
      );

  Stream<SessionSummary?> watchSummary(String sessionId) =>
      (_db.select(_db.sessions)..where((s) => s.id.equals(sessionId)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : decodeSummary(row.summaryJson));

  Future<void> _write(
    String sessionId, {
    List<Group>? groups,
    SessionSummary? summary,
  }) => (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId))).write(
    SessionsCompanion(
      groupsJson: groups == null
          ? const Value.absent()
          : Value(encodeGroups(groups)),
      summaryJson: summary == null
          ? const Value.absent()
          : Value(encodeSummary(summary)),
    ),
  );

  /// Puts [group] (new or edited) into its session and recomputes the group
  /// and leader counts. [myMemberId] keeps `myLeading` right.
  Future<void> mergeGroup(Group group, {String? myMemberId}) async {
    final row = await session(group.sessionId);
    if (row == null) return;
    final groups = decodeGroups(row.groupsJson);
    final i = groups.indexWhere((g) => g.id == group.id);
    if (i >= 0) {
      groups[i] = group;
    } else {
      groups.add(group);
    }
    await _write(
      group.sessionId,
      groups: groups,
      summary: _recount(decodeSummary(row.summaryJson), groups, myMemberId),
    );
  }

  /// Removes a deleted group. Anyone assigned to it becomes unassigned.
  Future<void> removeGroup(
    String sessionId,
    String groupId, {
    String? myMemberId,
  }) async {
    final row = await session(sessionId);
    if (row == null) return;
    final groups = decodeGroups(row.groupsJson)
      ..removeWhere((g) => g.id == groupId);
    var summary = _recount(decodeSummary(row.summaryJson), groups, myMemberId);
    if (summary.myGroupId == groupId) {
      summary = summary.copyWith(clearMyGroup: true);
    }
    await _write(sessionId, groups: groups, summary: summary);
  }

  SessionSummary _recount(
    SessionSummary? old,
    List<Group> groups,
    String? myMemberId,
  ) {
    final leaders = {
      for (final g in groups) ...g.leaders.map((l) => l.memberId),
    };
    return (old ?? const SessionSummary()).copyWith(
      groupCount: groups.length,
      leaderCount: leaders.length,
      myLeading: myMemberId == null ? null : leaders.contains(myMemberId),
    );
  }

  /// Moves the caller's response in the cached session: adjusts the going and
  /// maybe counts (session and group) from the old [SessionSummary.myStatus] /
  /// `myGroupId` to [status] / [groupId], and sets them. A null [status] clears
  /// the response (no row on the server).
  /// [serverCountedGroupId] names a group whose cached counts already include
  /// this response (the server just returned it), so it is left alone.
  Future<void> applyAttendance(
    String sessionId, {
    required String? status,
    String? groupId,
    String? serverCountedGroupId,
  }) async {
    final row = await session(sessionId);
    if (row == null) return;
    final old = decodeSummary(row.summaryJson) ?? const SessionSummary();
    final newGroup = status == null || status == 'not_going' ? null : groupId;
    if (old.myStatus == status && old.myGroupId == newGroup) return;
    var going = old.goingCount;
    var maybe = old.maybeCount;
    if (old.myStatus == 'going') going--;
    if (old.myStatus == 'maybe') maybe--;
    if (status == 'going') going++;
    if (status == 'maybe') maybe++;
    final groups = decodeGroups(row.groupsJson);
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      var gg = g.goingCount;
      var gm = g.maybeCount;
      if (g.id == serverCountedGroupId) continue;
      if (g.id == old.myGroupId) {
        if (old.myStatus == 'going') gg--;
        if (old.myStatus == 'maybe') gm--;
      }
      if (g.id == newGroup) {
        if (status == 'going') gg++;
        if (status == 'maybe') gm++;
      }
      if (gg != g.goingCount || gm != g.maybeCount) {
        groups[i] = g.copyWith(
          goingCount: gg < 0 ? 0 : gg,
          maybeCount: gm < 0 ? 0 : gm,
        );
      }
    }
    await _write(
      sessionId,
      groups: row.groupsJson == null ? null : groups,
      summary: SessionSummary(
        groupCount: old.groupCount,
        leaderCount: old.leaderCount,
        goingCount: going < 0 ? 0 : going,
        maybeCount: maybe < 0 ? 0 : maybe,
        myStatus: status,
        myGroupId: newGroup,
        myLeading: old.myLeading,
      ),
    );
  }
}

/// Groups ordered fastest pace first, groups without a pace last (by sort order).
List<Group> sortGroups(List<Group> groups) {
  final sorted = [...groups];
  sorted.sort((a, b) {
    final pa = a.sortSecPerKm;
    final pb = b.sortSecPerKm;
    if (pa != null && pb != null) {
      final c = pa.compareTo(pb);
      if (c != 0) return c;
    } else if (pa != null) {
      return -1;
    } else if (pb != null) {
      return 1;
    }
    return a.sortOrder.compareTo(b.sortOrder);
  });
  return sorted;
}
