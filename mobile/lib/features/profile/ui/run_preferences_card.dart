import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace.dart';
import '../../../core/units/pace_spec.dart';
import '../../groups/data/member_dtos.dart';
import '../../groups/data/run_preferences_repository.dart';
import '../../groups/ui/groups_providers.dart';
import '../../groups/ui/pace_time_field.dart';
import '../../membership/ui/membership_providers.dart';

/// "Running preferences" on the Profile tab: the units paces and distances are
/// shown in (D21) and an optional usual pace range. It shows the cached values
/// offline; saving needs a connection.
///
/// The units save as soon as they are tapped. The usual pace has its own
/// **Save** button (D88): the Profile tab is kept alive by the shell's
/// `IndexedStack`, so typed-but-unsaved numbers used to look saved when the tab
/// was revisited, while nothing had reached the server or the cache.
///
/// The form is a local copy of the cached preferences (like `useState` seeded
/// from a query). It follows the cache until the user has typed something.
class RunPreferencesCard extends ConsumerStatefulWidget {
  const RunPreferencesCard({super.key});

  @override
  ConsumerState<RunPreferencesCard> createState() => _RunPreferencesCardState();
}

/// What the two pace boxes hold: the spec (null when invalid) and any errors.
/// (A Dart 3 "record" type alias, like `type PaceCheck = {spec, ...}`.)
typedef _PaceCheck = ({PaceSpec? spec, String? fromError, String? toError});

class _RunPreferencesCardState extends ConsumerState<RunPreferencesCard> {
  final _from = PaceTimeController();
  final _to = PaceTimeController();
  DistUnit _paceUnit = DistUnit.mi;
  DistUnit _distanceUnit = DistUnit.mi;
  bool _saving = false;
  bool _justSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(runPreferencesProvider(ref.read(activeClubIdProvider)))
        .value;
    if (cached != null) _seed(cached);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _seed(PreferencesDto p) {
    _paceUnit = p.paceUnit;
    _distanceUnit = p.distanceUnit;
    _seedPace(p.usualPace);
  }

  void _seedPace(PaceSpec spec) {
    _from.text = spec.fastest?.format() ?? '';
    _to.text = spec is PaceRange ? spec.slow.format() : '';
  }

  /// True when the boxes still show exactly what [p] holds (nothing typed).
  bool _showsPace(PreferencesDto p) {
    final spec = p.usualPace;
    return p.paceUnit == _paceUnit &&
        _from.text == (spec.fastest?.format() ?? '') &&
        _to.text == (spec is PaceRange ? spec.slow.format() : '');
  }

  void _edited() => setState(() {
    _justSaved = false;
    _error = null;
  });

  /// Reads the boxes without touching state, so build can enable or disable
  /// Save from it. Empty boxes are a valid "no pace".
  _PaceCheck _check() {
    final fromText = _from.text.trim();
    final toText = _to.text.trim();
    if (fromText.isEmpty && toText.isEmpty) {
      return (spec: const NoPace(), fromError: null, toError: null);
    }
    String? fromErr;
    String? toErr;
    final from = fromText.isEmpty ? null : Pace.tryParse(fromText, _paceUnit);
    final to = toText.isEmpty ? null : Pace.tryParse(toText, _paceUnit);
    if (fromText.isEmpty) {
      fromErr = 'Enter your faster pace';
    } else if (from == null) {
      fromErr = 'Enter minutes, like 9 (seconds are optional)';
    } else if (!from.isWithinServerRange) {
      fromErr = 'Between 3:00 and 30:00';
    }
    if (toText.isNotEmpty) {
      if (to == null) {
        toErr = 'Enter minutes, like 10 (seconds are optional)';
      } else if (!to.isWithinServerRange) {
        toErr = 'Between 3:00 and 30:00';
      } else if (from != null && to.seconds < from.seconds) {
        toErr = 'Must be the same or slower than From';
      }
    }
    if (fromErr != null) fromErr = paceTimeError(_from, fromErr);
    if (toErr != null) toErr = paceTimeError(_to, toErr);
    if (fromErr != null || toErr != null) {
      return (spec: null, fromError: fromErr, toError: toErr);
    }
    final f = from!;
    final spec = (to == null || to.seconds == f.seconds)
        ? SinglePace(f)
        : PaceRange(f, to);
    return (spec: spec, fromError: null, toError: null);
  }

  /// The same spec in another unit.
  PaceSpec _convert(PaceSpec spec, DistUnit unit) => switch (spec) {
    NoPace() => spec,
    SinglePace(:final pace) => SinglePace(pace.convertTo(unit)),
    PaceRange(:final fast, :final slow) => PaceRange(
      fast.convertTo(unit),
      slow.convertTo(unit),
    ),
  };

  /// The cached (saved) preferences right now.
  PreferencesDto get _saved =>
      ref.read(runPreferencesProvider(ref.read(activeClubIdProvider))).value ??
      PreferencesDto.defaults;

  /// PUTs the three values. Returns the saved copy, or null after recording
  /// why it failed (offline, validation) in [_error].
  Future<PreferencesDto?> _put({
    required DistUnit paceUnit,
    required DistUnit distanceUnit,
    required PaceSpec pace,
  }) async {
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runPreferencesRepositoryProvider);
    setState(() {
      _saving = true;
      _justSaved = false;
      _error = null;
    });
    try {
      // `repo.save` writes the Drift row, which every screen watches through
      // `runPreferencesProvider`, so nothing else needs telling.
      final saved = await repo.save(
        clubId,
        paceUnit: paceUnit,
        distanceUnit: distanceUnit,
        usualPace: pace,
      );
      // Cached plans name people with their pace; refetch the ones in use.
      ref.invalidate(planLoadProvider);
      if (mounted) setState(() => _saving = false);
      return saved;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.isNetworkError
              ? 'You need a connection to save your preferences.'
              : e.message;
        });
      }
      return null;
    }
  }

  Future<void> _savePace() async {
    final spec = _check().spec;
    if (spec == null || _saving) return;
    final saved = await _put(
      paceUnit: _paceUnit,
      distanceUnit: _saved.distanceUnit,
      pace: spec,
    );
    if (saved == null || !mounted) return;
    setState(() {
      _seedPace(saved.usualPace);
      _justSaved = true;
    });
  }

  /// Empties the boxes and, when a pace is stored, removes it straight away.
  Future<void> _clearPace() async {
    _from.clear();
    _to.clear();
    if (_saved.usualPace.isNone) return _edited();
    final saved = await _put(
      paceUnit: _paceUnit,
      distanceUnit: _saved.distanceUnit,
      pace: const NoPace(),
    );
    if (!mounted) return;
    setState(() {
      if (saved == null) {
        _seedPace(_saved.usualPace); // show what is really stored again
      } else {
        _justSaved = true;
      }
    });
  }

  /// Switching min/mile <-> min/km converts what is typed and the stored
  /// range, and saves at once (the server clears a range when only the unit
  /// changes, so the converted range is sent too).
  Future<void> _changePaceUnit(DistUnit unit) async {
    if (unit == _paceUnit || _saving) return;
    final oldUnit = _paceUnit;
    final oldFrom = _from.text;
    final oldTo = _to.text;
    for (final c in [_from, _to]) {
      final p = Pace.tryParse(c.text, _paceUnit);
      if (p != null) c.text = p.convertTo(unit).format();
    }
    setState(() => _paceUnit = unit);
    final saved = _saved;
    final done = await _put(
      paceUnit: unit,
      distanceUnit: saved.distanceUnit,
      pace: _convert(saved.usualPace, unit),
    );
    if (done == null && mounted) {
      setState(() {
        _paceUnit = oldUnit;
        _from.text = oldFrom;
        _to.text = oldTo;
      });
      _showSnack(_error);
    }
  }

  Future<void> _changeDistanceUnit(DistUnit unit) async {
    if (unit == _distanceUnit || _saving) return;
    final old = _distanceUnit;
    setState(() => _distanceUnit = unit);
    final saved = _saved;
    final done = await _put(
      paceUnit: saved.paceUnit,
      distanceUnit: unit,
      pace: saved.usualPace,
    );
    if (done == null && mounted) {
      setState(() => _distanceUnit = old);
      _showSnack(_error);
    }
  }

  void _showSnack(String? message) {
    if (message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clubId = ref.watch(activeClubIdProvider);
    final saved =
        ref.watch(runPreferencesProvider(clubId)).value ??
        PreferencesDto.defaults;
    // Follow the cache (a refresh, another device) unless the user has typed.
    ref.listen(runPreferencesProvider(clubId), (prev, next) {
      final p = next.value;
      if (p == null || _saving) return;
      final before = prev?.value ?? PreferencesDto.defaults;
      if (_showsPace(before) || p.paceUnit != _paceUnit) {
        setState(() => _seed(p));
      } else {
        setState(() => _distanceUnit = p.distanceUnit);
      }
    });

    final check = _check();
    final typed = !_from.isEmpty || !_to.isEmpty;
    final changed = check.spec != null && check.spec != saved.usualPace;
    final canSave = changed && !_saving;
    // "Enter your faster pace" only makes sense once something is typed.
    final fromError = typed ? check.fromError : null;
    final toError = typed ? check.toError : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Running preferences', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Paces and distances in the app are shown in these units.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('Pace', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<DistUnit>(
              key: const ValueKey('pace-unit'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DistUnit.mi, label: Text('min/mile')),
                ButtonSegment(value: DistUnit.km, label: Text('min/km')),
              ],
              selected: {_paceUnit},
              onSelectionChanged: (s) => unawaited(_changePaceUnit(s.first)),
            ),
            const SizedBox(height: 16),
            Text('Distance', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<DistUnit>(
              key: const ValueKey('distance-unit'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DistUnit.mi, label: Text('Miles')),
                ButtonSegment(value: DistUnit.km, label: Text('Kilometres')),
              ],
              selected: {_distanceUnit},
              onSelectionChanged: (s) =>
                  unawaited(_changeDistanceUnit(s.first)),
            ),
            const SizedBox(height: 16),
            Text(
              'My usual pace range (optional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Helps leaders see who is coming. Press Save to keep it; '
              'Clear removes it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            PaceTimeField(
              controller: _from,
              keyPrefix: 'pace-from',
              label: 'Faster end',
              unit: _paceUnit,
              errorText: fromError,
              onChanged: _edited,
            ),
            const SizedBox(height: 12),
            PaceTimeField(
              controller: _to,
              keyPrefix: 'pace-to',
              label: 'Slower end',
              unit: _paceUnit,
              errorText: toError,
              onChanged: _edited,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  key: const ValueKey('clear-pace'),
                  onPressed: _saving || (!typed && saved.usualPace.isNone)
                      ? null
                      : () => unawaited(_clearPace()),
                  child: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('save-prefs'),
                  // The theme's full-width minimum is infinite inside a Row,
                  // which stops the button laying out (and drawing) at all.
                  onPressed: canSave ? () => unawaited(_savePace()) : null,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  key: const ValueKey('pace-error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            else if (_justSaved)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  key: const ValueKey('pace-saved'),
                  children: [
                    const Icon(Icons.check, size: 16),
                    const SizedBox(width: 4),
                    Text('Saved', style: theme.textTheme.bodySmall),
                  ],
                ),
              )
            else if (changed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Not saved yet',
                  key: const ValueKey('pace-unsaved'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
