/// Notification categories, the same keys the API uses (docs/data-model.md). Each
/// one is an Android notification channel, so users can also tune them in the OS.
class NotificationCategory {
  const NotificationCategory(this.key, this.name, this.description);

  final String key;
  final String name;
  final String description;
}

const notificationCategories = <NotificationCategory>[
  NotificationCategory(
    'club_updates',
    'Club updates',
    'News from the committee',
  ),
  NotificationCategory(
    'run_reminders',
    'Run reminders',
    'The morning of runs you usually come to, with quick answers',
  ),
  NotificationCategory(
    'group_matches',
    'Group matches',
    'New pace groups that match your pace',
  ),
  NotificationCategory(
    'my_group_changes',
    'My group changes',
    'Cancelled or moved runs and groups',
  ),
  NotificationCategory(
    'leaders_needed',
    'Leaders needed',
    'Runs that need a leader',
  ),
  NotificationCategory('group_messages', 'Group messages', 'Group chat'),
];

const defaultNotificationCategory = 'club_updates';

NotificationCategory notificationCategoryFor(String? key) =>
    notificationCategories.firstWhere(
      (c) => c.key == key,
      orElse: () => notificationCategories.first,
    );
