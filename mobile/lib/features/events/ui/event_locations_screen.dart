import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/form_fields.dart';
import '../../runs/ui/runs_providers.dart';
import '../../runs/ui/session_actions.dart';
import '../data/event_dtos.dart';
import '../data/event_locations_repository.dart';
import 'event_providers.dart';

/// The hint under the count: the parkrun list comes from the server (D78).
const eventLocationsImportHint =
    'The parkrun list is imported by an administrator on the server '
    '(see setup docs).';

/// `/profile/event-locations`: the club's parkruns, races and other events
/// (committee/admin only; the entry points are hidden for everyone else and the
/// server answers 403 anyway). List with search and kind filters; tap a row to
/// edit or delete it, or use the button to add one. Writes need a connection.
class EventLocationsScreen extends ConsumerStatefulWidget {
  const EventLocationsScreen({super.key});

  @override
  ConsumerState<EventLocationsScreen> createState() =>
      _EventLocationsScreenState();
}

class _EventLocationsScreenState extends ConsumerState<EventLocationsScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// Kinds ticked in the filter chips; empty means all kinds.
  final Set<String> _kinds = {};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref
          .read(eventLocationsRepositoryProvider)
          .refresh(ref.read(activeClubIdProvider));
    } on Object {
      // Offline: the cached list is shown.
    }
  }

  bool _matches(EventLocation l) {
    if (_kinds.isNotEmpty && !_kinds.contains(l.kind)) return false;
    if (_query.isEmpty) return true;
    return l.name.toLowerCase().contains(_query) ||
        (l.region?.toLowerCase().contains(_query) ?? false) ||
        (l.slug?.toLowerCase().contains(_query) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = ref.watch(canManageRunsProvider);
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event locations')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Only the committee can manage event locations.'),
          ),
        ),
      );
    }
    final clubId = ref.watch(activeClubIdProvider);
    final all = ref.watch(eventLocationsProvider(clubId)).value;
    final shown = [
      for (final l in all ?? const <EventLocation>[])
        if (_matches(l)) l,
    ];
    final filtering = _query.isNotEmpty || _kinds.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Event locations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_openForm(context)),
        icon: const Icon(Icons.add),
        label: const Text('Add location'),
      ),
      body: SafeArea(
        child: all == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 96),
                  // Header block first, then one tile per location.
                  itemCount: shown.length + 2,
                  itemBuilder: (context, i) {
                    if (i == 0) return _header(theme, all.length, shown.length);
                    if (i == 1) {
                      return shown.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                filtering
                                    ? 'Nothing matches.'
                                    : 'No event locations yet.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final l = shown[i - 2];
                    return ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(l.name),
                      subtitle: Text(
                        [eventKindLabel(l.kind), ?l.region].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => unawaited(_openForm(context, existing: l)),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _header(ThemeData theme, int total, int shown) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: 'Search',
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
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final kind in eventLocationKinds)
              FilterChip(
                label: Text(eventKindLabel(kind)),
                selected: _kinds.contains(kind),
                onSelected: (on) => setState(() {
                  if (on) {
                    _kinds.add(kind);
                  } else {
                    _kinds.remove(kind);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          shown == total
              ? '$total ${total == 1 ? 'location' : 'locations'}'
              : 'Showing $shown of $total',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(eventLocationsImportHint, style: theme.textTheme.bodySmall),
      ],
    ),
  );

  Future<void> _openForm(BuildContext context, {EventLocation? existing}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: _LocationForm(existing: existing),
        ),
      );
}

/// Add/edit form in a bottom sheet. Saving and deleting go straight to the
/// server (online-only); the sheet closes on success.
class _LocationForm extends ConsumerStatefulWidget {
  const _LocationForm({this.existing});

  final EventLocation? existing;

  @override
  ConsumerState<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends ConsumerState<_LocationForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _region = TextEditingController(
    text: widget.existing?.region ?? '',
  );
  late final _url = TextEditingController(text: widget.existing?.url ?? '');
  late final _lat = TextEditingController(
    text: widget.existing?.lat?.toString() ?? '',
  );
  late final _lng = TextEditingController(
    text: widget.existing?.lng?.toString() ?? '',
  );
  late String _kind = widget.existing?.kind ?? 'race';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _region.dispose();
    _url.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  /// Optional coordinate: empty is fine, otherwise a number within [limit].
  String? _coordinate(String? v, double limit, String what) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null || n.abs() > limit) return 'Enter a valid $what';
    return null;
  }

  /// Latitude and longitude only make sense together.
  String? _pair(String? v, TextEditingController other) =>
      (v ?? '').trim().isEmpty && other.text.trim().isNotEmpty
      ? 'Enter both latitude and longitude'
      : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(eventLocationsRepositoryProvider);
    final navigator = Navigator.of(context);
    final existing = widget.existing;
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    setState(() => _busy = true);
    final ok = await runWrite(
      context,
      ref,
      () => existing == null
          ? repo.create(
              clubId,
              kind: _kind,
              name: _name.text.trim(),
              region: _nullIfEmpty(_region),
              lat: lat,
              lng: lng,
              url: _nullIfEmpty(_url),
            )
          : repo.update(
              clubId,
              existing.id,
              kind: _kind,
              name: _name.text.trim(),
              region: _nullIfEmpty(_region),
              lat: lat,
              lng: lng,
              url: _nullIfEmpty(_url),
            ),
      success: existing == null ? 'Location added' : 'Location updated',
      errorMessage: eventLocationErrorMessage,
    );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(eventLocationsRepositoryProvider);
    final navigator = Navigator.of(context);
    final yes = await confirm(
      context,
      title: 'Delete ${existing.name}?',
      message:
          'It will no longer be offered when adding an event. Events that '
          'already use it keep their name.',
      action: 'Delete',
    );
    if (!yes || !mounted) return;
    setState(() => _busy = true);
    final ok = await runWrite(
      context,
      ref,
      () => repo.delete(clubId, existing.id),
      success: 'Location deleted',
      errorMessage: eventLocationErrorMessage,
    );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            editing ? 'Edit location' : 'Add location',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          SegmentedButton<String>(
            segments: [
              for (final k in eventLocationKinds)
                ButtonSegment(value: k, label: Text(eventKindLabel(k))),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          formGap,
          TextFormField(
            controller: _region,
            decoration: const InputDecoration(
              labelText: 'Region (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      _coordinate(v, 90, 'latitude') ?? _pair(v, _lng),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      _coordinate(v, 180, 'longitude') ?? _pair(v, _lat),
                ),
              ),
            ],
          ),
          formGap,
          TextFormField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'Website (optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            validator: _validateUrl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (editing)
                TextButton.icon(
                  onPressed: _busy ? null : () => unawaited(_delete()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_save()),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty is fine; otherwise an http(s) link of at most 255 characters (the
/// server's column size).
String? _validateUrl(String? v) {
  final text = (v ?? '').trim();
  if (text.isEmpty) return null;
  if (text.length > 255) return 'At most 255 characters';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty) {
    return 'Enter a link starting with http:// or https://';
  }
  return null;
}
