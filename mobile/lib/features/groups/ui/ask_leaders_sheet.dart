import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/accounts_controller.dart';
import '../../../core/auth/session_expiry.dart';
import '../../../core/db/app_database.dart';
import '../../members/ui/member_avatar.dart';
import '../../membership/ui/membership_providers.dart';
import '../../messages/data/leader_pool_dtos.dart';
import '../../messages/data/messages_repository.dart';
import 'groups_providers.dart';

export '../logic/ask_stretch.dart' show askOpenFast, askOpenSlow;

/// What the committee is looking for when it asks (D127): a stretch of the pace
/// axis (seconds per km; 150 and 900 mean open ended, see `askOpenFast` and
/// `askOpenSlow`), a jog/walk group, or nothing specific (the whole run). `label`
/// is the phrase after "Ask for": "a group between 9:30 and 10:15/mi", "a group
/// faster than 8:30/mi", "a jog/walk group"; empty for the whole run.
typedef AskTarget = ({
  int? fastSPerKm,
  int? slowSPerKm,
  bool jogWalk,
  String label,
});

/// The committee's "can anyone lead?" sheet (D125, D127). It lists the people who
/// could lead the run (those who led its series or day before, or chose the day),
/// regulars first and those whose usual pace fits [target] at the top. **Send**
/// asks the ones picked by name, posts the ask in the run's leaders thread, then
/// opens the thread (unless [openThread] is false, when it is the screen asking).
/// Needs a connection.
Future<void> showAskLeadersSheet(
  BuildContext context,
  WidgetRef ref, {
  required Session session,
  required AskTarget target,
  bool openThread = true,
}) async {
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await showModalBottomSheet<AskResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AskSheet(session: session, target: target),
  );
  if (result == null) return;
  messenger.showSnackBar(SnackBar(content: Text(askResultText(result))));
  // Asked from inside the thread, it is already open.
  if (openThread) unawaited(router.push('/runs/${session.id}/leaders-chat'));
}

/// "Asked 3 leaders", with who was left out ("Asked 2 leaders (1 already
/// asked)"), or what happened when nobody could be asked.
String askResultText(AskResult result) {
  if (result.notified == 0) {
    return 'Nobody could be asked for that. It is in the leaders thread for '
        'the committee.';
  }
  final asked = result.notified == 1
      ? 'Asked 1 leader'
      : 'Asked ${result.notified} leaders';
  final counts = <String, int>{};
  for (final s in result.skipped) {
    final why = switch (s.reason) {
      'leading' => 'already leading',
      'not_going' => "can't make it",
      'asked_recently' => 'already asked',
      _ => 'not active',
    };
    counts[why] = (counts[why] ?? 0) + 1;
  }
  if (counts.isEmpty) return asked;
  return '$asked (${counts.entries.map((e) => '${e.value} ${e.key}').join(', ')})';
}

String _title(AskTarget target) {
  if (target.jogWalk) return 'Ask for a jog/walk group';
  return target.label.isEmpty ? 'Ask for leaders' : 'Ask for ${target.label}';
}

/// "Led 6 times · last 14 Oct at 9:15/mi", "Signed up to lead before", "Chose
/// this day in their settings" or "Leader, hasn't led yet": what the committee
/// knows about this person as a leader, in the viewer's units.
String poolSubtitle(PoolMember m, UnitPrefs units) {
  final last = m.lastLed;
  if (last == null) {
    return m.reason == 'new_leader'
        ? "Leader, hasn't led yet"
        : 'Chose this day in their settings';
  }
  final walk = last.isJogWalk && last.pace.isNone;
  final pace = walk ? 'jog/walk' : last.pace.display(units.paceUnit);
  final at = pace.isEmpty ? '' : (walk ? ', $pace' : ' at $pace');
  if (m.ledCount == 0) return 'Signed up to lead before$at';
  final times = switch (m.ledCount) {
    1 => 'Led once',
    2 => 'Led twice',
    final n => 'Led $n times',
  };
  final on = m.lastLedOn;
  final when = on == null ? '' : ' · last ${DateFormat('d MMM').format(on)}';
  return '$times$when$at';
}

class _AskSheet extends ConsumerStatefulWidget {
  const _AskSheet({required this.session, required this.target});

  final Session session;
  final AskTarget target;

  @override
  ConsumerState<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends ConsumerState<_AskSheet> {
  final _note = TextEditingController();
  final _picked = <String>{};
  List<PoolMember>? _pool;
  Object? _loadError;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final t = widget.target;
    try {
      final pool = await ref
          .read(messagesRepositoryProvider)
          .leaderPool(
            ref.read(activeClubIdProvider),
            widget.session.id,
            fastSPerKm: t.fastSPerKm,
            slowSPerKm: t.slowSPerKm,
            jogWalk: t.jogWalk,
          );
      if (mounted) {
        setState(() {
          _pool = pool;
          _loading = false;
        });
      }
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    if (_picked.isEmpty) {
      setState(() => _error = 'Pick at least one person');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final sub = ref.read(activeSubProvider);
    final handleExpiry = ref.read(sessionExpiryHandlerProvider);
    final t = widget.target;
    try {
      final result = await ref
          .read(messagesRepositoryProvider)
          .askForLeader(
            ref.read(activeClubIdProvider),
            widget.session.id,
            fastSPerKm: t.fastSPerKm,
            slowSPerKm: t.slowSPerKm,
            memberIds: _picked.toList(),
            jogWalk: t.jogWalk,
            note: _note.text,
          );
      if (mounted) navigator.pop(result);
    } on Object catch (e) {
      if (sub != null && await handleExpiry(sub, e)) {
        if (mounted) navigator.pop();
        return;
      }
      final api = ApiException.from(e);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = api.isNetworkError
            ? 'You need a connection to ask leaders.'
            : api.statusCode == 403
            ? 'Only the committee can ask for leaders.'
            : api.code == 'thread_closed'
            ? api.message
            : "Couldn't send that. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                Text(
                  _title(widget.target),
                  key: const ValueKey('ask-title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.session.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'People who have led this series or day before, or chose '
                  'this day in their settings. Nobody else is listed, so a '
                  "Monday leader isn't asked about a Thursday.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                ..._people(context),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('ask-note'),
                  controller: _note,
                  maxLength: 200,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Add a note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      key: const ValueKey('ask-error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const ValueKey('ask-send'),
                      onPressed: _busy ? null : () => unawaited(_send()),
                      child: Text(
                        _picked.length == 1
                            ? 'Send to 1 person'
                            : 'Send to ${_picked.length} people',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _people(BuildContext context) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_loadError != null) {
      final offline = ApiException.from(_loadError!).isNetworkError;
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                offline
                    ? 'You need a connection to see who could lead.'
                    : "Couldn't load who could lead.",
                key: const ValueKey('ask-load-error'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('ask-retry'),
                onPressed: () => unawaited(_load()),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ];
    }
    final pool = _pool ?? const <PoolMember>[];
    if (pool.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Nobody has led this series or day before, or chosen it in their '
            'settings.',
            key: ValueKey('ask-empty'),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }
    final fits = [
      for (final m in pool)
        if (m.canBeAsked && m.fitsRange) m,
    ];
    final others = [
      for (final m in pool)
        if (m.canBeAsked && !m.fitsRange) m,
    ];
    final blocked = [
      for (final m in pool)
        if (!m.canBeAsked) m,
    ];
    return [
      if (fits.isNotEmpty) ...[
        const _Section('Usually lead around here'),
        for (final m in fits) _row(m),
      ],
      if (others.isNotEmpty) ...[
        _Section(fits.isEmpty ? 'Previous leaders' : 'Other previous leaders'),
        for (final m in others) _row(m),
      ],
      if (blocked.isNotEmpty) ...[
        const _Section("Can't be asked"),
        for (final m in blocked) _row(m),
      ],
    ];
  }

  Widget _row(PoolMember m) {
    final units = ref.watch(unitPrefsProvider);
    final theme = Theme.of(context);
    final blocked = m.blockedReason;
    final tag = blocked ?? (m.reason == 'led_day' ? 'Same day' : null);
    return CheckboxListTile(
      key: ValueKey('pool-${m.memberId}'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _picked.contains(m.memberId),
      onChanged: blocked != null
          ? null
          : (v) => setState(() {
              _error = null;
              if (v ?? false) {
                _picked.add(m.memberId);
              } else {
                _picked.remove(m.memberId);
              }
            }),
      secondary: MemberAvatar(memberId: m.memberId, name: m.name, size: 36),
      title: Row(
        children: [
          Flexible(child: Text(m.name)),
          if (tag != null) ...[
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(tag, style: theme.textTheme.labelSmall),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(poolSubtitle(m, units)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
