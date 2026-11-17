import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/groups/data/plan_repository.dart';
import '../../features/runs/data/runs_repository.dart';
import '../auth/accounts_controller.dart';
import '../auth/session_expiry.dart';

/// Default minimum gap between two non-forced refreshes of the same thing.
const defaultRefreshThrottle = Duration(seconds: 60);

/// How often the visible Runs tab / open run page is polled while the app is in
/// the foreground (chat polls more often; runs change much less).
const runsPollInterval = Duration(seconds: 75);

/// One place that decides *when* run data is pulled from the API, so resume,
/// the gentle poll and pushes don't each hammer it. Reads still come from
/// Drift streams: a refresh just writes rows and the screens update.
///
///  * non-forced calls (resume, poll) are throttled per club/session;
///  * forced calls (push received, notification tapped) always fetch, waiting
///    for any request already in flight first (it may predate the change);
///  * the sessions call uses the repository's `since` cursor, so it is cheap.
///
/// Failures never throw (offline is normal); [onError] sees them, so a dead
/// session can be handled like everywhere else.
class RefreshCoordinator {
  RefreshCoordinator({
    required this.fetchSessions,
    required this.fetchPlan,
    DateTime Function()? now,
    this.onError,
    this.throttle = defaultRefreshThrottle,
  }) : _now = now ?? DateTime.now;

  final Future<void> Function(int clubId) fetchSessions;
  final Future<void> Function(String sessionId) fetchPlan;
  final Future<void> Function(Object error)? onError;
  final Duration throttle;
  final DateTime Function() _now;

  final _last = <String, DateTime>{};
  final _inFlight = <String, Future<void>>{};

  /// Refreshes the sessions feed for [clubId] (groups, leaders, cancellations
  /// come with it). Returns true when a request was made.
  Future<bool> refreshSessions(int clubId, {bool force = false}) =>
      _run('sessions:$clubId', () => fetchSessions(clubId), force: force);

  /// Refreshes one run's plan (the pace-group plan block).
  Future<bool> refreshPlan(String sessionId, {bool force = false}) =>
      _run('plan:$sessionId', () => fetchPlan(sessionId), force: force);

  /// Sessions feed plus the plan of [sessionId] when it is given. The plan runs
  /// after the feed, because it needs the session cached.
  Future<void> refreshSession(
    int clubId,
    String? sessionId, {
    bool force = false,
  }) async {
    await refreshSessions(clubId, force: force);
    if (sessionId != null) await refreshPlan(sessionId, force: force);
  }

  Future<bool> _run(
    String key,
    Future<void> Function() action, {
    required bool force,
  }) async {
    final pending = _inFlight[key];
    if (pending != null) {
      if (!force) {
        await pending;
        return false;
      }
      await pending; // finished (or failed) before we start the fresh one
    } else if (!force) {
      final last = _last[key];
      if (last != null && _now().difference(last) < throttle) return false;
    }
    // Stamp before the call so a failing/offline fetch is not retried in a loop.
    _last[key] = _now();
    final future = _guarded(action);
    _inFlight[key] = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight[key], future)) unawaited(_inFlight.remove(key));
    }
    return true;
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      debugPrint('Refresh failed: $e');
      await onError?.call(e);
    }
  }
}

/// Rebuilt when the account changes, so throttle state never crosses accounts.
final refreshCoordinatorProvider = Provider<RefreshCoordinator>((ref) {
  final runs = ref.watch(runsRepositoryProvider);
  final plans = ref.watch(planRepositoryProvider);
  final sub = ref.watch(activeSubProvider);
  final handleExpiry = ref.read(sessionExpiryHandlerProvider);
  return RefreshCoordinator(
    fetchSessions: runs.refreshSessions,
    fetchPlan: (id) async {
      await plans.refreshPlan(id);
    },
    onError: (e) async {
      if (sub != null) await handleExpiry(sub, e);
    },
  );
});
