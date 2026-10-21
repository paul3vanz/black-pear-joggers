import '../../messages/data/message_dtos.dart' show isLeadersThread;

/// The Inbox's smart views (D121, D125), like Gmail's tabs: one list, filtered
/// by what the server already sends (category and route). Nothing is stored; a
/// notification belongs to **All** and to at most one other view.
enum InboxFolder {
  all('All'),
  chats('Chats'),
  leaders('Leaders'),
  updates('Updates'),
  runs('Runs');

  const InboxFolder(this.label);

  final String label;

  /// Whether a notification of [category], opening [route], shows in this view.
  /// The leaders thread (D125) has its own view: its messages and asks (whose
  /// category is `leaders_needed`) both open `/runs/<id>/leaders-chat`.
  bool holds(String category, {String? route}) {
    final leadersThread = route != null && route.endsWith('/leaders-chat');
    return switch (this) {
      InboxFolder.all => true,
      InboxFolder.leaders => leadersThread,
      InboxFolder.chats => category == 'group_messages' && !leadersThread,
      InboxFolder.updates => category == 'club_updates',
      InboxFolder.runs =>
        !leadersThread &&
            const {
              'run_reminders',
              'group_matches',
              'my_group_changes',
              'leaders_needed',
            }.contains(category),
    };
  }

  /// Whether a chat thread ([threadId]: a group id or `leaders:<run>`) is listed
  /// in this view.
  bool holdsThread(String threadId) => switch (this) {
    InboxFolder.all => true,
    InboxFolder.chats => !isLeadersThread(threadId),
    InboxFolder.leaders => isLeadersThread(threadId),
    _ => false,
  };

  /// Whether the chat threads list belongs in this view.
  bool get showsThreads =>
      this == InboxFolder.all ||
      this == InboxFolder.chats ||
      this == InboxFolder.leaders;

  /// What an empty view says.
  String get emptyText => switch (this) {
    InboxFolder.all => 'No notifications yet',
    InboxFolder.chats => 'No chat notifications',
    InboxFolder.leaders => 'Nothing from the leaders thread',
    InboxFolder.updates => 'No club updates',
    InboxFolder.runs => 'No run notifications',
  };
}
