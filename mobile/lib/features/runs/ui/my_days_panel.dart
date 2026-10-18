import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../groups/data/run_preferences_repository.dart';
import '../../membership/ui/membership_providers.dart';
import '../logic/my_days.dart';

/// "Days I run" (Runs tab) or "Days I may lead" (Lead a run), D115. One
/// compact line once a choice is made ("Run days: Mon, Wed", **Show 3 more**,
/// **Change**), the chips with **Save** while choosing. The list it narrows
/// belongs to the screen, so the screen owns [showAll] and passes [hidden].
///
/// Saving is a `PUT /preferences` of just this kind's days, online-only, and
/// the server's reply goes into the Drift cache the screen already watches, so
/// the list narrows by itself. (In React terms: a controlled form whose draft
/// lives in `useState` and whose saved value comes from the query cache.)
class MyDaysPanel extends ConsumerStatefulWidget {
  const MyDaysPanel({
    super.key,
    required this.kind,
    required this.present,
    required this.saved,
    required this.otherSaved,
    required this.hidden,
    required this.showAll,
    required this.onShowAll,
    this.preselect = const {},
    this.promptWhenUnset = false,
    this.onSaved,
  });

  final DayKind kind;

  /// Weekdays that have upcoming runs (the chips offered, plus any saved day).
  final Set<int> present;

  /// This kind's saved days: null = never chosen.
  final List<int>? saved;

  /// The other kind's saved days, for the "this changes that too" hints.
  final List<int>? otherSaved;

  /// Runs the current filter hides (0 while showing all).
  final int hidden;
  final bool showAll;
  final ValueChanged<bool> onShowAll;

  /// Chips ticked while nothing is saved yet.
  final Set<int> preselect;

  /// Open the chips straight away while nothing is saved (Lead a run asks;
  /// the Runs tab offers a quiet "Choose days" instead).
  final bool promptWhenUnset;

  /// After a successful save.
  final VoidCallback? onSaved;

  @override
  ConsumerState<MyDaysPanel> createState() => _MyDaysPanelState();
}

class _MyDaysPanelState extends ConsumerState<MyDaysPanel> {
  /// Chips are open although the panel would be compact (Change or Choose).
  bool _editing = false;

  /// The unsaved selection; null until a chip is touched, so the chips follow
  /// `saved` (or [MyDaysPanel.preselect]) until then.
  Set<int>? _draft;
  bool _saving = false;
  String? _error;

  DayKind get _kind => widget.kind;
  String get _key => _kind.name;

  Set<int> get _selected =>
      _draft ?? (widget.saved?.toSet() ?? widget.preselect);

  void _toggle(int day, bool on) => setState(() {
    _error = null;
    _draft = on ? {..._selected, day} : ({..._selected}..remove(day));
  });

  Future<void> _save(List<int>? days) async {
    if (_saving) return;
    final clubId = ref.read(activeClubIdProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(runPreferencesRepositoryProvider)
          .saveDays(clubId, _kind, days == null ? null : ([...days]..sort()));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
        _draft = null;
      });
      widget.onSaved?.call();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.isNetworkError
              ? 'You need a connection to save your days.'
              : e.message;
        });
      }
    }
  }

  void _cancel() => setState(() {
    _editing = false;
    _draft = null;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final saved = widget.saved;
    final editing = _editing || (saved == null && widget.promptWhenUnset);
    return Container(
      key: ValueKey('${_key}DaysPanel'),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: editing
          ? const EdgeInsets.all(12)
          : const EdgeInsets.only(left: 12, right: 4),
      child: editing ? _buildEditor(context) : _buildLine(context),
    );
  }

  /// "Run days: Mon, Wed   Show 3 more   Change" on one row.
  Widget _buildLine(BuildContext context) {
    final saved = widget.saved;
    final String text;
    if (saved == null) {
      text = 'Showing every day';
    } else if (saved.isEmpty) {
      text = _kind == DayKind.lead ? 'Not leading on any day' : 'No run days';
    } else {
      final label = _kind == DayKind.lead ? 'Lead days' : 'Run days';
      text = '$label: ${formatWeekdays(saved)}';
    }
    final compact = TextButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        if (widget.showAll || widget.hidden > 0)
          TextButton(
            key: ValueKey('${_key}DaysReveal'),
            style: compact,
            onPressed: () => widget.onShowAll(!widget.showAll),
            child: Text(
              widget.showAll ? 'Just my days' : 'Show ${widget.hidden} more',
            ),
          ),
        TextButton(
          key: ValueKey('${_key}DaysChange'),
          style: compact,
          onPressed: () => setState(() {
            _editing = true;
            _draft = saved?.toSet() ?? widget.preselect;
          }),
          child: Text(saved == null ? 'Choose days' : 'Change'),
        ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final saved = widget.saved;
    final selected = _selected;
    final other = widget.otherSaved?.toSet();
    final days = {...widget.present, ...selected, ...?saved}.toList()..sort();
    final isLead = _kind == DayKind.lead;
    // A run day needs at least one day; "every day" is its own button.
    final canSave = !_saving && (isLead || selected.isNotEmpty);

    // What saving would also change in the other list (the server keeps lead
    // days inside run days).
    final String? knockOn;
    if (isLead && other != null) {
      final added = selected.difference(other);
      knockOn = added.isEmpty
          ? null
          : '${formatWeekdays(added)} will be added to your run days.';
    } else if (!isLead && other != null) {
      final dropped = other.difference(selected);
      knockOn = dropped.isEmpty
          ? null
          : "You'll stop being asked to lead on ${formatWeekdays(dropped)}.";
    } else {
      knockOn = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(switch ((isLead, saved == null)) {
          (true, true) => 'Which days could you lead?',
          (true, false) => 'Days I may lead',
          (false, true) => 'Which days do you usually run?',
          (false, false) => 'Days I run',
        }, style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          isLead
              ? "Only those days are listed here, and we'll only ask you to "
                    'lead on them.'
              : 'Runs on other days are hidden, and we only tell you about '
                    "them if you say you're coming.",
          style: muted,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final d in days)
              FilterChip(
                key: ValueKey('${_key}Day-$d'),
                label: Text(weekdayShort[d - 1]),
                selected: selected.contains(d),
                onSelected: _saving ? null : (on) => _toggle(d, on),
              ),
          ],
        ),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              isLead
                  ? "No days chosen: you won't be asked to lead"
                  : 'Pick at least one day, or show every day.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (knockOn != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(knockOn, style: muted),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              key: ValueKey('${_key}DaysSave'),
              onPressed: canSave
                  ? () => unawaited(_save(selected.toList()))
                  : null,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            if (!isLead && saved != null)
              TextButton(
                key: ValueKey('${_key}DaysEveryDay'),
                onPressed: _saving ? null : () => unawaited(_save(null)),
                child: const Text('Show every day'),
              ),
            if (_editing)
              TextButton(
                key: ValueKey('${_key}DaysCancel'),
                onPressed: _saving ? null : _cancel,
                child: const Text('Cancel'),
              ),
            if (widget.showAll || widget.hidden > 0)
              TextButton(
                key: ValueKey('${_key}DaysReveal'),
                onPressed: () => widget.onShowAll(!widget.showAll),
                child: Text(
                  widget.showAll
                      ? 'Just my days'
                      : 'Show ${widget.hidden} more',
                ),
              ),
          ],
        ),
      ],
    );
  }
}
