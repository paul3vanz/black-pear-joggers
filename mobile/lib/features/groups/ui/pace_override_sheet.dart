import 'package:flutter/material.dart';

import '../../../core/units/dist_unit.dart';
import '../../../core/units/pace_spec.dart';
import 'pace_input.dart';

/// Bottom sheet for "My pace for this run". Returns the chosen [PaceSpec]
/// ([NoPace] means "use my usual pace"), or null when dismissed.
Future<PaceSpec?> showPaceOverrideSheet(
  BuildContext context, {
  required PaceSpec current,
  required DistUnit viewerUnit,
}) => showModalBottomSheet<PaceSpec>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _PaceSheet(current: current, viewerUnit: viewerUnit),
);

class _PaceSheet extends StatefulWidget {
  const _PaceSheet({required this.current, required this.viewerUnit});

  final PaceSpec current;
  final DistUnit viewerUnit;

  @override
  State<_PaceSheet> createState() => _PaceSheetState();
}

class _PaceSheetState extends State<_PaceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final PaceInputController _pace = PaceInputController(
    initial: widget.current,
    defaultUnit: widget.viewerUnit,
  );

  @override
  void dispose() {
    _pace.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_pace.spec);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('My pace for this run', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Only for this run. It helps leaders see who is coming and '
                'at what pace. Your usual pace is set in your profile.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              PaceInput(controller: _pace),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save pace')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(const NoPace()),
                child: const Text('Use my usual pace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
