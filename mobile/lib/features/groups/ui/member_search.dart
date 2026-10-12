import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../../members/ui/member_avatar.dart';
import '../data/member_dtos.dart';
import '../data/members_repository.dart';

/// "Leader", "Committee", "Admin".
String roleLabel(String role) => switch (role) {
  'leader' => 'Leader',
  'committee' => 'Committee',
  'admin' => 'Admin',
  _ => role,
};

/// A search box plus the matching members (committee tools): debounced
/// `MembersRepository.search`, name, an active/lapsed chip and role chips.
/// Shared by the coordinator picker and the members and roles screen. The
/// server returns at most 50, so a long list says to narrow the search.
class MemberSearchList extends ConsumerStatefulWidget {
  const MemberSearchList({
    super.key,
    required this.onSelect,
    this.debounce = const Duration(milliseconds: 300),
  });

  final void Function(MemberItem member) onSelect;
  final Duration debounce;

  @override
  ConsumerState<MemberSearchList> createState() => MemberSearchListState();
}

class MemberSearchListState extends ConsumerState<MemberSearchList> {
  static const pageSize = 50;

  final _controller = TextEditingController();
  Timer? _timer;
  List<MemberItem> _items = const [];
  Object? _error;
  bool _loading = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Swaps in an updated member (after a role change) without a new search.
  void replace(MemberItem member) {
    setState(() {
      _items = [
        for (final m in _items) m.memberId == member.memberId ? member : m,
      ];
    });
  }

  void _onChanged(String _) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => unawaited(_load()));
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final clubId = ref.read(activeClubIdProvider);
    final repo = ref.read(membersRepositoryProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await repo.search(
        clubId,
        _controller.text.trim(),
        limit: pageSize,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = <Widget>[
      if (_loading) const LinearProgressIndicator(),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(runsErrorMessage(_error!))),
              TextButton(
                onPressed: () => unawaited(_load()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      if (!_loading && _error == null && _items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No members found.'),
        ),
      for (final m in _items)
        ListTile(
          key: ValueKey(m.memberId),
          // Avatar only: the row's own tap action selects the member (D69).
          leading: MemberAvatar(memberId: m.memberId, name: m.displayName),
          title: Text(m.displayName),
          subtitle: _Chips(member: m),
          onTap: () => widget.onSelect(m),
        ),
      if (_items.length >= pageSize)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Showing the first $pageSize. Type a name to narrow it down.',
            style: theme.textTheme.bodySmall,
          ),
        ),
    ];
    final field = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          labelText: 'Search members',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    );
    return Column(
      children: [
        field,
        Expanded(child: ListView(children: results)),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.member});

  final MemberItem member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      children: [
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(member.status == 'active' ? 'Active' : 'Lapsed'),
          backgroundColor: member.status == 'active'
              ? scheme.secondaryContainer
              : scheme.errorContainer,
        ),
        for (final r in member.roles)
          Chip(visualDensity: VisualDensity.compact, label: Text(roleLabel(r))),
      ],
    );
  }
}
