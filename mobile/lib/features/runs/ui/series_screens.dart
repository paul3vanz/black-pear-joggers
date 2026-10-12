import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../membership/ui/membership_providers.dart';
import '../../../core/db/app_database.dart';
import '../data/runs_repository.dart';
import '../data/session_changes.dart';
import '../logic/run_modes.dart';
import 'form_fields.dart';
import 'run_format.dart';
import 'series_image.dart';
import 'runs_providers.dart';
import 'session_actions.dart';

/// `/runs/series`: the weekly patterns that generate the runs (committee only).
class SeriesListScreen extends ConsumerWidget {
  const SeriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(activeClubIdProvider);
    final series = ref.watch(seriesListProvider(clubId)).value;
    final venues = ref.watch(venuesProvider(clubId)).value ?? const <Venue>[];
    final venueNames = {for (final v in venues) v.id: v.name};
    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(context.push('/runs/series/new')),
        icon: const Icon(Icons.add),
        label: const Text('Add series'),
      ),
      body: SafeArea(
        child: series == null
            ? const Center(child: CircularProgressIndicator())
            : series.isEmpty
            ? const Center(child: Text('No series yet.'))
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final s in series)
                    ListTile(
                      leading: const Icon(Icons.repeat),
                      title: Text(s.title),
                      subtitle: Text(
                        [
                          '${weekdayNames[(s.weekday - 1).clamp(0, 6)]} '
                              '${timeRange(s.startTime, endTimeFor(s.startTime, s.durationMin))}',
                          ?venueNames[s.venueId],
                          groupModeLabel(s.groupMode),
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          unawaited(context.push('/runs/series/${s.id}')),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Validates the optional series image URL: empty is fine; otherwise http(s) and
/// at most 500 characters (the server's rule, D49).
String? validateImageUrl(String? v) {
  final text = (v ?? '').trim();
  if (text.isEmpty) return null;
  if (text.length > 500) return 'At most 500 characters';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.isScheme('http') || uri.isScheme('https')) ||
      uri.host.isEmpty) {
    return 'Enter a link starting with http:// or https://';
  }
  return null;
}

/// `/runs/series/new` and `/runs/series/:id`.
class SeriesEditScreen extends ConsumerWidget {
  const SeriesEditScreen({super.key, this.seriesId});

  final String? seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = seriesId;
    if (id == null) return const _SeriesForm();
    final series = ref.watch(seriesProvider(id));
    return series.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Series')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Series')),
        body: const Center(child: Text("Couldn't load this series.")),
      ),
      data: (s) => s == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Series')),
              body: const Center(child: Text("This series isn't available.")),
            )
          : _SeriesForm(series: s),
    );
  }
}

class _SeriesForm extends ConsumerStatefulWidget {
  const _SeriesForm({this.series});

  final RunSeries? series;

  @override
  ConsumerState<_SeriesForm> createState() => _SeriesFormState();
}

class _SeriesFormState extends ConsumerState<_SeriesForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.series?.title ?? '');
  late final _description = TextEditingController(
    text: widget.series?.description ?? '',
  );
  late final _duration = TextEditingController(
    // New series default to 90 min; an existing series with no end stays empty.
    text: widget.series == null
        ? '90'
        : (widget.series!.durationMin?.toString() ?? ''),
  );
  late final _slug = TextEditingController(text: widget.series?.cmsSlug ?? '');
  late final _imageUrl = TextEditingController(
    text: widget.series?.imageUrl ?? '',
  );
  // The preview only follows the field when it loses focus, so half-typed URLs
  // don't trigger downloads.
  late String? _previewUrl = widget.series?.imageUrl;
  late int _weekday = widget.series?.weekday ?? 1;
  late int _interval = widget.series?.intervalWeeks ?? 1;
  late String? _start = widget.series?.startTime ?? '19:00';
  late String? _validFrom = widget.series?.validFrom ?? todayString();
  late String? _validUntil = widget.series?.validUntil;
  late String? _venueId = widget.series?.venueId;
  late String _groupMode = widget.series?.groupMode ?? 'paced';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    _slug.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final router = GoRouter.of(context);
    final existing = widget.series;
    final duration = DurationField.parse(_duration); // null = no end time
    setState(() => _saving = true);
    final ok = await runWrite(
      context,
      ref,
      () => existing == null
          ? repo.createSeries(
              clubId,
              title: _title.text.trim(),
              description: _nullIfEmpty(_description),
              venueId: _venueId,
              weekday: _weekday,
              startTime: _start!,
              durationMin: duration,
              intervalWeeks: _interval,
              validFrom: _validFrom!,
              validUntil: _validUntil,
              groupMode: _groupMode,
              cmsSlug: _nullIfEmpty(_slug),
              imageUrl: _nullIfEmpty(_imageUrl),
            )
          : repo.updateSeries(
              clubId,
              existing.id,
              title: _title.text.trim(),
              description: _nullIfEmpty(_description),
              venueId: _venueId,
              weekday: _weekday,
              startTime: _start!,
              durationMin: duration,
              intervalWeeks: _interval,
              validFrom: _validFrom!,
              validUntil: _validUntil,
              groupMode: _groupMode,
              cmsSlug: _nullIfEmpty(_slug),
              imageUrl: _nullIfEmpty(_imageUrl),
            ),
      success: existing == null ? 'Series added' : 'Series updated',
    );
    if (!mounted) return;
    if (ok) {
      router.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.series!;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final router = GoRouter.of(context);
    final yes = await confirm(
      context,
      title: 'Delete ${existing.title}?',
      message:
          'Its upcoming runs will be removed. Runs you have already edited '
          'or cancelled are kept.',
      action: 'Delete',
    );
    if (!yes || !mounted) return;
    final ok = await runWrite(
      context,
      ref,
      () => repo.deleteSeries(clubId, existing.id),
      success: 'Series deleted',
    );
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final editing = widget.series != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit series' : 'Add series'),
        actions: [saveAction(saving: _saving, onPressed: _save)],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLength: 150,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
              ),
              formGap,
              DropdownButtonFormField<int>(
                initialValue: _weekday,
                decoration: const InputDecoration(
                  labelText: 'Day of the week',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var i = 0; i < 7; i++)
                    DropdownMenuItem(
                      value: i + 1,
                      child: Text(weekdayNames[i]),
                    ),
                ],
                onChanged: (v) => _weekday = v ?? _weekday,
              ),
              formGap,
              TimeField(
                label: 'Start time',
                initialValue: _start,
                onSaved: (v) => _start = v,
              ),
              formGap,
              DurationField(controller: _duration),
              formGap,
              DropdownButtonFormField<int>(
                initialValue: _interval,
                decoration: const InputDecoration(
                  labelText: 'Repeats',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var i = 1; i <= 8; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(i == 1 ? 'Every week' : 'Every $i weeks'),
                    ),
                ],
                onChanged: (v) => _interval = v ?? _interval,
              ),
              formGap,
              DateField(
                label: 'Valid from',
                initialValue: _validFrom,
                onSaved: (v) => _validFrom = v,
                onChanged: (v) => _validFrom = v,
              ),
              formGap,
              DateField(
                label: 'Valid until (optional)',
                initialValue: _validUntil,
                required: false,
                onSaved: (v) => _validUntil = v,
                onChanged: (v) => _validUntil = v,
                extraValidator: (v) =>
                    (v != null &&
                        v.isNotEmpty &&
                        _validFrom != null &&
                        v.compareTo(_validFrom!) < 0)
                    ? 'Must be on or after "Valid from"'
                    : null,
              ),
              formGap,
              VenueDropdown(
                clubId: clubId,
                value: _venueId,
                onChanged: (v) => _venueId = v,
              ),
              formGap,
              GroupModeDropdown(
                value: _groupMode,
                modes: seriesGroupModes,
                onChanged: (v) => setState(() => _groupMode = v),
              ),
              formGap,
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(
                  labelText: 'Website page (optional)',
                  helperText: 'The slug in bpj.org.uk/club-runs/<slug>',
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                validator: (v) =>
                    (v != null &&
                        v.trim().isNotEmpty &&
                        !RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim()))
                    ? 'Lowercase letters, numbers and hyphens only'
                    : null,
              ),
              formGap,
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    final v = _imageUrl.text.trim();
                    setState(
                      () => _previewUrl =
                          validateImageUrl(v) == null && v.isNotEmpty
                          ? v
                          : null,
                    );
                  }
                },
                child: TextFormField(
                  key: const ValueKey('series-image-url'),
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    helperText:
                        'Shown above each run. Leave empty for no image.',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: validateImageUrl,
                ),
              ),
              if (_previewUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SeriesImage(url: _previewUrl, roundBottom: true),
                ),
              if (editing) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => unawaited(_delete()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete series'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
