import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../membership/data/membership_dtos.dart';
import '../../membership/ui/membership_providers.dart';
import '../../runs/ui/runs_providers.dart';
import '../data/group_dtos.dart';

/// The clock the groups UI uses to decide whether a run has finished. A
/// provider so tests can pin it.
final groupsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The signed-in member's id in the active club, or null when not linked.
final myMemberIdProvider = Provider<String?>(
  (ref) => ref.watch(activeMembershipProvider)?.memberId,
);

/// Whether a run is still open for responses and group changes: not cancelled
/// and not yet ended. The server enforces this too (409).
bool isRunOpen(Session session, DateTime now) =>
    session.status != 'cancelled' && !session.endsAt.isBefore(now);

/// Why a run is closed, for the explanation card; null while it is open.
String? runClosedReason(Session session, DateTime now) {
  if (session.status == 'cancelled') return 'This run has been cancelled.';
  if (session.endsAt.isBefore(now)) return 'This run has finished.';
  return null;
}

/// Who may edit or delete [group]: its leaders, the session coordinator and
/// the committee or admin (data-model.md, "Visibility and permissions").
bool canEditGroup({
  required Group group,
  required Session session,
  required String? myMemberId,
  required bool isCommittee,
}) {
  if (isCommittee) return true;
  if (myMemberId == null) return false;
  return group.isLedBy(myMemberId) || session.coordinatorMemberId == myMemberId;
}

/// Who may create a leaderless group (e.g. a Sunday route).
bool canCreateLeaderless({
  required Session session,
  required String? myMemberId,
  required bool isCommittee,
}) =>
    isCommittee ||
    (myMemberId != null && session.coordinatorMemberId == myMemberId);

/// "Add route" shows for the committee, admin and the session coordinator in a
/// `routes` session.
final canAddRoutesProvider = Provider.family<bool, Session>(
  (ref, session) =>
      session.groupMode == 'routes' &&
      canCreateLeaderless(
        session: session,
        myMemberId: ref.watch(myMemberIdProvider),
        isCommittee: ref.watch(canManageRunsProvider),
      ),
);

/// The caller's roles in the active club (`leader`, `committee`, `admin`).
final myRolesProvider = Provider<List<String>>((ref) {
  final membership = ref.watch(activeMembershipProvider);
  return membership == null ? const [] : decodeRoles(membership.rolesJson);
});

/// Only admins may grant or remove `committee` and `admin` (the server 403s
/// others).
final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(myRolesProvider).contains('admin'),
);

/// Who may read and post in [group]'s chat (api-contract.md, Phase 6): its
/// leaders, the session coordinator, members who chose the group ([inGroup])
/// and the committee or admin. The server enforces it too (403 `not_in_group`).
bool canChatIn({
  required Group group,
  required Session session,
  required String? myMemberId,
  required bool inGroup,
  required bool isCommittee,
}) {
  if (isCommittee || inGroup) return true;
  if (myMemberId == null) return false;
  return group.isLedBy(myMemberId) || session.coordinatorMemberId == myMemberId;
}
