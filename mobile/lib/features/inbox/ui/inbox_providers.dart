import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/accounts_controller.dart';
import '../../../core/db/app_database.dart';
import '../data/inbox_repository.dart';

/// Live cached inbox for a club, newest first. Hand-written (see profileProvider).
final inboxProvider = StreamProvider.family<List<InboxItem>, int>(
  (ref, clubId) => ref.watch(inboxRepositoryProvider).watchInbox(clubId),
);

/// Number of unread inbox items, for the tab badge. Empty while signed out.
final unreadCountProvider = StreamProvider.family<int, int>((ref, clubId) {
  if (ref.watch(activeSubProvider) == null) return const Stream.empty();
  return ref.watch(inboxRepositoryProvider).watchUnreadCount(clubId);
});
