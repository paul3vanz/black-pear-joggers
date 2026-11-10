import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/units/distance.dart';
import '../../../core/util/open_link.dart';
import '../../runs/ui/session_actions.dart';
import '../data/groups_repository.dart';
import '../data/route_dtos.dart';
import 'distance_input.dart';
import 'group_format.dart';
import 'groups_providers.dart';

/// The routes set for a run (D130), e.g. a 10 and a 14 mile route for a long
/// run. Every member can open them, going or not, so they can look ahead; the
/// committee and the run's coordinator add, edit and delete them. Groups pick
/// one in the group editor. Hidden when there are none and the caller cannot
/// add any.
class RoutesCard extends ConsumerWidget {
  const RoutesCard({
    super.key,
    required this.session,
    required this.canManage,
    required this.open,
  });

  final Session session;

  /// The caller is the committee, an admin or this run's coordinator.
  final bool canManage;

  /// The run is neither cancelled nor finished (the server refuses edits after).
  final bool open;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SessionRoute route,
  ) async {
    final ok = await confirm(
      context,
      title: 'Delete this route?',
      message: 'Groups that chose it will be left with no route.',
      action: 'Delete',
    );
    if (!ok || !context.mounted) return;
    await runWrite(
      context,
      ref,
      () =>
          ref.read(groupsRepositoryProvider).deleteRoute(session.id, route.id),
      success: 'Route deleted',
      errorMessage: groupErrorMessage,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(sessionRoutesProvider(session.id)).value ?? [];
    final units = ref.watch(unitPrefsProvider);
    final canEdit = canManage && open;
    if (routes.isEmpty && !canEdit) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (routes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'None set. Add the routes for this run and leaders can '
                  'pick one for their group.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            for (final r in routes)
              ListTile(
                key: ValueKey('route-${r.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(r.label),
                subtitle: r.distance == null
                    ? null
                    : Text(r.distance!.display(units.distanceUnit)),
                leading: const Icon(Icons.map_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (routeUri(r.url) != null)
                      TextButton(
                        onPressed: () =>
                            unawaited(openLink(context, ref, routeUri(r.url)!)),
                        child: const Text('View route'),
                      ),
                    if (canEdit)
                      PopupMenuButton<String>(
                        tooltip: 'Route actions',
                        onSelected: (v) => v == 'edit'
                            ? unawaited(showRouteDialog(context, session, r))
                            : unawaited(_delete(context, ref, r)),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                  ],
                ),
              ),
            if (canEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('add-session-route'),
                  onPressed: () => unawaited(showRouteDialog(context, session)),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a route'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Add ([existing] null) or edit a route of [session].
Future<void> showRouteDialog(
  BuildContext context,
  Session session, [
  SessionRoute? existing,
]) => showDialog<void>(
  context: context,
  builder: (_) => _RouteDialog(session: session, existing: existing),
);

class _RouteDialog extends ConsumerStatefulWidget {
  const _RouteDialog({required this.session, this.existing});

  final Session session;
  final SessionRoute? existing;

  @override
  ConsumerState<_RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends ConsumerState<_RouteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _url;
  late final DistanceInputController _distance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _label = TextEditingController(text: r?.label ?? '');
    _url = TextEditingController(text: r?.url ?? '');
    _distance = DistanceInputController(
      initial: r?.distance,
      defaultUnit: ref.read(unitPrefsProvider).distanceUnit,
    );
  }

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final repo = ref.read(groupsRepositoryProvider);
    final label = _label.text.trim();
    final url = _url.text.trim();
    final Distance? distance = _distance.distance;
    setState(() => _saving = true);
    final done = await runWrite(
      context,
      ref,
      () => widget.existing == null
          ? repo.createRoute(
              widget.session.id,
              label: label,
              url: url,
              distance: distance,
            )
          : repo.updateRoute(
              widget.session.id,
              widget.existing!.id,
              label: label,
              url: url,
              distance: distance,
            ),
      errorMessage: groupErrorMessage,
    );
    if (!mounted) return;
    if (done) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Add a route' : 'Edit route'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _label,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. 10 mile route',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Give the route a name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _url,
              maxLength: 500,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Route link',
                hintText: 'https://www.plotaroute.com/route/403075',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Add the link to the route'
                  : checkRouteUrl(v),
            ),
            const SizedBox(height: 8),
            DistanceInput(controller: _distance),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('Save'),
      ),
    ],
  );
}
