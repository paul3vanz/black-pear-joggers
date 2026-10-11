import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace.dart';

/// State of one [PaceTimeField]: a minutes box and a seconds box. The Android
/// number pad has no colon, so a pace is typed as two numbers (D29). [text] is
/// the bridge to the `m:ss` world of [Pace.parse].
class PaceTimeController extends ChangeNotifier {
  PaceTimeController({String text = ''}) {
    this.text = text;
    minutes.addListener(notifyListeners);
    seconds.addListener(notifyListeners);
  }

  final minutes = TextEditingController();
  final seconds = TextEditingController();

  bool get isEmpty =>
      minutes.text.trim().isEmpty && seconds.text.trim().isEmpty;

  /// True when the seconds box holds a number above 59.
  bool get secondsOutOfRange => (int.tryParse(seconds.text.trim()) ?? 0) > 59;

  /// The two boxes as `m:ss`: `9` + empty is `9:00`, `9` + `5` is `9:05`.
  /// Empty when both are empty. Without minutes it is `:ss`, which
  /// [Pace.tryParse] rejects.
  String get text {
    final m = minutes.text.trim();
    final s = seconds.text.trim();
    if (m.isEmpty && s.isEmpty) return '';
    return '$m:${s.isEmpty ? '00' : s.padLeft(2, '0')}';
  }

  /// Fills the boxes from `m:ss` (or a bare number of minutes). Anything else
  /// puts the raw text in the minutes box.
  set text(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      minutes.text = '';
      seconds.text = '';
      return;
    }
    final i = v.indexOf(':');
    if (i < 0) {
      minutes.text = v;
      seconds.text = '';
    } else {
      minutes.text = v.substring(0, i);
      final s = v.substring(i + 1);
      seconds.text = s == '00' ? '' : s;
    }
  }

  void clear() => text = '';

  @override
  void dispose() {
    minutes.dispose();
    seconds.dispose();
    super.dispose();
  }
}

/// Two number boxes for a pace: minutes and (optional) seconds, with the unit
/// shown after them. A [FormField]: inside a [Form] it validates through
/// [validator]; otherwise pass [errorText].
class PaceTimeField extends FormField<String> {
  PaceTimeField({
    super.key,
    required PaceTimeController controller,
    required String label,
    required DistUnit unit,
    String keyPrefix = 'pace',
    String? errorText,
    super.validator,
    VoidCallback? onChanged,
  }) : super(
         forceErrorText: errorText,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         builder: (state) {
           final theme = Theme.of(state.context);
           void changed(String _) {
             state.didChange(controller.text);
             onChanged?.call();
           }

           return Semantics(
             container: true,
             label: label,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: theme.textTheme.labelLarge),
                 const SizedBox(height: 6),
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Expanded(
                       flex: 2,
                       child: _numberBox(
                         key: ValueKey('$keyPrefix-min'),
                         controller: controller.minutes,
                         label: 'min',
                         onChanged: changed,
                       ),
                     ),
                     const SizedBox(width: 8),
                     Expanded(
                       flex: 3,
                       child: _numberBox(
                         key: ValueKey('$keyPrefix-sec'),
                         controller: controller.seconds,
                         label: 'sec',
                         hint: 'optional',
                         onChanged: changed,
                       ),
                     ),
                     Padding(
                       padding: const EdgeInsets.only(left: 6, top: 16),
                       child: Text(
                         '/${unit.code}',
                         style: theme.textTheme.bodyMedium,
                       ),
                     ),
                   ],
                 ),
                 if (state.errorText != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 6),
                     child: Text(
                       state.errorText!,
                       style: theme.textTheme.bodySmall?.copyWith(
                         color: theme.colorScheme.error,
                       ),
                     ),
                   ),
               ],
             ),
           );
         },
       );

  static Widget _numberBox({
    required Key key,
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    String? hint,
  }) => TextField(
    key: key,
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(2),
    ],
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
    onChanged: onChanged,
  );
}

/// `Seconds must be 0 to 59` when that is the problem, else [checkError].
String? paceTimeError(PaceTimeController c, String? checkError) =>
    c.secondsOutOfRange ? 'Seconds must be 0 to 59' : checkError;
