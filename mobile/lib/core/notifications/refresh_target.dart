/// What a push notification's `data` map says needs refreshing. Pure, so it is
/// unit-tested without Firebase or a database.
class RefreshTarget {
  const RefreshTarget({
    this.sessionId,
    this.sessions = false,
    this.posts = false,
    this.threads = false,
  });

  /// The run the push is about (from `sessionId`, else the `/runs/<id>` route).
  final String? sessionId;

  /// Pull the sessions feed (which embeds groups, leaders and summaries) and
  /// the run's plan. True for run, group, pace, leader-needed, cancel and moved
  /// pushes: all of them land on a run page.
  final bool sessions;

  /// Pull the club updates feed (new or edited post, comments).
  final bool posts;

  /// Refresh the chat threads list (unread dots, Inbox chats).
  final bool threads;

  @override
  bool operator ==(Object other) =>
      other is RefreshTarget &&
      other.sessionId == sessionId &&
      other.sessions == sessions &&
      other.posts == posts &&
      other.threads == threads;

  @override
  int get hashCode => Object.hash(sessionId, sessions, posts, threads);

  @override
  String toString() =>
      'RefreshTarget($sessionId, sessions: $sessions, posts: $posts, '
      'threads: $threads)';
}

const _reservedRunSegments = {'new', 'lead', 'series', 'venues'};

/// The run id in an in-app location such as `/runs/abc`, `/runs/abc/edit` or
/// `/runs/abc/groups/new?x=1`; null for `/runs`, `/runs/new`, `/updates`...
String? sessionIdFromRoute(String? route) {
  if (route == null) return null;
  final path = Uri.tryParse(route)?.pathSegments ?? const <String>[];
  if (path.length < 2 || path[0] != 'runs') return null;
  final id = path[1];
  return id.isEmpty || _reservedRunSegments.contains(id) ? null : id;
}

/// Maps a notification's `data` (`route`, `sessionId`, `groupId`, `category`)
/// to what to refresh. Chat pushes (group or leaders chat, post comments) only
/// refresh the threads list: the open chat screen polls itself.
RefreshTarget refreshTargetFor(Map<String, Object?> data) {
  final route = data['route'] as String?;
  final category = data['category'] as String?;
  final rawSession = data['sessionId'];
  final sessionId = rawSession is String && rawSession.isNotEmpty
      ? rawSession
      : sessionIdFromRoute(route);

  final isChat =
      category == 'group_messages' ||
      (route != null &&
          (route.endsWith('/chat') ||
              route.endsWith('/leaders-chat') ||
              route.endsWith('/comments')));
  if (isChat) {
    return RefreshTarget(
      sessionId: sessionId,
      threads: true,
      posts: route != null && route.startsWith('/updates'),
    );
  }

  final updates = route != null && route.startsWith('/updates');
  return RefreshTarget(
    sessionId: sessionId,
    sessions: sessionId != null,
    posts: updates || category == 'club_updates',
  );
}

/// The run an in-app location is showing (`/runs/<id>` and its sub-pages), or
/// null. Used to refresh the open run page's plan while it is on screen.
String? openSessionIdFromLocation(String location) =>
    sessionIdFromRoute(location);
