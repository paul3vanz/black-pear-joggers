import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../groups/data/group_dtos.dart';
import '../../groups/data/plan_dtos.dart';
import '../../groups/ui/attendance_actions.dart';
import '../../groups/ui/group_access.dart';
import '../../groups/ui/group_actions.dart';
import '../../groups/ui/group_format.dart';
import '../../groups/ui/groups_providers.dart';
import '../../messages/ui/messages_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../../runs/ui/session_actions.dart';
import '../logic/event_access.dart';
import 'event_card.dart';
import 'event_picker_sheet.dart';

/// "Where are you running?" on an `events` run (D79): a card per event the
/// club has picked for that day, plus "Add a parkrun / event". It replaces the
/// pace groups section (no pace, leaders or coverage here).
///
/// A stateful widget only because it remembers which card to scroll to after
/// you add an event (like a `useRef` + `useEffect` in React).
class EventsSection extends ConsumerStatefulWidget {
  const EventsSection({super.key, required this.session});

  final Session session;

  @override
  ConsumerState<EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends ConsumerState<EventsSection> {
  Session get session => widget.session;
  String get _base => '/runs/${session.id}/groups';

  /// One key per card so [Scrollable.ensureVisible] can find it.
  final _keys = <String, GlobalKey>{};
  String? _scrollTo;

  void _scrollWhenBuilt() {
    final id = _scrollTo;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[id]?.currentContext;
      if (ctx == null || !mounted) return; // not in the list yet: next build
      _scrollTo = null;
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
        ),
      );
    });
  }

  Future<void> _add(BuildContext context, List<Group> groups) async {
    final messenger = ScaffoldMessenger.of(context);
    final pick = await showEventPicker(
      context,
      ref,
      clubId: session.clubId,
      sessionId: session.id,
      usedLocationIds: [for (final g in groups) ?g.locationId],
      allowCreate: true,
    );
    if (pick == null || !context.mounted) return;
    ({Group group, bool existed})? added;
    final ok = await groupWrite(context, ref, (repo) async {
      added = await repo.addEventGroup(
        session.id,
        locationId: pick.locationId,
        label: pick.isFreeText ? pick.name : null,
      );
      return added;
    });
    final result = added;
    if (!ok || result == null || !mounted) return;
    ref.invalidate(planLoadProvider(session.id)); // fetch the names
    setState(() => _scrollTo = result.group.id);
    final name = result.group.label ?? pick.name;
    // The server de-duplicates by location (D78): an existing event is just
    // joined, and has a note already.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.existed
              ? "You're going to $name"
              : 'Added $name. You are going.',
        ),
        action: result.existed
            ? null
            : SnackBarAction(
                label: 'Add a note for car sharing',
                onPressed: () {
                  if (mounted) unawaited(_editNote(result.group));
                },
              ),
      ),
    );
  }

  Future<void> _editNote(Group g) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: g.description ?? ''),
    );
    if (text == null || !mounted) return;
    await groupWrite(
      context,
      ref,
      (repo) => repo.updateGroup(
        session.id,
        g.id,
        kind: 'event',
        label: g.label,
        description: text.isEmpty ? null : text,
        distance: g.distance,
      ),
      success: 'Note saved',
    );
  }

  Future<void> _remove(Group g) async {
    final ok = await confirm(
      context,
      title: 'Remove this event?',
      message:
          'People who picked it will be left going with no event chosen, '
          'and its chat goes with it.',
      action: 'Remove',
    );
    if (!ok || !mounted) return;
    await groupWrite(
      context,
      ref,
      (repo) => repo.deleteGroup(session.id, g.id),
      success: 'Event removed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ref.watch(sessionGroupsProvider(session.id)).value ?? [];
    final units = ref.watch(unitPrefsProvider);
    final resp = myResponse(ref, session.id);
    final myId = ref.watch(myMemberIdProvider);
    final isCommittee = ref.watch(canManageRunsProvider);
    final open = isRunOpen(session, ref.watch(groupsClockProvider)());
    final summary = ref.watch(sessionSummaryProvider(session.id)).value;
    // Names come from the plan (online-only, last response cached). Watching
    // the load is what fetches it; a failure just means no names (D77).
    ref.watch(planLoadProvider(session.id));
    final plan = ref.watch(sessionPlanProvider(session.id)).value;
    final namesAnyway = canCreateLeaderless(
      session: session,
      myMemberId: myId,
      isCommittee: isCommittee,
    );
    _scrollWhenBuilt();

    final inEvents = groups.fold<int>(0, (n, g) => n + g.goingCount);
    final noEvent = (summary?.goingCount ?? 0) - inEvents;
    final addButton = open && myId != null
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => unawaited(_add(context, groups)),
                icon: const Icon(Icons.add),
                label: const Text('Add a parkrun / event'),
              ),
            ),
          )
        : const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          groupsHeading(session.groupMode),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(groupsIntro(session.groupMode), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nobody has picked a parkrun yet.'),
            ),
          )
        else
          for (final g in groups)
            _card(
              g,
              key: _keys.putIfAbsent(g.id, GlobalKey.new),
              units: units,
              resp: resp,
              myId: myId,
              isCommittee: isCommittee,
              open: open,
              plan: plan,
              showNames: namesAnyway,
            ),
        if (noEvent > 0 && groups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$noEvent going, event not chosen yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        addButton,
      ],
    );
  }

  Widget _card(
    Group g, {
    required Key key,
    required UnitPrefs units,
    required MyResponse resp,
    required String? myId,
    required bool isCommittee,
    required bool open,
    required SessionPlan? plan,
    required bool showNames,
  }) {
    final mine = resp.groupId == g.id && resp.status != 'not_going';
    final canEdit =
        open &&
        canEditEvent(
          group: g,
          coordinatorMemberId: session.coordinatorMemberId,
          myMemberId: myId,
          isCommittee: isCommittee,
        );
    // Names only while you are in the event (or you manage the run): a cached
    // plan from before you left must not keep showing them.
    final names = mine || showNames
        ? [
            for (final a in plan?.forGroup(g.id)?.attendees ?? <PlanAttendee>[])
              if (a.memberId != myId) a,
          ]
        : <PlanAttendee>[];
    return EventCard(
      key: key,
      title: g.label ?? groupKindLabel(g.kind),
      distance: distanceText(g.distance, units),
      note: g.description,
      going: g.goingCount,
      maybe: g.maybeCount,
      isMine: mine,
      fellowAttendees: names,
      onJoin: open && !mine
          ? () => unawaited(
              respondToRun(
                context,
                ref,
                session: session,
                status: 'going',
                groupId: g.id,
              ),
            )
          : null,
      // Mirrors "Leave group" on pace groups (D85): back to going, no event.
      onLeave: open && mine
          ? () => unawaited(
              respondToRun(context, ref, session: session, status: 'going'),
            )
          : null,
      onChat:
          canChatIn(
            group: g,
            session: session,
            myMemberId: myId,
            inGroup: mine,
            isCommittee: isCommittee,
          )
          ? () => unawaited(context.push('$_base/${g.id}/chat'))
          : null,
      chatUnread:
          (ref.watch(threadStateProvider(g.id)).value?.unreadCount ?? 0) > 0,
      onEditNote: canEdit ? () => unawaited(_editNote(g)) : null,
      onRemove:
          open &&
              canRemoveEvent(
                mode: session.groupMode,
                group: g,
                coordinatorMemberId: session.coordinatorMemberId,
                myMemberId: myId,
                isCommittee: isCommittee,
              )
          ? () => unawaited(_remove(g))
          : null,
    );
  }
}

/// The note editor: a multi-line field with a counter (max 1000, the server's
/// limit). Pops the trimmed text (empty clears the note) or null on Cancel.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});

  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  // A controller owns the field's text, like a controlled input's state in
  // React; it must be disposed (hence the StatefulWidget).
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Note for this event'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      minLines: 3,
      maxLines: 6,
      maxLength: eventNoteMaxLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: eventNoteHint),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: const Text('Save'),
      ),
    ],
  );
}

/// The server's limit for an event note (`description`).
const eventNoteMaxLength = 1000;
const eventNoteHint =
    'e.g. Meeting at 8:15 at the Co-op car park, 2 seats spare';
