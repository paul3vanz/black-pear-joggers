import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../../runs/ui/session_actions.dart';
import '../data/member_dtos.dart';
import '../data/members_repository.dart';

/// The role list to send for the switches: `setRoles` replaces the whole set,
/// so this is always the full intended list, in the server's order.
List<String> rolesToSend({
  required bool leader,
  required bool committee,
  required bool admin,
}) => [if (leader) 'leader', if (committee) 'committee', if (admin) 'admin'];

/// Shows the roles of [member] as switches and saves them. Returns the updated
/// member, or null if dismissed or nothing changed.
Future<MemberItem?> showRolesSheet(
  BuildContext context,
  WidgetRef ref, {
  required MemberItem member,
  required bool isSelf,
  required bool isAdmin,
}) => showModalBottomSheet<MemberItem>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => RolesSheet(member: member, isSelf: isSelf, isAdmin: isAdmin),
);

class RolesSheet extends ConsumerStatefulWidget {
  const RolesSheet({
    super.key,
    required this.member,
    required this.isSelf,
    required this.isAdmin,
  });

  final MemberItem member;
  final bool isSelf;
  final bool isAdmin;

  @override
  ConsumerState<RolesSheet> createState() => _RolesSheetState();
}

class _RolesSheetState extends ConsumerState<RolesSheet> {
  late bool _leader = widget.member.roles.contains('leader');
  late bool _committee = widget.member.roles.contains('committee');
  late bool _admin = widget.member.roles.contains('admin');
  bool _saving = false;
  String? _error;

  bool get _changed =>
      _leader != widget.member.roles.contains('leader') ||
      _committee != widget.member.roles.contains('committee') ||
      _admin != widget.member.roles.contains('admin');

  Future<void> _save() async {
    final removingOwnAdmin =
        widget.isSelf && widget.member.roles.contains('admin') && !_admin;
    if (removingOwnAdmin) {
      final ok = await confirm(
        context,
        title: 'Remove your admin role?',
        message: "You'll lose admin access. Make sure another admin exists.",
        action: 'Remove',
      );
      if (!ok || !mounted) return;
    }
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(membersRepositoryProvider);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await repo.setRoles(
        clubId,
        widget.member.memberId,
        rolesToSend(leader: _leader, committee: _committee, admin: _admin),
      );
      if (mounted) navigator.pop(saved);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiException.from(e).statusCode == 403
            ? 'Only an admin can change committee or admin roles.'
            : runsErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminOnly = widget.isAdmin ? null : 'Only an admin can change this.';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.member.displayName, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Leader badge'),
              subtitle: const Text('Shown beside their name as a run leader.'),
              value: _leader,
              onChanged: _saving ? null : (v) => setState(() => _leader = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Committee'),
              subtitle: Text(
                adminOnly ?? 'Can manage runs, groups and club updates.',
              ),
              value: _committee,
              onChanged: _saving || !widget.isAdmin
                  ? null
                  : (v) => setState(() => _committee = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Admin'),
              subtitle: Text(
                adminOnly ?? 'Everything the committee can do, and roles.',
              ),
              value: _admin,
              onChanged: _saving || !widget.isAdmin
                  ? null
                  : (v) => setState(() => _admin = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving || !_changed ? null : () => unawaited(_save()),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save roles'),
            ),
          ],
        ),
      ),
    );
  }
}
