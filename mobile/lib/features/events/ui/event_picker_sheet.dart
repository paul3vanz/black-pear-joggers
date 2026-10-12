import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../data/event_dtos.dart';
import '../data/event_locations_repository.dart';
import 'event_providers.dart';

/// What the event picker returns: a club event location ([locationId] set) or
/// a free-text name ([locationId] null, [name] typed by the member). A saved
/// "Other..." name comes back as a location, like any other.
class EventPick {
  const EventPick({this.locationId, required this.name});

  final String? locationId;
  final String name;

  bool get isFreeText => locationId == null;
}

/// Opens the event picker as a bottom sheet and returns the choice, or null if
/// it was dismissed. The caller (the run page's "Add a parkrun/event" button)
/// then adds the group, passing `locationId` or `label: name`.
///
/// - [sessionId]: the run being added to; its event groups are greyed with
///   "Already added" (still selectable: choosing one just joins it).
/// - [usedLocationIds]: more ids to grey out, merged with the run's cached ones.
/// - [allowCreate]: offer "Save for next time" under "Other...", which POSTs a
///   `race`/`other` location (any linked member may; parkrun is committee only).
///
/// Opening it also refreshes the club's locations in the background (D78); the
/// cached list shows at once.
Future<EventPick?> showEventPicker(
  BuildContext context,
  WidgetRef ref, {
  required int clubId,
  required String sessionId,
  List<String> usedLocationIds = const [],
  bool allowCreate = false,
}) {
  unawaited(
    _refreshQuietly(ref.read(eventLocationsRepositoryProvider), clubId),
  );
  return showModalBottomSheet<EventPick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => EventPickerSheet(
      clubId: clubId,
      sessionId: sessionId,
      usedLocationIds: usedLocationIds.toSet(),
      allowCreate: allowCreate,
    ),
  );
}

Future<void> _refreshQuietly(EventLocationsRepository repo, int clubId) async {
  try {
    await repo.refresh(clubId);
  } on Object {
    // Offline or a hiccup: the cached list is fine.
  }
}

/// A flattened list row, so one `ListView.builder` can show headers and
/// locations without building widgets for ~800 rows up front.
sealed class _Row {}

class _HeaderRow extends _Row {
  _HeaderRow(this.text);
  final String text;
}

class _LocationRow extends _Row {
  _LocationRow(this.location);
  final EventLocation location;
}

/// The sheet's content. A `ConsumerStatefulWidget` is a `StatefulWidget` that
/// can `ref.watch` providers (a class component with hooks, roughly).
class EventPickerSheet extends ConsumerStatefulWidget {
  const EventPickerSheet({
    super.key,
    required this.clubId,
    required this.sessionId,
    this.usedLocationIds = const {},
    this.allowCreate = false,
  });

  final int clubId;
  final String sessionId;
  final Set<String> usedLocationIds;
  final bool allowCreate;

  @override
  ConsumerState<EventPickerSheet> createState() => _EventPickerSheetState();
}

class _EventPickerSheetState extends ConsumerState<EventPickerSheet> {
  /// How many "Recently used" rows to show above the A-Z list.
  static const _maxRecent = 8;

  final _search = TextEditingController();
  final _name = TextEditingController();
  String _query = '';
  List<String> _recentIds = const [];
  Set<String> _used = const {};
  bool _otherMode = false;
  bool _save = false;
  String _saveKind = 'race';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _used = widget.usedLocationIds;
    unawaited(_loadContext());
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    super.dispose();
  }

  /// Reads the cached runs once: what the club used lately and what this run
  /// already has.
  Future<void> _loadContext() async {
    final repo = ref.read(eventLocationsRepositoryProvider);
    final recent = await repo.recentLocationIds(widget.clubId);
    final onSession = await repo.locationIdsOnSession(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _recentIds = recent;
      _used = {...widget.usedLocationIds, ...onSession};
    });
  }

  bool _matches(EventLocation l) =>
      l.name.toLowerCase().contains(_query) ||
      (l.region?.toLowerCase().contains(_query) ?? false) ||
      (l.slug?.toLowerCase().contains(_query) ?? false);

  List<_Row> _rows(List<EventLocation> all) {
    if (_query.isNotEmpty) {
      return [
        for (final l in all)
          if (_matches(l)) _LocationRow(l),
      ];
    }
    final byId = {for (final l in all) l.id: l};
    final recent = [for (final id in _recentIds.take(_maxRecent)) ?byId[id]];
    return [
      if (recent.isNotEmpty) ...[
        _HeaderRow('Recently used by the club'),
        for (final l in recent) _LocationRow(l),
      ],
      if (all.isNotEmpty) _HeaderRow('All events, A to Z'),
      for (final l in all) _LocationRow(l),
    ];
  }

  void _pick(EventLocation l) =>
      Navigator.of(context).pop(EventPick(locationId: l.id, name: l.name));

  Future<void> _submitOther() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (!(widget.allowCreate && _save)) {
      Navigator.of(context).pop(EventPick(name: name));
      return;
    }
    final repo = ref.read(eventLocationsRepositoryProvider);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await repo.create(
        widget.clubId,
        kind: _saveKind,
        name: name,
      );
      navigator.pop(EventPick(locationId: saved.id, name: saved.name));
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) return;
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            '${eventLocationErrorMessage(e)} Untick "Save for next time" to '
            'use the name without saving it.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.9;
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: _otherMode ? _otherForm(context) : _picker(context),
      ),
    );
  }

  Widget _picker(BuildContext context) {
    final theme = Theme.of(context);
    final all =
        ref.watch(eventLocationsProvider(widget.clubId)).value ??
        const <EventLocation>[];
    final rows = _rows(all);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search parkruns and events',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Other...'),
          subtitle: const Text('Type the name of an event that is not listed'),
          onTap: () => setState(() {
            _otherMode = true;
            _name.text = _search.text.trim();
          }),
        ),
        const Divider(height: 1),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _query.isEmpty
                          ? 'No events yet. Use "Other..." to type one.'
                          : 'Nothing matches. Use "Other..." to type the name.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) => switch (rows[i]) {
                    _HeaderRow(:final text) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        text,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _LocationRow(:final location) => _tile(
                      theme,
                      location,
                      muted,
                    ),
                  },
                ),
        ),
      ],
    );
  }

  Widget _tile(ThemeData theme, EventLocation l, Color muted) {
    final used = _used.contains(l.id);
    final subtitle = [
      if (l.kind != 'parkrun') eventKindLabel(l.kind),
      ?l.region,
    ].join(' · ');
    return ListTile(
      leading: Icon(Icons.flag_outlined, color: used ? muted : null),
      title: Text(l.name, style: used ? TextStyle(color: muted) : null),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: used ? TextStyle(color: muted) : null),
      // Still selectable: choosing it just joins the existing event.
      trailing: used
          ? Text(
              'Already added',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            )
          : null,
      onTap: () => _pick(l),
    );
  }

  Widget _otherForm(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Other event',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Event name',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (widget.allowCreate) ...[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _save,
            onChanged: _saving
                ? null
                : (v) => setState(() => _save = v ?? false),
            title: const Text('Save for next time'),
            subtitle: const Text('Everyone in the club can pick it later.'),
          ),
          if (_save)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'race', label: Text('Race')),
                  ButtonSegment(value: 'other', label: Text('Other')),
                ],
                selected: {_saveKind},
                onSelectionChanged: _saving
                    ? null
                    : (s) => setState(() => _saveKind = s.first),
              ),
            ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Row(
          children: [
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _otherMode = false;
                      _error = null;
                    }),
              child: const Text('Back'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _saving || _name.text.trim().isEmpty
                  ? null
                  : () => unawaited(_submitOther()),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Use this name'),
            ),
          ],
        ),
      ],
    );
  }
}
