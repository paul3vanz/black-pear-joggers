import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/db/app_database.dart';
import '../data/messages_repository.dart';

// Hand-written (not @riverpod): riverpod_generator can't see Drift's row types.

/// The cached messages of a group's thread, oldest first.
final threadMessagesProvider =
    StreamProvider.family<List<GroupMessage>, String>(
      (ref, groupId) =>
          ref.watch(messagesRepositoryProvider).watchThread(groupId),
    );

/// The caller's state for a thread (unread, muted, closed); null when unknown.
final threadStateProvider = StreamProvider.family<ThreadState?, String>(
  (ref, groupId) =>
      ref.watch(messagesRepositoryProvider).watchThreadState(groupId),
);

/// The caller's threads that have messages, newest first (Inbox section).
final threadsProvider = StreamProvider.family<List<ThreadState>, int>((
  ref,
  clubId,
) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  return ref.watch(messagesRepositoryProvider).watchThreads(clubId);
});

/// Whether the "Everyone in this group can see your name" line was dismissed.
final chatInfoDismissedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(messagesRepositoryProvider).isInfoDismissed(),
);

/// The group whose chat screen is open right now (see [openChatGroupIdProvider]).
class OpenChatGroup extends Notifier<String?> {
  @override
  String? build() => null;

  // A method, not `state = ` from outside: Notifier state is only settable from
  // inside the notifier (like a reducer).
  void open(String groupId) => state = groupId;

  void close(String groupId) {
    // A late call after the app scope is torn down (tests, sign-out) is a no-op.
    if (ref.mounted && state == groupId) state = null;
  }
}

/// The group whose chat screen is open, or null. A foreground push for it is
/// not shown as a notification (the screen refreshes at once instead).
final openChatGroupIdProvider = NotifierProvider<OpenChatGroup, String?>(
  OpenChatGroup.new,
);
