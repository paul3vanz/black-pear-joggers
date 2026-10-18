import 'package:flutter/foundation.dart';

/// What the "Something's not working" banner shows (D102).
@immutable
class HealthState {
  const HealthState({this.unhealthy = false, this.reason});

  final bool unhealthy;

  /// Short machine-ish reason for the report, e.g. `5xx x4`.
  final String? reason;

  static const ok = HealthState();

  @override
  bool operator ==(Object other) =>
      other is HealthState &&
      other.unhealthy == unhealthy &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(unhealthy, reason);
}

/// Decides whether "everything is failing", from a stream of outcomes. Pure Dart
/// with an injectable clock, so the thresholds are unit-tested without widgets.
///
/// It only trips for failures that are the APP's problem:
/// * [apiThreshold] consecutive requests, all inside [window], that failed with the
///   SAME class (`5xx`, a local `TypeError`, ...). A success resets the run. Plain
///   offline (network errors), 401s and normal 4xx answers are never reported here.
/// * [localThreshold] local exceptions (TypeError, database errors) inside
///   [window]. Only [reportLocalOk] or [reset] clears these, not an API success:
///   "the request worked but the screen still can't read it" is exactly the case
///   this exists to catch.
class HealthTracker {
  HealthTracker({
    DateTime Function()? now,
    this.window = const Duration(minutes: 2),
    this.apiThreshold = 4,
    this.localThreshold = 3,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration window;
  final int apiThreshold;
  final int localThreshold;

  final _state = ValueNotifier<HealthState>(HealthState.ok);
  final _api = <(DateTime, String)>[];
  final _local = <DateTime>[];

  ValueListenable<HealthState> get listenable => _state;
  HealthState get state => _state.value;

  /// A request failed in a way that says something is broken, not just "offline".
  void reportApiFailure(String errorClass) {
    _api.add((_now(), errorClass));
    _evaluate();
  }

  /// Any request succeeded: the API side is fine again.
  void reportApiSuccess() {
    _api.clear();
    _evaluate();
  }

  /// A local exception (TypeError, database error) was seen.
  void reportLocalError() {
    _local.add(_now());
    _evaluate();
  }

  /// The database answered a query: local errors so far are no longer "consecutive".
  void reportLocalOk() {
    _local.clear();
    _evaluate();
  }

  /// After a reset or when the user dismisses the banner.
  void reset() {
    _api.clear();
    _local.clear();
    _set(HealthState.ok);
  }

  void _set(HealthState s) {
    if (_state.value != s) _state.value = s;
  }

  /// Recomputes the state from what is still inside [window].
  void _evaluate() {
    final now = _now();
    _api.removeWhere((e) => now.difference(e.$1) > window);
    _local.removeWhere((t) => now.difference(t) > window);
    if (_api.isNotEmpty) {
      // The run of identical classes at the end of the list.
      final last = _api.last.$2;
      var run = 0;
      for (var i = _api.length - 1; i >= 0 && _api[i].$2 == last; i--) {
        run++;
      }
      if (run >= apiThreshold) {
        return _set(HealthState(unhealthy: true, reason: '$last x$run'));
      }
    }
    if (_local.length >= localThreshold) {
      return _set(
        HealthState(unhealthy: true, reason: 'local errors x${_local.length}'),
      );
    }
    _set(HealthState.ok);
  }
}
