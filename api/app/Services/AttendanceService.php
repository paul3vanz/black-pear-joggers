<?php

namespace App\Services;

use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Writes a member's RSVP for a run. Shared by PUT .../attendance and the
 * unauthenticated notification-actions endpoint, so both do exactly the same.
 */
class AttendanceService
{
    /**
     * Upserts the member's row and bumps the session so `?since=` delivers it.
     * Callers validate first (session open, group belongs to the session, paces).
     * The row is saved even when nothing changed, so its updated_at moves.
     */
    public function set(
        $club,
        $member,
        ClubSession $session,
        string $status,
        ?string $groupId,
        $unit = null,
        $from = null,
        $to = null
    ): SessionAttendee {
        $row = DB::transaction(function () use ($club, $member, $session, $status, $groupId, $unit, $from, $to) {
            // An `everyone` run has no leaders or pace groups: whoever is coming
            // joins its one shared group, which also holds the chat.
            if ($session->isEveryoneMode() && $status !== SessionAttendee::NOT_GOING) {
                $groupId = $this->everyoneGroup($club, $session)->id;
            }

            $row =SessionAttendee::firstOrNew(['session_id' => $session->id, 'member_id' => $member->id]);
            $row->fill([
                'club_id' => $club->id,
                'status' => $status,
                'group_id' => $groupId,
                'pace_unit' => $unit,
                'pace_from_s' => $from !== null ? (int) $from : null,
                'pace_to_s' => $to !== null ? (int) $to : null,
            ]);
            $row->updated_at = Carbon::now(); // saved even when nothing else changed
            $row->save();
            $session->touchForChange();

            return $row;
        });

        return $row->fresh();
    }

    /** The single leaderless group of an `everyone` run, created on first use. */
    public function everyoneGroup($club, ClubSession $session): SessionGroup
    {
        $group = SessionGroup::where('club_id', $club->id)->where('session_id', $session->id)->orderBy('created_at')->first();

        return $group ?: SessionGroup::create([
            'club_id' => $club->id,
            'session_id' => $session->id,
            'kind' => 'other',
            'label' => 'Run chat',
            'status' => SessionGroup::STATUS_ACTIVE,
        ]);
    }
}
