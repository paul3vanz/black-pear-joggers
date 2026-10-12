import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../membership/ui/membership_providers.dart';
import '../../../core/db/app_database.dart';
import '../data/runs_repository.dart';
import '../../groups/ui/member_picker.dart';
import 'form_fields.dart';
import 'run_format.dart';
import 'runs_providers.dart';
import 'session_actions.dart';

/// `/runs/new` (add an ad-hoc run) and `/runs/:id/edit` (change this occurrence
/// only). Committee/admin only; the entry points are hidden for everyone else
/// and the server answers 403 anyway. Online-only: failures keep the form open.
class SessionEditScreen extends ConsumerWidget {
  const SessionEditScreen({super.key, this.sessionId});

  /// Null when adding a new ad-hoc run.
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = sessionId;
    if (id == null) return const _SessionForm();
    final session = ref.watch(sessionProvider(id));
    return session.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit run')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit run')),
        body: const Center(child: Text("Couldn't load this run.")),
      ),
      data: (s) => s == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Edit run')),
              body: const Center(child: Text("This run isn't available.")),
            )
          : _SessionForm(session: s),
    );
  }
}

class _SessionForm extends ConsumerStatefulWidget {
  const _SessionForm({this.session});

  final Session? session;

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  late String? _date;
  late String? _start;
  late String? _venueId;
  late String _groupMode;
  String? _coordinatorId;
  String? _coordinatorName;
  bool _coordinatorChanged = false;
  bool _saving = false;

  Session? get _existing => widget.session;

  /// A date can only change for ad-hoc runs (series occurrences keep theirs).
  bool get _dateEditable => _existing == null || _existing!.seriesId == null;

  @override
  void initState() {
    super.initState();
    final s = _existing;
    _title = TextEditingController(text: s?.title ?? '');
    _duration = TextEditingController(
      text: s == null
          ? '90'
          : s.localEndTime == null
          ? ''
          : durationBetween(s.localStartTime, s.localEndTime!).toString(),
    );
    _notes = TextEditingController(text: s?.notes ?? '');
    _date = s?.localDate ?? todayString();
    _start = s?.localStartTime ?? '19:00';
    _venueId = s?.venueId;
    _groupMode = s?.groupMode ?? 'open';
    _coordinatorId = s?.coordinatorMemberId;
    _coordinatorName = s?.coordinatorName;
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickCoordinator() async {
    final pick = await showMemberPicker(
      context,
      title: 'Coordinator',
      noneLabel: 'No coordinator',
    );
    if (pick == null || !mounted) return;
    setState(() {
      _coordinatorChanged = true;
      _coordinatorId = pick.member?.memberId;
      _coordinatorName = pick.member?.displayName;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(runsRepositoryProvider);
    final router = GoRouter.of(context);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final duration = DurationField.parse(_duration); // null = no end time
    setState(() => _saving = true);
    final existing = _existing;
    final ok = await runWrite(
      context,
      ref,
      () => existing == null
          ? repo.createAdHocSession(
              clubId,
              title: _title.text.trim(),
              localDate: _date!,
              startTime: _start!,
              durationMin: duration,
              groupMode: _groupMode,
              venueId: _venueId,
              notes: notes,
            )
          : repo.updateSession(
              clubId,
              existing.id,
              title: _title.text.trim(),
              startTime: _start!,
              durationMin: duration,
              venueId: _venueId,
              notes: notes,
              localDate: _dateEditable ? _date : null,
              setCoordinator: _coordinatorChanged,
              coordinatorMemberId: _coordinatorId,
            ),
      success: existing == null ? 'Run added' : 'Run updated',
    );
    if (!mounted) return;
    if (ok) {
      router.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(activeClubIdProvider);
    final editing = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit run' : 'Add ad-hoc run'),
        actions: [saveAction(saving: _saving, onPressed: _save)],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (editing && _existing!.seriesId != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Changes apply to this run only. The weekly series '
                    'is not affected.',
                  ),
                ),
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
              if (_dateEditable) ...[
                DateField(
                  label: 'Date',
                  initialValue: _date,
                  onSaved: (v) => _date = v,
                ),
                formGap,
              ],
              TimeField(
                label: 'Start time',
                initialValue: _start,
                onSaved: (v) => _start = v,
              ),
              formGap,
              DurationField(controller: _duration),
              formGap,
              VenueDropdown(
                clubId: clubId,
                value: _venueId,
                onChanged: (v) => _venueId = v,
              ),
              formGap,
              if (editing && ref.watch(canManageRunsProvider)) ...[
                _CoordinatorTile(
                  name: _coordinatorName,
                  onPick: _pickCoordinator,
                ),
                formGap,
              ],
              if (!editing) ...[
                GroupModeDropdown(
                  value: _groupMode,
                  onChanged: (v) => setState(() => _groupMode = v),
                ),
                formGap,
              ],
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Coordinator: Jo Bloggs" with a button to change it. The coordinator can
/// add routes and groups for the run (most useful for `routes` sessions).
class _CoordinatorTile extends StatelessWidget {
  const _CoordinatorTile({required this.name, required this.onPick});

  final String? name;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: const InputDecoration(
      labelText: 'Coordinator',
      helperText: 'Can add routes and groups for this run.',
      border: OutlineInputBorder(),
    ),
    child: Row(
      children: [
        Expanded(child: Text(name ?? 'No coordinator')),
        TextButton(
          onPressed: onPick,
          child: Text(name == null ? 'Choose' : 'Change'),
        ),
      ],
    ),
  );
}
