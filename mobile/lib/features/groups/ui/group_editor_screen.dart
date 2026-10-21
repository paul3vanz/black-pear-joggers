import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/db/app_database.dart';
import '../../runs/logic/run_modes.dart';
import '../../runs/ui/form_fields.dart';
import '../../runs/ui/runs_providers.dart';
import '../../runs/ui/session_actions.dart';
import '../../../core/units/distance.dart';
import '../../../core/units/pace_spec.dart';
import '../data/group_dtos.dart';
import '../data/groups_repository.dart';
import '../data/last_group_store.dart';
import 'distance_input.dart';
import 'group_access.dart';
import 'group_actions.dart';
import 'group_format.dart';
import 'groups_providers.dart';
import 'pace_input.dart';

/// Why the editor was opened for a new group (D86).
///
/// - [lead]: the member pressed a "lead" action ("Offer to lead", "Lead a
///   group"). The group is theirs, so the editor never asks whether they will
///   lead it.
/// - [add]: an "add a group" action for the committee or the run's coordinator
///   ("Add a group", "Add route"). Only those people may create a leaderless
///   group, so only they see the "I will lead this group" switch. Anyone else
///   who somehow arrives with [add] still creates a group they lead.
enum GroupIntent {
  lead,
  add;

  /// The `intent` query parameter of the route; anything but `add` is [lead].
  static GroupIntent fromQuery(String? value) => value == 'add' ? add : lead;
}

/// `/runs/:sessionId/groups/new` and `/runs/:sessionId/groups/:groupId/edit`.
/// Creating a group is online-only (D23): errors show in a SnackBar and the
/// form stays on screen. [initialKind] / [initialLead] pre-fill "Add route".
class GroupEditorScreen extends ConsumerWidget {
  const GroupEditorScreen({
    super.key,
    required this.sessionId,
    this.groupId,
    this.initialKind,
    this.intent = GroupIntent.lead,
    this.initialLead,
  });

  /// The new-group screen for a route like
  /// `/runs/a/groups/new?intent=add&kind=route&lead=false`. Shared by the
  /// router and the tests, so the query parameters mean one thing.
  factory GroupEditorScreen.fromUri(String sessionId, Uri uri) {
    final q = uri.queryParameters;
    return GroupEditorScreen(
      sessionId: sessionId,
      initialKind: q['kind'],
      // 'lead' (default) or 'add' (D86).
      intent: GroupIntent.fromQuery(q['intent']),
      // Start state of the "I will lead" switch on 'add'.
      initialLead: switch (q['lead']) {
        'false' => false,
        'true' => true,
        _ => null,
      },
    );
  }

  final String sessionId;
  final String? groupId;
  final String? initialKind;
  final GroupIntent intent;

  /// Where the "I will lead this group" switch starts for [GroupIntent.add]
  /// (null = on). "Add route" starts it off.
  final bool? initialLead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId));
    final groups = ref.watch(sessionGroupsProvider(sessionId));
    // "Lead a group" starts from the member's last group (not for routes or
    // "add a group", which are not "mine").
    final prefill =
        groupId == null && initialKind == null && intent == GroupIntent.lead;
    final last = prefill ? ref.watch(lastGroupSpecProvider(sessionId)) : null;
    final editing = groupId != null;
    Widget body;
    final s = session.value;
    if (s == null ||
        (editing && !groups.hasValue) ||
        (last?.isLoading ?? false)) {
      body = session.isLoading || groups.isLoading || (last?.isLoading ?? false)
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: Text("This run isn't available."));
    } else if (isEventLikeMode(s.groupMode)) {
      // Events and races have no pace or leaders (D79): an event's note is
      // edited from its card on the run page, so this screen never applies.
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Events have no pace groups. Change an event from its card on '
            'the run page.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      final existing = editing
          ? (groups.value ?? const <Group>[])
                .where((g) => g.id == groupId)
                .firstOrNull
          : null;
      body = editing && existing == null
          ? const Center(child: Text("This group isn't available."))
          : GroupForm(
              session: s,
              existing: existing,
              initialKind: initialKind,
              intent: intent,
              initialLead: initialLead,
              initialSpec: last?.value,
            );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit group'
              : intent == GroupIntent.add
              ? 'Add a group'
              : 'Lead a group',
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// The group form. Public so it can be pumped on its own in tests.
class GroupForm extends ConsumerStatefulWidget {
  const GroupForm({
    super.key,
    required this.session,
    this.existing,
    this.initialKind,
    this.intent = GroupIntent.lead,
    this.initialLead,
    this.initialSpec,
  });

  final Session session;
  final Group? existing;
  final String? initialKind;
  final GroupIntent intent;
  final bool? initialLead;

  /// The member's last group, used to pre-fill a new group.
  final LastGroupSpec? initialSpec;

  @override
  ConsumerState<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends ConsumerState<GroupForm> {
  final _formKey = GlobalKey<FormState>();
  late final PaceInputController _pace;
  late final DistanceInputController _distance;
  late final TextEditingController _label;
  late final TextEditingController _description;
  late String _kind;
  late bool _lead;
  bool _saving = false;

  /// The new group's client id, made ONCE per editor and reused by every save
  /// attempt. The server de-duplicates on `id` (a replay answers 200 with the
  /// same group), so pressing Save twice, or retrying after a slow or failed
  /// response, can never create two groups.
  final String _newGroupId = const Uuid().v4();

  /// The server's 422 message for `label`, shown on the field until it is
  /// edited (the client rule should catch it first; this is the safety net).
  String? _serverLabelError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    final prior = g == null ? widget.initialSpec : null;
    final units = ref.read(unitPrefsProvider);
    _pace = PaceInputController(
      initial: g?.pace ?? prior?.pace ?? const NoPace(),
      defaultUnit: units.paceUnit,
    );
    _distance = DistanceInputController(
      initial: g?.distance ?? prior?.distance,
      defaultUnit: units.distanceUnit,
    );
    _label = TextEditingController(text: g?.label ?? prior?.label ?? '');
    _description = TextEditingController(
      text: g?.description ?? prior?.description ?? '',
    );
    _kind =
        g?.kind ??
        widget.initialKind ??
        prior?.kind ??
        (widget.session.groupMode == 'routes' ? 'route' : 'run');
    _lead = widget.initialLead ?? true;
    // A snackbar from the previous screen (e.g. "already leading" with its
    // Open it action) is app-wide and would sit over the Save button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _pace.dispose();
    _distance.dispose();
    _label.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Whether this member may create a leaderless group. Watched in `build`
  /// (the membership may still be loading), read in event handlers.
  bool _canLeaderless({bool watch = false}) => canCreateLeaderless(
    session: widget.session,
    myMemberId: watch
        ? ref.watch(myMemberIdProvider)
        : ref.read(myMemberIdProvider),
    isCommittee: watch
        ? ref.watch(canManageRunsProvider)
        : ref.read(canManageRunsProvider),
  );

  /// Whether to ask "I will lead this group": a new group, opened through an
  /// "add" action, by someone allowed to create leaderless groups (D86).
  bool _showLeadSwitch({bool watch = false}) =>
      !_editing &&
      widget.intent == GroupIntent.add &&
      _canLeaderless(watch: watch);

  /// Awaits [write]; if the server answers 422 on `label`, shows that message
  /// on the label field, then rethrows so the usual SnackBar still appears.
  Future<Object?> _surfaceLabelError(Future<Object?> write) async {
    try {
      return await write;
    } on Object catch (e) {
      final message = ApiException.from(e).fieldErrors['label'];
      if (message != null && mounted) {
        setState(() => _serverLabelError = message);
        _formKey.currentState?.validate();
      }
      rethrow;
    }
  }

  Future<void> _save() async {
    // A save is already in flight: ignore the tap (the button is disabled too).
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final router = GoRouter.of(context);
    final repo = ref.read(groupsRepositoryProvider);
    final store = ref.read(lastGroupStoreProvider);
    final label = _label.text.trim();
    final description = _description.text.trim();
    final pace = _pace.spec;
    final distance = _distance.distance;
    // The switch only exists for "add a group" by someone who may create a
    // leaderless group (D86). Everyone else leads what they create (the server
    // returns 403 for a leaderless group from an ordinary member).
    final lead = _showLeadSwitch() ? _lead : true;
    // One group per leader per run (D108): don't even try a second led group.
    if (!_editing && lead) {
      final mine = groupLedBy(
        ref.read(sessionGroupsProvider(widget.session.id)).value ?? const [],
        ref.read(myMemberIdProvider),
      );
      if (mine != null) {
        showAlreadyLeading(context, widget.session, mine.id);
        return;
      }
    }
    setState(() => _saving = true);
    final done = await runWrite(
      context,
      ref,
      () => _surfaceLabelError(
        _editing
            ? repo.updateGroup(
                widget.session.id,
                widget.existing!.id,
                kind: _kind,
                label: label.isEmpty ? null : label,
                description: description.isEmpty ? null : description,
                pace: pace,
                distance: distance,
              )
            : () async {
                final g = await repo.createGroup(
                  widget.session.id,
                  id: _newGroupId,
                  kind: _kind,
                  label: label.isEmpty ? null : label,
                  description: description.isEmpty ? null : description,
                  pace: pace,
                  distance: distance,
                  lead: lead,
                );
                if (lead) await rememberLastGroup(store, widget.session, g);
                return g;
              }(),
      ),
      errorMessage: groupErrorMessage,
      errorAction: (e) => groupErrorAction(router, widget.session.id, e),
    );
    if (!mounted) return;
    if (done) {
      router.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep these live so `_save` (which only reads) sees who I am and which
    // group I lead on this run, for the one-group-per-leader check (D108).
    ref.watch(myMemberIdProvider);
    ref.watch(sessionGroupsProvider(widget.session.id));
    final route = _kind == 'route';
    final paceField = PaceInput(controller: _pace);
    final distanceField = DistanceInput(
      controller: _distance,
      label: route ? 'Distance' : 'Distance (optional)',
    );
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kind',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final k in groupKinds)
                DropdownMenuItem(
                  value: k,
                  child: Text(groupKindEditorLabel(k)),
                ),
            ],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          formGap,
          if (route) ...[
            Text('Distance', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            distanceField,
            formGap,
            Text('Pace', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            paceField,
          ] else ...[
            Text('Pace', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            paceField,
            formGap,
            distanceField,
          ],
          formGap,
          // The label is required while the pace is None, so this rebuilds
          // when the pace mode changes (like a `useEffect` on `mode`).
          ListenableBuilder(
            listenable: _pace,
            builder: (context, _) {
              final required = _pace.mode == PaceMode.none;
              return TextFormField(
                controller: _label,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => _serverLabelError = null,
                decoration: InputDecoration(
                  labelText: required ? 'Label (required)' : 'Label (optional)',
                  hintText: required
                      ? 'e.g. Jog/walk or Efforts'
                      : 'e.g. Easy 5k',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    checkGroupLabel(mode: _pace.mode, label: v ?? '') ??
                    _serverLabelError,
              );
            },
          ),
          formGap,
          TextFormField(
            controller: _description,
            maxLength: 1000,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: route
                  ? 'Route link or directions, and where to muster'
                  : 'Where we muster, how efforts are structured (e.g. 6 x '
                        '400 m), where faster runners wait',
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_showLeadSwitch(watch: true))
            _LeadSwitch(
              value: _lead,
              onChanged: (v) => setState(() => _lead = v),
            ),
          formGap,
          _Preview(
            listenable: Listenable.merge([
              _pace,
              _distance,
              _label,
              _description,
            ]),
            kind: _kind,
            pace: () => _pace.spec,
            distance: () => _distance.distance,
            label: () => _label.text.trim(),
            description: () => _description.text.trim(),
          ),
          formGap,
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editing ? 'Save changes' : 'Save group'),
          ),
        ],
      ),
    );
  }
}

class _LeadSwitch extends StatelessWidget {
  const _LeadSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('I will lead this group'),
    subtitle: const Text(
      'Turn off to create a group with no leader yet, such as a route.',
    ),
    value: value,
    onChanged: onChanged,
  );
}

class _Preview extends ConsumerWidget {
  const _Preview({
    required this.listenable,
    required this.kind,
    required this.pace,
    required this.distance,
    required this.label,
    required this.description,
  });

  final Listenable listenable;
  final String kind;
  final PaceSpec Function() pace;
  final Distance? Function() distance;
  final String Function() label;
  final String Function() description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitPrefsProvider);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        // The same heading the card will show.
        final heading = headingFor(
          kind: kind,
          label: label(),
          pace: pace(),
          distance: distance(),
          units: units,
        );
        final desc = description();
        return Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(groupKindIcon(kind), color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading.title,
                            key: const ValueKey('group-preview-spec'),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (heading.subtitle != null) Text(heading.subtitle!),
                        ],
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) Text(desc),
              ],
            ),
          ),
        );
      },
    );
  }
}
