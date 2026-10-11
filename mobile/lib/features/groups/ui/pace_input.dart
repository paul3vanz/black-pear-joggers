import 'package:flutter/material.dart';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace.dart';
import '../../../core/units/pace_spec.dart';
import 'pace_time_field.dart';

/// Which kind of pace the user is entering.
enum PaceMode { none, single, range }

/// The result of checking the pace fields: a [spec] when they are valid, or
/// per-field error text.
class PaceFieldsCheck {
  const PaceFieldsCheck({this.spec, this.fastError, this.slowError});

  final PaceSpec? spec;
  final String? fastError;
  final String? slowError;

  bool get isValid => fastError == null && slowError == null;
}

String? _paceError(String text) {
  final pace = Pace.tryParse(text, DistUnit.mi);
  if (pace == null) return 'Enter a pace like 9:30';
  if (!pace.isWithinServerRange) return 'Enter a pace from 3:00 to 30:00';
  return null;
}

/// Pure validation for the pace fields (the widget only wires text to it).
/// Single needs [fast]; range needs both, with [slow] not faster than [fast].
PaceFieldsCheck checkPaceFields({
  required PaceMode mode,
  required DistUnit unit,
  required String fast,
  required String slow,
}) {
  switch (mode) {
    case PaceMode.none:
      return const PaceFieldsCheck(spec: NoPace());
    case PaceMode.single:
      final err = _paceError(fast);
      if (err != null) return PaceFieldsCheck(fastError: err);
      return PaceFieldsCheck(spec: SinglePace(Pace.parse(fast, unit)));
    case PaceMode.range:
      final fastErr = _paceError(fast);
      final slowErr = _paceError(slow);
      if (fastErr != null || slowErr != null) {
        return PaceFieldsCheck(fastError: fastErr, slowError: slowErr);
      }
      final f = Pace.parse(fast, unit);
      final s = Pace.parse(slow, unit);
      if (s.seconds < f.seconds) {
        return const PaceFieldsCheck(
          slowError: 'The slower end must not be faster than the faster end',
        );
      }
      return PaceFieldsCheck(spec: PaceRange(f, s));
  }
}

/// State of a [PaceInput]: mode, unit and the two min/sec pace fields. Like a form
/// hook in React: the parent owns it, reads [check] / [spec] and disposes it.
class PaceInputController extends ChangeNotifier {
  PaceInputController({
    PaceSpec initial = const NoPace(),
    this.defaultUnit = DistUnit.mi,
  }) : unit = switch (initial) {
         SinglePace(:final pace) => pace.unit,
         PaceRange(:final fast) => fast.unit,
         NoPace() => defaultUnit,
       },
       mode = switch (initial) {
         SinglePace() => PaceMode.single,
         PaceRange() => PaceMode.range,
         NoPace() => PaceMode.none,
       } {
    fast.text = initial.fastest?.format() ?? '';
    slow.text = initial is PaceRange ? initial.slow.format() : '';
    fast.addListener(notifyListeners);
    slow.addListener(notifyListeners);
  }

  final DistUnit defaultUnit;
  PaceMode mode;
  DistUnit unit;
  final fast = PaceTimeController();
  final slow = PaceTimeController();

  void setMode(PaceMode value) {
    mode = value;
    notifyListeners();
  }

  /// Switching min/mile <-> min/km converts what is already typed.
  void setUnit(DistUnit value) {
    if (value != unit) {
      for (final c in [fast, slow]) {
        final p = Pace.tryParse(c.text, unit);
        if (p != null) c.text = p.convertTo(value).format();
      }
    }
    unit = value;
    notifyListeners();
  }

  PaceFieldsCheck check() =>
      checkPaceFields(mode: mode, unit: unit, fast: fast.text, slow: slow.text);

  /// The valid spec, or [NoPace] while the fields are incomplete (previews).
  PaceSpec get spec => check().spec ?? const NoPace();

  @override
  void dispose() {
    fast.dispose();
    slow.dispose();
    super.dispose();
  }
}

/// Mode (none / single / range), unit toggle and min/sec fields for a pace.
/// Put it inside a [Form]; the fields validate through
/// [PaceInputController.check]. Shared by the group editor and the per-run
/// pace sheet.
class PaceInput extends StatelessWidget {
  const PaceInput({
    super.key,
    required this.controller,
    this.noneLabel = 'None',
    this.showHelp = true,
  });

  final PaceInputController controller;
  final String noneLabel;
  final bool showHelp;

  static const helpText =
      'No pace: use the description (e.g. jog/walk or efforts). Single pace: '
      'you aim to run close to it. Range: you support a wider spread; say in '
      'the description where faster runners muster back.';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final mode = controller.mode;
      final range = mode == PaceMode.range;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PaceMode>(
            segments: [
              ButtonSegment(value: PaceMode.none, label: Text(noneLabel)),
              const ButtonSegment(
                value: PaceMode.single,
                label: Text('Single'),
              ),
              const ButtonSegment(value: PaceMode.range, label: Text('Range')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
          if (showHelp)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                helpText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (mode != PaceMode.none) ...[
            const SizedBox(height: 12),
            SegmentedButton<DistUnit>(
              segments: const [
                ButtonSegment(value: DistUnit.mi, label: Text('min/mile')),
                ButtonSegment(value: DistUnit.km, label: Text('min/km')),
              ],
              selected: {controller.unit},
              onSelectionChanged: (s) => controller.setUnit(s.first),
            ),
            const SizedBox(height: 12),
            PaceTimeField(
              controller: controller.fast,
              keyPrefix: 'pace-fast',
              label: range ? 'Faster end' : 'Pace',
              unit: controller.unit,
              validator: (_) =>
                  paceTimeError(controller.fast, controller.check().fastError),
            ),
            if (range) ...[
              const SizedBox(height: 12),
              PaceTimeField(
                controller: controller.slow,
                keyPrefix: 'pace-slow',
                label: 'Slower end',
                unit: controller.unit,
                validator: (_) => paceTimeError(
                  controller.slow,
                  controller.check().slowError,
                ),
              ),
            ],
          ],
        ],
      );
    },
  );
}
