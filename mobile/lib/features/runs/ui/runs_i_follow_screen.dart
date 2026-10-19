import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/util/clock_time.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/follows_repository.dart';
import '../logic/follow_resolver.dart';
import '../logic/run_feed.dart';
import '../logic/run_modes.dart';
import 'follow_widgets.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _dayName(int weekday) => _weekdayNames[(weekday - 1).clamp(0, 6)];

/// "7pm · Monday Club Run".
String followRowLabel(SeriesFollow s) => s.localStartTime.isEmpty
    ? s.title
    : '${formatClock(s.localStartTime)} · ${s.title}';

/// The line under each series, which is what makes Auto understandable.
String followStatusLine(SeriesFollow s) => switch (s.mode) {
  FollowMode.follow => 'Following',
  FollowMode.hide => 'Hidden · only shown in All runs',
  FollowMode.auto when s.usuallyComes => 'Auto: following (you usually come)',
  FollowMode.auto when isEventLikeMode(s.groupMode) =>
    'Auto: not following (choose Follow for events)',
  FollowMode.auto => 'Auto: not following (you rarely come)',
};

/// Runs I follow (`/follows`, D117): the only place follow choices are
/// edited. Every change saves on tap (no Save button); a failed write puts the
/// control back and says so. Follow all / Follow everything offer Undo.
class RunsIFollowScreen extends ConsumerStatefulWidget {
  const RunsIFollowScreen({super.key});

  @override
  ConsumerState<RunsIFollowScreen> createState() => _RunsIFollowScreenState();
}

class _RunsIFollowScreenState extends ConsumerState<RunsIFollowScreen> {
  bool _loading = true;
  Object? _loadError;

  /// Series with a write in flight; their control is disabled meanwhile.
  final _saving = <String>{};

  /// Bumped by every change, so an Undo snackbar from an earlier bulk change
  /// can tell it is stale (any later change clears the undo).
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final clubId = ref.read(activeClubIdProvider);
    if (!_loading) setState(() => _loading = true);
    Object? error;
    try {
      await ref.read(followsRepositoryProvider).refresh(clubId);
    } on Object catch (e) {
      error = e;
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  /// Runs one write: clears any pending Undo, disables [ids] while it runs,
  /// and reports a failure (the repository has already put the old value
  /// back). Returns null on failure.
  Future<T?> _write<T>(Iterable<String> ids, Future<T> Function() send) async {
    final messenger = ScaffoldMessenger.of(context);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    _generation++;
    messenger.hideCurrentSnackBar();
    setState(() => _saving.addAll(ids));
    try {
      return await send();
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ApiException.from(e).isNetworkError
                ? "That change didn't save. You're offline."
                : "That change didn't save. Try again.",
          ),
        ),
      );
      return null;
    } finally {
      if (mounted) setState(() => _saving.removeAll(ids));
    }
  }

  void _setMode(SeriesFollow s, FollowMode mode) {
    final clubId = ref.read(activeClubIdProvider);
    unawaited(
      _write(
        [s.seriesId],
        () => ref
            .read(followsRepositoryProvider)
            .setMode(clubId, s.seriesId, mode)
            .then((_) => true),
      ),
    );
  }

  /// Follow all (one day) or Follow everything, then a snackbar with Undo.
  Future<void> _followMany(List<SeriesFollow> series, String done) async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(followsRepositoryProvider);
    final ids = [for (final s in series) s.seriesId];
    final messenger = ScaffoldMessenger.of(context);
    final previous = await _write(
      ids,
      () => repo.setMany(clubId, ids, FollowMode.follow),
    );
    if (previous == null || !mounted) return;
    final generation = _generation;
    messenger.showSnackBar(
      SnackBar(
        content: Text(done),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (generation != _generation || !mounted) return;
            unawaited(_write(ids, () => repo.restore(clubId, previous)));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final follows = ref.watch(seriesFollowsProvider(clubId)).value;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final Widget body;
    if (follows == null || (follows.isEmpty && _loading)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (follows.isEmpty && _loadError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ApiException.from(_loadError!).isNetworkError
                    ? 'You need a connection to load the club runs.'
                    : "Couldn't load the club runs.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _refresh, child: const Text('Try again')),
            ],
          ),
        ),
      );
    } else {
      final days = <int, List<SeriesFollow>>{};
      for (final s in follows) {
        (days[s.weekday] ??= []).add(s);
      }
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'These choices decide what shows in My runs and which reminders '
            'you get. Auto follows runs you usually come to.',
            style: muted,
          ),
          if (follows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('No regular runs yet.', style: muted),
            ),
          for (final MapEntry(key: weekday, value: series) in days.entries) ...[
            _DayHeader(
              day: _dayName(weekday),
              onFollowAll:
                  series.every((s) => s.mode == FollowMode.follow) ||
                      series.any((s) => _saving.contains(s.seriesId))
                  ? null
                  : () => unawaited(
                      _followMany(
                        series,
                        'Following every ${_dayName(weekday)} run',
                      ),
                    ),
            ),
            for (final s in series)
              _SeriesRow(
                key: ValueKey('follow-${s.seriesId}'),
                series: s,
                onChanged: _saving.contains(s.seriesId)
                    ? null
                    : (m) => _setMode(s, m),
              ),
          ],
          if (follows.isNotEmpty) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              key: const ValueKey('followEverything'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              onPressed:
                  follows.every((s) => s.mode == FollowMode.follow) ||
                      _saving.isNotEmpty
                  ? null
                  : () =>
                        unawaited(_followMany(follows, 'Following every run')),
              child: const Text('Follow everything'),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Runs I follow')),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _refresh, child: body),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.onFollowAll});

  final String day;
  final VoidCallback? onFollowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                day.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          TextButton(
            key: ValueKey('followAll-$day'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: onFollowAll,
            child: Text('Follow all', semanticsLabel: 'Follow all $day runs'),
          ),
        ],
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.series, required this.onChanged, super.key});

  final SeriesFollow series;
  final ValueChanged<FollowMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            followRowLabel(series),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            followStatusLine(series),
            key: ValueKey('status-line-${series.seriesId}'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FollowModeControl(
            mode: series.mode,
            seriesLabel: series.title,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
