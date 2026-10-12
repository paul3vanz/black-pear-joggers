import '../../groups/data/group_dtos.dart';
import '../../runs/logic/run_modes.dart';

/// Who may edit the note of, or remove, an event group (api-contract.md,
/// Phase 8): the member who created it, the run's coordinator and the
/// committee or admin. Leaders of an event group get no extra rights. A race's
/// single group cannot be removed (the server answers 409 `race_group_fixed`),
/// so [canRemoveEvent] is false for it.
bool canEditEvent({
  required Group group,
  required String? coordinatorMemberId,
  required String? myMemberId,
  required bool isCommittee,
}) {
  if (isCommittee) return true;
  if (myMemberId == null) return false;
  return group.createdByMemberId == myMemberId ||
      coordinatorMemberId == myMemberId;
}

/// [canEditEvent] and not a race.
bool canRemoveEvent({
  required String mode,
  required Group group,
  required String? coordinatorMemberId,
  required String? myMemberId,
  required bool isCommittee,
}) =>
    !isRaceMode(mode) &&
    canEditEvent(
      group: group,
      coordinatorMemberId: coordinatorMemberId,
      myMemberId: myMemberId,
      isCommittee: isCommittee,
    );
