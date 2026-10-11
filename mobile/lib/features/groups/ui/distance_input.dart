import 'package:flutter/material.dart';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/distance.dart';

/// The result of checking the distance field. An empty field is valid and
/// means no distance ([distance] null).
class DistanceCheck {
  const DistanceCheck({this.distance, this.error});

  final Distance? distance;
  final String? error;

  bool get isValid => error == null;
}

/// Pure validation for the optional distance field (0.1 to 200 in its unit).
DistanceCheck checkDistanceField(String text, DistUnit unit) {
  if (text.trim().isEmpty) return const DistanceCheck();
  final d = Distance.tryParse(text, unit);
  if (d == null) {
    return const DistanceCheck(error: 'Enter a number like 5 or 5.5');
  }
  if (!d.isWithinServerRange) {
    return const DistanceCheck(error: 'Enter a distance from 0.1 to 200');
  }
  return DistanceCheck(distance: d);
}

/// State of a [DistanceInput]: the value text and the unit.
class DistanceInputController extends ChangeNotifier {
  DistanceInputController({
    Distance? initial,
    DistUnit defaultUnit = DistUnit.mi,
  }) : unit = initial?.unit ?? defaultUnit {
    text.text = initial == null ? '' : Distance.formatValue(initial.value);
    text.addListener(notifyListeners);
  }

  final text = TextEditingController();
  DistUnit unit;

  void setUnit(DistUnit value) {
    unit = value;
    notifyListeners();
  }

  DistanceCheck check() => checkDistanceField(text.text, unit);

  /// The valid distance, or null when empty or invalid (previews).
  Distance? get distance => check().distance;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }
}

/// Optional distance: a value and a miles/km toggle. Put it inside a [Form].
class DistanceInput extends StatelessWidget {
  const DistanceInput({super.key, required this.controller, this.label});

  final DistanceInputController controller;
  final String? label;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.text,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: label ?? 'Distance (optional)',
            suffixText: controller.unit == DistUnit.mi ? 'miles' : 'km',
            border: const OutlineInputBorder(),
          ),
          validator: (_) => controller.check().error,
        ),
        const SizedBox(height: 8),
        SegmentedButton<DistUnit>(
          segments: const [
            ButtonSegment(value: DistUnit.mi, label: Text('miles')),
            ButtonSegment(value: DistUnit.km, label: Text('km')),
          ],
          selected: {controller.unit},
          onSelectionChanged: (s) => controller.setUnit(s.first),
        ),
      ],
    ),
  );
}
