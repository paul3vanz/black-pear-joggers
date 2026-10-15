import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's one source of "now" and "today" (D87).
///
/// Cached data never changes with the date (offline-first), but what it is
/// *called* does: a run is "Today" until midnight, "5 minutes ago" turns into
/// "6 minutes ago", a finished run stops being open. Computing those once in a
/// `build` or a provider body left them stale when the app stayed in memory
/// overnight. Everything now watches the providers below, so a timer or an app
/// resume re-evaluates it, and tests override [clockProvider].
///
/// Time zone: the club's runs are club-local (`localDate` strings), but the app
/// has no club time zone setting, so "today" is the *device's* local date, as
/// `localDateString` always did. Fine while members are in the club's zone;
/// revisit if the app is white-labelled for another one (D19 notes the same).

/// `yyyy-MM-dd` for [d] in the device's local time. Compared with the
/// club-local `localDate` strings from the API.
String localDateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The source of the current time. Tests override it with a closure over a
/// variable they can move forward (like injecting `Date.now` in Jest).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The club-local date as of the last recompute. Equality is by [date], so a
/// provider watching this only rebuilds when the day actually changes.
class ClubToday {
  const ClubToday(this.now);

  /// When this was computed. Use it for date arithmetic (`now.add(days)`) only:
  /// it is not refreshed during the day. For the time of day watch [nowProvider].
  final DateTime now;

  /// `yyyy-MM-dd`, the same shape as `Session.localDate`.
  String get date => localDateString(now);

  @override
  bool operator ==(Object other) => other is ClubToday && other.date == date;

  @override
  int get hashCode => date.hashCode;
}

/// Tells [onResume] when the app returns to the foreground. A tiny
/// `WidgetsBindingObserver` (like a `visibilitychange` listener in a browser).
class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// Runs [onResume] on every app resume until the provider is disposed.
void _onResume(Ref ref, VoidCallback onResume) {
  // `ensureInitialized` is a no-op once the app (or flutter_test) has bound.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final observer = _ResumeObserver(onResume);
  binding.addObserver(observer);
  ref.onDispose(() => binding.removeObserver(observer));
}

/// Today's club-local date. Recomputed at the next local midnight (a one-shot
/// `Timer`, re-armed each time) and whenever the app resumes, which covers a
/// phone that slept through midnight (timers do not run while asleep).
final clubTodayProvider = NotifierProvider<ClubTodayNotifier, ClubToday>(
  ClubTodayNotifier.new,
);

class ClubTodayNotifier extends Notifier<ClubToday> {
  Timer? _timer;

  @override
  ClubToday build() {
    ref.onDispose(() => _timer?.cancel());
    _onResume(ref, recompute);
    final now = ref.read(clockProvider)();
    _arm(now);
    return ClubToday(now);
  }

  /// Reads the clock again. Listeners are only told if the date changed.
  void recompute() {
    final now = ref.read(clockProvider)();
    _arm(now);
    state = ClubToday(now);
  }

  void _arm(DateTime now) {
    _timer?.cancel();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    // A second of slack so the timer never wakes just before the date flips.
    _timer = Timer(
      midnight.difference(now) + const Duration(seconds: 1),
      recompute,
    );
  }
}

/// The current time, refreshed every minute and on resume, for things that
/// depend on the time of day: "5 minutes ago" and whether a run has finished.
/// Auto-disposed, so the timer only runs while a screen is watching it.
final nowProvider = NotifierProvider.autoDispose<NowNotifier, DateTime>(
  NowNotifier.new,
);

class NowNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    ref.onDispose(timer.cancel);
    _onResume(ref, refresh);
    return ref.read(clockProvider)();
  }

  void refresh() => state = ref.read(clockProvider)();
}
