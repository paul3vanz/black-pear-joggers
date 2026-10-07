<?php

namespace App\Http\Controllers\Concerns;

use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;

/**
 * Shared by the Phase 4 controllers (groups, attendance, plan).
 */
trait ManagesGroups
{
    use AppResponses;

    /** Committee and admin run the whole schedule. */
    protected function isManager($member): bool
    {
        return $member->hasRole('committee', 'admin');
    }

    /** Committee, admin, or the coordinator of this run. */
    protected function isManagerOrCoordinator($member, ClubSession $session): bool
    {
        return $this->isManager($member)
            || ($session->coordinator_member_id !== null && $session->coordinator_member_id === $member->id);
    }

    protected function isLeaderOf(SessionGroup $group, $member): bool
    {
        return SessionGroupLeader::where('group_id', $group->id)
            ->where('member_id', $member->id)
            ->where('status', SessionGroupLeader::CONFIRMED)
            ->exists();
    }

    /**
     * Someone leading a group is going on that run, so mark them as attending it.
     * An existing response keeps its per-run pace; "not going" or "maybe" becomes
     * "going". Leaving the group as a leader later does not undo this.
     */
    protected function attendAsLeader($club, ClubSession $session, SessionGroup $group, $member): void
    {
        $row = SessionAttendee::firstOrNew(['session_id' => $session->id, 'member_id' => $member->id]);
        $row->fill([
            'club_id' => $club->id,
            'status' => SessionAttendee::GOING,
            'group_id' => $group->id,
        ]);
        $row->save();
    }

    /** A live session of this club, or null. */
    protected function findSession($club, $id): ?ClubSession
    {
        return ClubSession::where('club_id', $club->id)->find($id);
    }

    /** 409 for a cancelled or finished run, else null. */
    protected function closedResponse(ClubSession $session)
    {
        if ($session->isCancelled()) {
            return response()->json(['error' => 'session_cancelled', 'message' => 'This run has been cancelled.'], 409);
        }

        if ($session->hasEnded()) {
            return response()->json(['error' => 'session_past', 'message' => 'This run has already finished.'], 409);
        }

        return null;
    }

    protected function invalidField(string $field, string $message)
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => $message,
            'errors' => [$field => [$message]],
        ], 422);
    }

    /**
     * Combination rules shared by group and preference/attendance paces.
     * Returns a 422 response or null. $unit is the pace unit, $from/$to the range.
     */
    protected function checkPaceRange($unit, $from, $to, string $prefix = 'pace')
    {
        if (($from !== null || $to !== null) && $unit === null) {
            return $this->invalidField($prefix . 'Unit', $prefix . 'Unit is required when a pace is given.');
        }

        if ($to !== null && $from === null) {
            return $this->invalidField($prefix . 'FromS', $prefix . 'FromS is required when ' . $prefix . 'ToS is given.');
        }

        if ($from !== null && $to !== null && (int) $from > (int) $to) {
            return $this->invalidField($prefix . 'ToS', $prefix . 'FromS (the faster end) must not exceed ' . $prefix . 'ToS.');
        }

        return null;
    }
}
