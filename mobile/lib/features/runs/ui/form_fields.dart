import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../data/runs_repository.dart';
import '../data/session_changes.dart';
import 'run_format.dart';
import 'runs_providers.dart';

/// A tap-to-pick time field holding an `HH:mm` string (club-local time, no
/// time zone conversion).
class TimeField extends FormField<String> {
  TimeField({
    super.key,
    required String label,
    super.initialValue,
    super.onSaved,
    ValueChanged<String>? onChanged,
  }) : super(
         validator: (v) =>
             (v == null || parseHm(v) == null) ? 'Pick a time' : null,
         builder: (state) {
           Future<void> pick() async {
             final current = parseHm(state.value ?? '') ?? 19 * 60;
             final picked = await showTimePicker(
               context: state.context,
               initialTime: TimeOfDay(
                 hour: current ~/ 60,
                 minute: current % 60,
               ),
               builder: (ctx, child) => MediaQuery(
                 data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                 child: child!,
               ),
             );
             if (picked == null) return;
             final value = formatHm(picked.hour * 60 + picked.minute);
             state.didChange(value);
             onChanged?.call(value);
           }

           return InkWell(
             onTap: pick,
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 border: const OutlineInputBorder(),
                 errorText: state.errorText,
                 suffixIcon: const Icon(Icons.schedule),
               ),
               child: Text(state.value ?? 'Not set'),
             ),
           );
         },
       );
}

/// A tap-to-pick date field holding a `yyyy-MM-dd` string. Optional fields
/// (`required: false`) can be cleared.
class DateField extends FormField<String> {
  DateField({
    super.key,
    required String label,
    super.initialValue,
    bool required = true,
    DateTime? firstDate,
    super.onSaved,
    ValueChanged<String?>? onChanged,
    FormFieldValidator<String>? extraValidator,
  }) : super(
         validator: (v) {
           if (required && (v == null || v.isEmpty)) return 'Pick a date';
           return extraValidator?.call(v);
         },
         builder: (state) {
           Future<void> pick() async {
             final initial = state.value == null || state.value!.isEmpty
                 ? DateTime.now()
                 : parseLocalDate(state.value!);
             final first = firstDate ?? DateTime(2020);
             final picked = await showDatePicker(
               context: state.context,
               initialDate: initial.isBefore(first) ? first : initial,
               firstDate: first.isBefore(initial) ? first : initial,
               lastDate: DateTime(2100),
             );
             if (picked == null) return;
             final value = localDateString(picked);
             state.didChange(value);
             onChanged?.call(value);
           }

           final value = state.value;
           return InkWell(
             onTap: pick,
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 border: const OutlineInputBorder(),
                 errorText: state.errorText,
                 suffixIcon: !required && value != null && value.isNotEmpty
                     ? IconButton(
                         icon: const Icon(Icons.clear),
                         tooltip: 'Clear',
                         onPressed: () {
                           state.didChange(null);
                           onChanged?.call(null);
                         },
                       )
                     : const Icon(Icons.calendar_today),
               ),
               child: Text(
                 value == null || value.isEmpty
                     ? (required ? 'Not set' : 'None')
                     : longDate(value),
               ),
             ),
           );
         },
       );
}

/// Venue dropdown over the cached venues, with a "No venue" choice.
class VenueDropdown extends ConsumerWidget {
  const VenueDropdown({
    super.key,
    required this.clubId,
    required this.value,
    required this.onChanged,
  });

  final int clubId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final known = venues.any((v) => v.id == value);
    return DropdownButtonFormField<String?>(
      initialValue: known ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Venue',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(child: Text('No venue')),
        for (final v in venues)
          DropdownMenuItem<String?>(
            value: v.id,
            child: Text(v.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Group mode dropdown (paced / single / open / routes).
class GroupModeDropdown extends StatelessWidget {
  const GroupModeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: 'How we run',
      helperText: groupModeExplainer(value),
      helperMaxLines: 2,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final m in groupModes)
        DropdownMenuItem(value: m, child: Text(groupModeLabel(m))),
    ],
    onChanged: (v) => onChanged(v ?? value),
  );
}

/// Duration in minutes (the server accepts 15-600).
class DurationField extends StatelessWidget {
  const DurationField({super.key, required this.controller});

  final TextEditingController controller;

  static String? validate(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 15 || n > 600) return 'Enter 15 to 600 minutes';
    return null;
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Duration (minutes)',
      border: OutlineInputBorder(),
    ),
    validator: validate,
  );
}

/// Shared spacing between form fields.
const formGap = SizedBox(height: 16);

/// The AppBar "Save" action with an in-progress indicator.
Widget saveAction({required bool saving, required VoidCallback onPressed}) =>
    TextButton(
      onPressed: saving ? null : onPressed,
      child: saving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Save'),
    );

/// Today as `yyyy-MM-dd` (device clock).
String todayString() => localDateString(DateTime.now());
