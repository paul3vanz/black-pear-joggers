/// The Inbox's smart views (D121), like Gmail's tabs: one list, filtered by the
/// notification category the server already sends. Nothing is stored; a
/// notification belongs to **All** and to at most one other view.
enum InboxFolder {
  all('All'),
  chats('Chats'),
  updates('Updates'),
  runs('Runs');

  const InboxFolder(this.label);

  final String label;

  /// Whether a notification of [category] shows in this view.
  bool holds(String category) => switch (this) {
    InboxFolder.all => true,
    InboxFolder.chats => category == 'group_messages',
    InboxFolder.updates => category == 'club_updates',
    InboxFolder.runs => const {
      'run_reminders',
      'group_matches',
      'my_group_changes',
      'leaders_needed',
    }.contains(category),
  };

  /// Whether the group chat threads list belongs in this view.
  bool get showsThreads => this == InboxFolder.all || this == InboxFolder.chats;

  /// What an empty view says.
  String get emptyText => switch (this) {
    InboxFolder.all => 'No notifications yet',
    InboxFolder.chats => 'No chat notifications',
    InboxFolder.updates => 'No club updates',
    InboxFolder.runs => 'No run notifications',
  };
}
