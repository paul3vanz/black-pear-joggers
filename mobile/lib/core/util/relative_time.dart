import 'package:intl/intl.dart';

/// "just now", "5 minutes ago", "3 hours ago", "2 days ago", then a plain date.
/// [now] is injectable so tests don't depend on the clock.
String relativeTime(DateTime then, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  return 'on ${DateFormat('d MMM yyyy').format(then)}';
}
