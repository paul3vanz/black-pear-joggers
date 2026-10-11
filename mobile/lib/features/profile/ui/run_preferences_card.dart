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
/// The form is a local copy of the cached preferences (like `useState` seeded
/// from a query). It re-seeds from the cache until the user starts editing.
class RunPreferencesCard extends ConsumerStatefulWidget {
  const RunPreferencesCard({super.key});

  @override
  ConsumerState<RunPreferencesCard> createState() => _RunPreferencesCardState();
}

class _RunPreferencesCardState extends ConsumerState<RunPreferencesCard> {
  final _from = PaceTimeController();
  final _to = PaceTimeController();
  DistUnit _paceUnit = DistUnit.mi;
  DistUnit _distanceUnit = DistUnit.mi;
  bool _dirty = false;
  bool _saving = false;
  String? _fromError;
  String? _toError;

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
    final spec = p.usualPace;
    _from.text = spec.fastest?.format() ?? '';
    _to.text = spec is PaceRange ? spec.slow.format() : '';
  }

  void _edited() => setState(() {
    _dirty = true;
    _fromError = null;
    _toError = null;
  });

  /// Switching min/mile <-> min/km converts what is already typed, because the
  /// range is entered in the chosen pace unit.
  void _changePaceUnit(DistUnit unit) {
    if (unit == _paceUnit) return;
    for (final c in [_from, _to]) {
      final p = Pace.tryParse(c.text, _paceUnit);
      if (p != null) c.text = p.convertTo(unit).format();
    }
    _paceUnit = unit;
    _edited();
  }

  /// Returns the spec, or null (after showing field errors) if invalid.
  PaceSpec? _validate() {
    final fromText = _from.text.trim();
    final toText = _to.text.trim();
    if (fromText.isEmpty && toText.isEmpty) return const NoPace();
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
      setState(() {
        _fromError = fromErr;
        _toError = toErr;
      });
      return null;
    }
    final f = from!;
    if (to == null || to.seconds == f.seconds) return SinglePace(f);
    return PaceRange(f, to);
  }

  Future<void> _save() async {
    final spec = _validate();
    if (spec == null) return;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runPreferencesRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    String message;
    try {
      final saved = await repo.save(
        clubId,
        paceUnit: _paceUnit,
        distanceUnit: _distanceUnit,
        usualPace: spec,
      );
      _dirty = false;
      if (mounted) _seed(saved);
      message = 'Running preferences saved';
    } on ApiException catch (e) {
      message = e.isNetworkError
          ? 'You need a connection to save your preferences.'
          : e.message;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clubId = ref.watch(activeClubIdProvider);
    // Follow the cache (a refresh, another save) until the user edits.
    ref.listen(runPreferencesProvider(clubId), (_, next) {
      final p = next.value;
      if (p != null && !_dirty) setState(() => _seed(p));
    });

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
              onSelectionChanged: (s) => _changePaceUnit(s.first),
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
              onSelectionChanged: (s) => setState(() {
                _distanceUnit = s.first;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'My usual pace range (optional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Helps leaders see who is coming. Leave both empty for none.',
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
              errorText: _fromError,
              onChanged: _edited,
            ),
            const SizedBox(height: 12),
            PaceTimeField(
              controller: _to,
              keyPrefix: 'pace-to',
              label: 'Slower end',
              unit: _paceUnit,
              errorText: _toError,
              onChanged: _edited,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  key: const ValueKey('clear-pace'),
                  onPressed: _from.text.isEmpty && _to.text.isEmpty
                      ? null
                      : () {
                          _from.clear();
                          _to.clear();
                          _edited();
                        },
                  child: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('save-prefs'),
                  onPressed: _saving ? null : () => unawaited(_save()),
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
          ],
        ),
      ),
    );
  }
}
