import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../members/ui/member_avatar.dart';
import '../../membership/ui/membership_providers.dart';
import '../data/message_dtos.dart';
import '../data/messages_repository.dart';

/// "Who's in this chat": everyone who will see its messages (the leaders, the
/// coordinator and the members going or maybe going), as a photo and a short
/// name. Needs a connection.
Future<void> showChatMembersSheet(
  BuildContext context, {
  required String groupId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ChatMembersSheet(groupId: groupId),
);

class _ChatMembersSheet extends ConsumerStatefulWidget {
  const _ChatMembersSheet({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_ChatMembersSheet> createState() => _ChatMembersSheetState();
}

class _ChatMembersSheetState extends ConsumerState<_ChatMembersSheet> {
  late Future<List<ChatMember>> _members = _load();

  Future<List<ChatMember>> _load() => ref
      .read(messagesRepositoryProvider)
      .members(ref.read(activeClubIdProvider), widget.groupId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scroll) => FutureBuilder<List<ChatMember>>(
        future: _members,
        builder: (context, snapshot) {
          final Widget body;
          if (snapshot.connectionState != ConnectionState.done) {
            body = const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            final offline = ApiException.from(snapshot.error!).isNetworkError;
            body = Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    offline
                        ? 'You need a connection to see who is in this chat.'
                        : "Couldn't load who is in this chat.",
                    key: const ValueKey('chat-members-error'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _members = _load()),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          } else {
            final people = snapshot.data ?? const <ChatMember>[];
            body = Column(
              children: [
                for (final p in people)
                  ListTile(
                    key: ValueKey('chat-member-${p.memberId}'),
                    contentPadding: EdgeInsets.zero,
                    leading: MemberAvatar(
                      memberId: p.memberId,
                      name: p.name,
                      size: 36,
                    ),
                    title: Text(p.name),
                    trailing: p.roleLabel.isEmpty
                        ? null
                        : Text(
                            p.roleLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
              ],
            );
          }
          final count = snapshot.data?.length;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                count == null
                    ? "Who's in this chat"
                    : "Who's in this chat ($count)",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Everyone going to this run, its leaders and the coordinator '
                'see the messages here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              body,
            ],
          );
        },
      ),
    );
  }
}
