import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/db/app_database.dart';
import '../../../core/units/dist_unit.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/attendance_repository.dart';
import '../data/group_dtos.dart';
import '../data/groups_repository.dart';
import '../data/last_group_store.dart';
import '../data/member_dtos.dart';
import '../data/plan_dtos.dart';
import '../data/plan_repository.dart';
import '../data/run_preferences_repository.dart';
import '../data/summary_dtos.dart';
import '../data/session_local.dart';

// Hand-written (not @riverpod): riverpod_generator can't see Drift's row types.

/// The groups embedded in a cached session, fastest pace first.
final sessionGroupsProvider = StreamProvider.family<List<Group>, String>(
  (ref, sessionId) =>
      ref.watch(groupsRepositoryProvider).watchGroups(sessionId),
);

/// The caller's `summary` block for a cached session (null for an older
/// payload without it).
final sessionSummaryProvider = StreamProvider.family<SessionSummary?, String>(
  (ref, sessionId) =>
      SessionLocalStore(ref.watch(appDatabaseProvider)).watchSummary(sessionId),
);

/// The caller's own response for a session, including `pending`.
final myAttendanceProvider = StreamProvider.family<MyAttendanceRow?, String>(
  (ref, sessionId) =>
      ref.watch(attendanceRepositoryProvider).watchMyAttendance(sessionId),
);

/// The cached plan of a session (null until fetched with
/// `PlanRepository.fetchPlan`).
final sessionPlanProvider = StreamProvider.family<SessionPlan?, String>(
  (ref, sessionId) => ref.watch(planRepositoryProvider).watchPlan(sessionId),
);

/// The caller's cached running preferences for a club (defaults when none).
final runPreferencesProvider = StreamProvider.family<PreferencesDto, int>(
  (ref, clubId) => ref.watch(runPreferencesRepositoryProvider).watch(clubId),
);

/// The viewer's units, used to render `PaceSpec` / `Distance`.
class UnitPrefs {
  const UnitPrefs({
    this.paceUnit = DistUnit.mi,
    this.distanceUnit = DistUnit.mi,
  });

  final DistUnit paceUnit;
  final DistUnit distanceUnit;

  @override
  bool operator ==(Object other) =>
      other is UnitPrefs &&
      other.paceUnit == paceUnit &&
      other.distanceUnit == distanceUnit;

  @override
  int get hashCode => Object.hash(paceUnit, distanceUnit);
}

/// The pace and distance units for the active club. `mi`/`mi` while loading,
/// signed out or when nothing is cached.
final unitPrefsProvider = Provider<UnitPrefs>((ref) {
  if (ref.watch(activeSubProvider) == null) return const UnitPrefs();
  final clubId = ref.watch(activeClubIdProvider);
  final prefs = ref.watch(runPreferencesProvider(clubId)).value;
  if (prefs == null) return const UnitPrefs();
  return UnitPrefs(paceUnit: prefs.paceUnit, distanceUnit: prefs.distanceUnit);
});

/// Fetches the caller's server-held attendance row once when the run is open
/// and the summary says they responded but this device has no row (fresh
/// install). Watch it from the session detail screen. Errors are swallowed by
/// the repository.
final attendanceBackfillProvider = FutureProvider.autoDispose
    .family<void, String>((ref, sessionId) {
      // Re-run when the server's idea of "I have responded" changes.
      ref.watch(
        sessionSummaryProvider(sessionId).select((s) => s.value?.myStatus),
      );
      return ref
          .read(attendanceRepositoryProvider)
          .backfillMyAttendance(sessionId);
    });

/// How the last plan fetch went: [offline] means the cached plan is shown.
class PlanLoad {
  const PlanLoad({this.offline = false, this.fetchedAt});

  final bool offline;

  /// When the cached plan was fetched, for "Updated 5 minutes ago".
  final DateTime? fetchedAt;
}

/// Fetches a session's plan (on open, and again when invalidated by
/// pull-to-refresh or a response). The data itself is read from
/// [sessionPlanProvider]; this only reports progress, offline and errors, so
/// a failure never blocks the screen.
final planLoadProvider = FutureProvider.autoDispose.family<PlanLoad, String>((
  ref,
  sessionId,
) async {
  final repo = ref.read(planRepositoryProvider);
  final result = await repo.refreshPlan(sessionId);
  return PlanLoad(
    offline: result.offline,
    fetchedAt: await repo.cachedAt(sessionId),
  );
});

final lastGroupStoreProvider = Provider<LastGroupStore>(
  (ref) => LastGroupStore(ref.watch(appDatabaseProvider)),
);

/// The member's last group for a session's series (or overall), for
/// pre-filling the editor and "Same as last time". Invalidate after
/// `rememberLastGroup`.
final lastGroupSpecProvider = FutureProvider.autoDispose
    .family<LastGroupSpec?, String>((ref, sessionId) async {
      final session = await ref.watch(sessionProvider(sessionId).future);
      if (session == null) return null;
      return ref
          .read(lastGroupStoreProvider)
          .read(session.clubId, session.seriesId);
    });

/// Remembers [group] (just created by the member to lead) as their last one.
Future<void> rememberLastGroup(
  LastGroupStore store,
  Session session,
  Group group,
) => store.write(
  session.clubId,
  session.seriesId,
  LastGroupSpec.fromGroup(group),
);
