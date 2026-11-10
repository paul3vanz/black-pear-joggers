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
import '../data/route_dtos.dart';
import '../logic/ask_stretch.dart';
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
    this.askedFastSPerKm,
    this.askedSlowSPerKm,
    this.askedJogWalk = false,
  });

  /// The new-group screen for a route like
  /// `/runs/a/groups/new?intent=add&kind=route&lead=false`. Shared by the
  /// router and the tests, so the query parameters mean one thing.
  factory GroupEditorScreen.fromUri(String sessionId, Uri uri) {
    final q = uri.queryParameters;
    final intent = GroupIntent.fromQuery(q['intent']);
    // "I can lead" on an ask carries what the committee is looking for (D127):
    // `fast` and `slow` (seconds per km) or `kind=jog_walk`. That is a request, not
    // "Add route", so it must not stand in for the form's own kind.
    final asked = intent == GroupIntent.lead;
    final askedJogWalk = asked && q['kind'] == 'jog_walk';
    return GroupEditorScreen(
      sessionId: sessionId,
      initialKind: askedJogWalk ? null : q['kind'],
      askedFastSPerKm: asked ? int.tryParse(q['fast'] ?? '') : null,
      askedSlowSPerKm: asked ? int.tryParse(q['slow'] ?? '') : null,
      askedJogWalk: askedJogWalk,
      // 'lead' (default) or 'add' (D86).
      intent: intent,
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

  /// What the committee asked for when this was opened from "I can lead" (D127):
  /// a stretch of the pace axis in seconds per km (150 and 900 mean open ended), or
  /// a jog/walk group. A hint and a starting point only: the member's own last
  /// group always wins.
  final int? askedFastSPerKm;
  final int? askedSlowSPerKm;
  final bool askedJogWalk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId));
    final groups = ref.watch(sessionGroupsProvider(sessionId));
    // "Lead a group" starts from the member's last group (not for routes or
    // "add a group", which are not "mine").
    final prefill =
        groupId == null && initialKind == null && intent == GroupIntent.lead;
    final last = prefill ? ref.watch(leadFormSpecProvider(sessionId)) : null;
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
              askedFastSPerKm: askedFastSPerKm,
              askedSlowSPerKm: askedSlowSPerKm,
              askedJogWalk: askedJogWalk,
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
    this.askedFastSPerKm,
    this.askedSlowSPerKm,
    this.askedJogWalk = false,
  });

  final Session session;
  final Group? existing;
  final String? initialKind;
  final GroupIntent intent;
  final bool? initialLead;

  /// The member's last group, used to pre-fill a new group.
  final LastGroupSpec? initialSpec;

  /// What the committee asked for (see [GroupEditorScreen.askedFastSPerKm]).
  final int? askedFastSPerKm;
  final int? askedSlowSPerKm;
  final bool askedJogWalk;

  @override
  ConsumerState<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends ConsumerState<GroupForm> {
  final _formKey = GlobalKey<FormState>();
  late final PaceInputController _pace;
  late final DistanceInputController _distance;
  late final TextEditingController _label;
  late final TextEditingController _description;
  late final TextEditingController _routeUrl;

  /// What the route picker shows: [_noRoute], [_ownLink] or the id of one of the
  /// run's routes (D130).
  late String _routeChoice;
  static const _noRoute = '__none';
  static const _ownLink = '__link';
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
    var prior = g == null ? widget.initialSpec : null;
    // Asked for a jog/walk group: take the distance from their last group, but a
    // pace and name that belong to a different kind of group would be wrong.
    if (prior != null && widget.askedJogWalk && prior.kind != 'jog_walk') {
      prior = LastGroupSpec(kind: 'jog_walk', distance: prior.distance);
    }
    final units = ref.read(unitPrefsProvider);
    _pace = PaceInputController(
      initial: g?.pace ?? prior?.pace ?? const NoPace(),
      defaultUnit: units.paceUnit,
    );
    _distance = DistanceInputController(
      initial: g?.distance ?? prior?.distance,
      defaultUnit: units.distanceUnit,
    );
    final askedWalk = g == null && widget.askedJogWalk;
    _label = TextEditingController(
      text: g?.label ?? prior?.label ?? (askedWalk ? 'Jog/walk' : ''),
    );
    _description = TextEditingController(
      text: g?.description ?? prior?.description ?? '',
    );
    _routeUrl = TextEditingController(text: g?.routeUrl ?? '');
    _routeChoice = g?.routeId ?? (g?.routeUrl != null ? _ownLink : _noRoute);
    _kind =
        g?.kind ??
        widget.initialKind ??
        (askedWalk ? 'jog_walk' : null) ??
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
    _routeUrl.dispose();
    super.dispose();
  }

  /// The line above the form for "Lead a group" (D127): where the pre-filled values came
  /// from and, when opened from an ask, what the committee is looking for. Their
  /// own usual pace always wins; with no history the stretch is only offered, with a
  /// button that fills its middle. Null when there is nothing to say.
  Widget? _hint(BuildContext context) {
    if (_editing || widget.intent != GroupIntent.lead) return null;
    final unit = ref.read(unitPrefsProvider).paceUnit;
    final spec = widget.initialSpec;
    final stretch = widget.askedJogWalk
        ? 'a jog/walk group'
        : stretchPhrase(
            fastSPerKm: widget.askedFastSPerKm,
            slowSPerKm: widget.askedSlowSPerKm,
            unit: unit,
          );
    final filled = spec == null || widget.askedJogWalk
        ? null
        : 'Filled in from your last group'
              '${spec.sourceTitle == null ? '' : ' on ${spec.sourceTitle}'}.';
    final String text;
    if (filled != null && stretch != null) {
      text = spec!.pace.isNone
          ? '$filled The committee is looking for $stretch.'
          : '$filled The committee is looking for $stretch, but your usual '
                'pace wins.';
    } else if (filled != null) {
      text = filled;
    } else if (stretch != null) {
      text = 'The committee is looking for $stretch.';
    } else {
      return null;
    }
    final middle = widget.askedJogWalk
        ? null
        : stretchMiddle(
            fastSPerKm: widget.askedFastSPerKm,
            slowSPerKm: widget.askedSlowSPerKm,
            unit: unit,
          );
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        key: const ValueKey('lead-hint'),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
              if (middle != null)
                ListenableBuilder(
                  listenable: _pace,
                  builder: (context, _) => _pace.mode == PaceMode.none
                      ? TextButton(
                          key: const ValueKey('lead-hint-use'),
                          onPressed: () {
                            _pace.setMode(PaceMode.single);
                            _pace.setUnit(unit);
                            _pace.fast.text = middle.format();
                          },
                          child: Text('Use ${middle.format()}/${unit.code}'),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
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

  /// Choosing a run route also fills in the distance when none is typed yet.
  void _pickRoute(String choice, List<SessionRoute> routes) {
    setState(() => _routeChoice = choice);
    final route = routes.where((r) => r.id == choice).firstOrNull;
    final d = route?.distance;
    if (d != null && _distance.text.text.trim().isEmpty) {
      _distance.text.text = Distance.formatValue(d.value);
      _distance.setUnit(d.unit);
    }
  }

  /// The route picker (when the run has routes) and the link field (D130).
  List<Widget> _routeFields() {
    final routes =
        ref.watch(sessionRoutesProvider(widget.session.id)).value ?? const [];
    final showLink = routes.isEmpty || _routeChoice == _ownLink;
    final known =
        _routeChoice == _noRoute ||
        _routeChoice == _ownLink ||
        routes.any((r) => r.id == _routeChoice);
    return [
      if (routes.isNotEmpty) ...[
        DropdownButtonFormField<String>(
          key: const ValueKey('route-picker'),
          initialValue: known ? _routeChoice : _noRoute,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Route (optional)',
            helperText: 'Pick one of the routes set for this run.',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: _noRoute, child: Text('No route')),
            for (final r in routes)
              DropdownMenuItem(
                value: r.id,
                child: Text(
                  r.distance == null
                      ? r.label
                      : '${r.label} (${r.distance!.format()})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const DropdownMenuItem(value: _ownLink, child: Text('Other link…')),
          ],
          onChanged: (v) => _pickRoute(v ?? _noRoute, routes),
        ),
        formGap,
      ],
      if (showLink)
        TextFormField(
          controller: _routeUrl,
          maxLength: 500,
          keyboardType: TextInputType.url,
          autocorrect: false,
          validator: checkRouteUrl,
          decoration: const InputDecoration(
            labelText: 'Route link (optional)',
            hintText: 'https://www.plotaroute.com/route/403075',
            helperText:
                'Every member can open it, whether or not they are going.',
            border: OutlineInputBorder(),
          ),
        ),
    ];
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
    final routes =
        ref.read(sessionRoutesProvider(widget.session.id)).value ?? const [];
    // Without run routes there is only the link field. With them, a group has one
    // of the routes or its own link, never both.
    final useLink = routes.isEmpty || _routeChoice == _ownLink;
    final routeUrl = useLink ? _routeUrl.text.trim() : '';
    final routeId = useLink || _routeChoice == _noRoute ? null : _routeChoice;
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
                routeUrl: routeUrl.isEmpty ? null : routeUrl,
                routeId: routeId,
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
                  routeUrl: routeUrl.isEmpty ? null : routeUrl,
                  routeId: routeId,
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
          ?_hint(context),
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
          formGap,
          ..._routeFields(),
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
