import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../membership/ui/membership_providers.dart';
import '../data/safety_repository.dart';
import 'safety_actions.dart';
import 'safety_providers.dart';

/// Profile > About & privacy > Blocked members (`/profile/about/blocked`).
class BlockedMembersScreen extends ConsumerStatefulWidget {
  const BlockedMembersScreen({super.key});

  @override
  ConsumerState<BlockedMembersScreen> createState() =>
      _BlockedMembersScreenState();
}

class _BlockedMembersScreenState extends ConsumerState<BlockedMembersScreen> {
  @override
  void initState() {
    super.initState();
    // Catch up with the server (a block made on another phone); offline keeps
    // the saved list.
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      await ref
          .read(safetyRepositoryProvider)
          .refresh(ref.read(activeClubIdProvider));
    } on Object {
      // Offline: the saved list is shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedMembersProvider).value ?? const {};
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked members')),
      body: SafeArea(
        child: blocked.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "You haven't blocked anyone. To block someone, press and "
                    'hold one of their messages, or open their profile.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            : ListView(
                children: [
                  for (final e in blocked.entries)
                    ListTile(
                      key: ValueKey('blocked-${e.key}'),
                      leading: const Icon(Icons.block),
                      title: Text(e.value),
                      trailing: TextButton(
                        onPressed: () => unawaited(
                          unblockMember(
                            context,
                            ref,
                            memberId: e.key,
                            name: e.value,
                          ),
                        ),
                        child: const Text('Unblock'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
