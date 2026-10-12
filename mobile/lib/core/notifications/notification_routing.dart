/// What to do when the user taps a notification.
class TapDecision {
  const TapDecision({this.switchToSub, this.setClubId, required this.route});

  /// Switch the active account to this `sub` first (null: stay).
  final String? switchToSub;

  /// Then switch the active club (null: stay).
  final int? setClubId;

  /// Finally `router.go(route)`.
  final String route;

  @override
  bool operator ==(Object other) =>
      other is TapDecision &&
      other.switchToSub == switchToSub &&
      other.setClubId == setClubId &&
      other.route == route;

  @override
  int get hashCode => Object.hash(switchToSub, setClubId, route);

  @override
  String toString() => 'TapDecision($switchToSub, $setClubId, $route)';
}

const fallbackNotificationRoute = '/inbox';

/// Pure routing rule for a notification's `data` map (`userId`, `clubId`, `route`).
///
///  * `userId` differs from the active account and that account is on this device
///    -> switch to it. If it is NOT on the device we can't show it, so just open
///    the inbox of whoever is active.
///  * `clubId` differs from the active club -> switch club.
///  * `route` must be an in-app path (starts with `/`), otherwise `/inbox`.
TapDecision decideTapRoute({
  required Map<String, Object?> data,
  required String? activeSub,
  required int? activeClubId,
  required Set<String> knownSubs,
}) {
  final userId = data['userId'] as String?;
  final clubId = int.tryParse('${data['clubId'] ?? ''}');
  final rawRoute = data['route'] as String?;
  final route = rawRoute != null && rawRoute.startsWith('/')
      ? rawRoute
      : fallbackNotificationRoute;

  String? switchTo;
  if (userId != null && userId.isNotEmpty && userId != activeSub) {
    if (!knownSubs.contains(userId)) {
      return const TapDecision(route: fallbackNotificationRoute);
    }
    switchTo = userId;
  }
  // After an account switch the new account has its own active club, so compare
  // against it only when we aren't switching (we can't know it here); always set it.
  final setClub = clubId != null && (switchTo != null || clubId != activeClubId)
      ? clubId
      : null;
  return TapDecision(switchToSub: switchTo, setClubId: setClub, route: route);
}

/// True when a foreground push is for the group chat that is open right now
/// ([openGroupId], null when no chat is open) of the active account
/// ([activeSub]): such a push is not shown as a notification, the open screen
/// just refreshes (api-contract.md, Phase 6). A push meant for another account
/// on the device is still shown.
bool isForOpenChat(
  Map<String, Object?> data,
  String? openGroupId, {
  required String? activeSub,
}) {
  if (openGroupId == null || data['groupId'] != openGroupId) return false;
  final userId = data['userId'] as String?;
  return userId == null || userId == activeSub;
}

/// True for a `group_messages` push (it carries a `groupId`).
bool isGroupMessagePush(Map<String, Object?> data) =>
    data['groupId'] is String || data['category'] == 'group_messages';
