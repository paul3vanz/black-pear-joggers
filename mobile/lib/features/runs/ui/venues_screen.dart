import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../membership/ui/membership_providers.dart';
import '../../../core/db/app_database.dart';
import '../data/runs_repository.dart';
import 'form_fields.dart';
import 'runs_providers.dart';
import 'session_actions.dart';

/// `/runs/venues`: the club's venues (committee only).
class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(activeClubIdProvider);
    final venues = ref.watch(venuesProvider(clubId)).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Venues')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(context.push('/runs/venues/new')),
        icon: const Icon(Icons.add),
        label: const Text('Add venue'),
      ),
      body: SafeArea(
        child: venues == null
            ? const Center(child: CircularProgressIndicator())
            : venues.isEmpty
            ? const Center(child: Text('No venues yet.'))
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final v in venues)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(v.name),
                      subtitle: v.address == null ? null : Text(v.address!),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          unawaited(context.push('/runs/venues/${v.id}')),
                    ),
                ],
              ),
      ),
    );
  }
}

/// `/runs/venues/new` and `/runs/venues/:id`.
class VenueEditScreen extends ConsumerWidget {
  const VenueEditScreen({super.key, this.venueId});

  final String? venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = venueId;
    if (id == null) return const _VenueForm();
    final venue = ref.watch(venueProvider(id));
    return venue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Venue')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Venue')),
        body: const Center(child: Text("Couldn't load this venue.")),
      ),
      data: (v) => v == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Venue')),
              body: const Center(child: Text("This venue isn't available.")),
            )
          : _VenueForm(venue: v),
    );
  }
}

class _VenueForm extends ConsumerStatefulWidget {
  const _VenueForm({this.venue});

  final Venue? venue;

  @override
  ConsumerState<_VenueForm> createState() => _VenueFormState();
}

class _VenueFormState extends ConsumerState<_VenueForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.venue?.name ?? '');
  late final _address = TextEditingController(
    text: widget.venue?.address ?? '',
  );
  late final _notes = TextEditingController(text: widget.venue?.notes ?? '');
  late final _lat = TextEditingController(
    text: widget.venue?.lat?.toString() ?? '',
  );
  late final _lng = TextEditingController(
    text: widget.venue?.lng?.toString() ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _notes.dispose();
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
  String? _pairValidator(TextEditingController other) =>
      (other.text.trim().isNotEmpty)
      ? 'Enter both latitude and longitude'
      : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final router = GoRouter.of(context);
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    final existing = widget.venue;
    setState(() => _saving = true);
    final ok = await runWrite(
      context,
      ref,
      () => existing == null
          ? repo.createVenue(
              clubId,
              name: _name.text.trim(),
              address: _nullIfEmpty(_address),
              lat: lat,
              lng: lng,
              notes: _nullIfEmpty(_notes),
            )
          : repo.updateVenue(
              clubId,
              existing.id,
              name: _name.text.trim(),
              address: _nullIfEmpty(_address),
              lat: lat,
              lng: lng,
              notes: _nullIfEmpty(_notes),
            ),
      success: existing == null ? 'Venue added' : 'Venue updated',
    );
    if (!mounted) return;
    if (ok) {
      router.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.venue!;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final router = GoRouter.of(context);
    final yes = await confirm(
      context,
      title: 'Delete ${existing.name}?',
      message: 'Venues that are still in use cannot be deleted.',
      action: 'Delete',
    );
    if (!yes || !mounted) return;
    final ok = await runWrite(
      context,
      ref,
      () => repo.deleteVenue(clubId, existing.id),
      success: 'Venue deleted',
    );
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.venue != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit venue' : 'Add venue'),
        actions: [saveAction(saving: _saving, onPressed: _save)],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 150,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              formGap,
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes (parking, meeting point...)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
              ),
              formGap,
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
                          _coordinate(v, 90, 'latitude') ??
                          (v!.trim().isEmpty ? _pairValidator(_lng) : null),
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
                          _coordinate(v, 180, 'longitude') ??
                          (v!.trim().isEmpty ? _pairValidator(_lat) : null),
                    ),
                  ),
                ],
              ),
              if (editing) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => unawaited(_delete()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete venue'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
