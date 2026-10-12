import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/db/app_database.dart';
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
import 'group_format.dart';
import 'groups_providers.dart';
import 'pace_input.dart';

/// `/runs/:sessionId/groups/new` and `/runs/:sessionId/groups/:groupId/edit`.
/// Creating a group is online-only (D23): errors show in a SnackBar and the
/// form stays on screen. [initialKind] / [initialLead] pre-fill "Add route".
class GroupEditorScreen extends ConsumerWidget {
  const GroupEditorScreen({
    super.key,
    required this.sessionId,
    this.groupId,
    this.initialKind,
    this.initialLead,
  });

  final String sessionId;
  final String? groupId;
  final String? initialKind;
  final bool? initialLead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId));
    final groups = ref.watch(sessionGroupsProvider(sessionId));
    // "Lead a group" starts from the member's last group (not for routes or
    // leaderless groups, which are not "mine").
    final prefill =
        groupId == null && initialKind == null && initialLead != false;
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
              initialLead: initialLead,
              initialSpec: last?.value,
            );
    }
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit group' : 'Lead a group')),
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
    this.initialLead,
    this.initialSpec,
  });

  final Session session;
  final Group? existing;
  final String? initialKind;
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
    if (!_formKey.currentState!.validate()) return;
    final router = GoRouter.of(context);
    final repo = ref.read(groupsRepositoryProvider);
    final store = ref.read(lastGroupStoreProvider);
    final label = _label.text.trim();
    final description = _description.text.trim();
    final pace = _pace.spec;
    final distance = _distance.distance;
    // Ordinary members must lead what they create (the server returns 403
    // otherwise), so the switch is ignored unless they may go leaderless.
    final lead = _canLeaderless() ? _lead : true;
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
    final route = _kind == 'route';
    final leaderless = _canLeaderless(watch: true);
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
          if (!_editing)
            _LeadSwitch(
              value: leaderless ? _lead : true,
              locked: !leaderless,
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
  const _LeadSwitch({
    required this.value,
    required this.locked,
    required this.onChanged,
  });

  final bool value;
  final bool locked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('I will lead this group'),
    subtitle: Text(
      locked
          ? 'You lead the groups you create.'
          : 'Turn off to create a group with no leader yet, such as a route.',
    ),
    value: value,
    onChanged: locked ? null : onChanged,
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
