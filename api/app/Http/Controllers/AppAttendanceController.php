<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesGroups;
use App\Models\MemberPreference;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Services\GroupPresenter;
use App\Services\NotificationPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * RSVP to a run, and the online session plan (Phase 4).
 * Contract: mobile/docs/api-contract.md.
 */
class AppAttendanceController extends Controller
{
    use ManagesGroups;

    private function row(?SessionAttendee $row): ?array
    {
        if (!$row) {
            return null;
        }

        return [
            'sessionId' => $row->session_id,
            'status' => $row->status,
            'groupId' => $row->group_id,
            'paceUnit' => $row->pace_unit,
            'paceFromS' => $row->pace_from_s !== null ? (int) $row->pace_from_s : null,
            'paceToS' => $row->pace_to_s !== null ? (int) $row->pace_to_s : null,
            'updatedAt' => NotificationPresenter::time($row->updated_at),
        ];
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/attendance",
     *   summary="Upsert the caller's RSVP (going/maybe/not_going), optional group and per-run pace.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The caller's attendance"),
     *   @OA\Response(response=404, description="No such session"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     *   @OA\Response(response=422, description="Validation error, or groupId is not a group of this session"),
     * )
     */
    public function update(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $session = $this->findSession($club, $sessionId);

        if (!$session) {
            return $this->notFound('No such session.');
        }

        $validator = $this->makeValidator($request->all(), [
            'status' => 'required|in:' . implode(',', SessionAttendee::STATUSES),
            'groupId' => 'nullable|uuid',
            'paceUnit' => 'nullable|in:mi,km',
            'paceFromS' => 'nullable|integer|between:180,1800',
            'paceToS' => 'nullable|integer|between:180,1800',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $unit = $request->input('paceUnit');
        $from = $request->input('paceFromS');
        $to = $request->input('paceToS');

        if ($bad = $this->checkPaceRange($unit, $from, $to)) {
            return $bad;
        }

        if ($bad = $this->closedResponse($session)) {
            return $bad;
        }

        $status = $request->input('status');
        $groupId = $status === SessionAttendee::NOT_GOING ? null : $request->input('groupId');

        if ($groupId !== null
            && !SessionGroup::where('club_id', $club->id)->where('session_id', $session->id)->whereKey($groupId)->exists()) {
            return $this->invalidField('groupId', 'groupId does not match a group of this session.');
        }

        $row = DB::transaction(function () use ($club, $member, $session, $status, $groupId, $unit, $from, $to) {
            $row = SessionAttendee::firstOrNew(['session_id' => $session->id, 'member_id' => $member->id]);
            $row->fill([
                'club_id' => $club->id,
                'status' => $status,
                'group_id' => $groupId,
                'pace_unit' => $unit,
                'pace_from_s' => $from !== null ? (int) $from : null,
                'pace_to_s' => $to !== null ? (int) $to : null,
            ]);
            $row->updated_at = \Illuminate\Support\Carbon::now(); // saved even when nothing else changed
            $row->save();
            $session->touchForChange();

            return $row;
        });

        return response()->json($this->row($row->fresh()));
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/attendance",
     *   summary="The caller's own attendance row for the run, or null.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="Attendance or null"),
     *   @OA\Response(response=404, description="No such session"),
     * )
     */
    public function show(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$this->findSession($club, $sessionId)) {
            return $this->notFound('No such session.');
        }

        $row = SessionAttendee::where('session_id', $sessionId)->where('member_id', $member->id)->first();

        // A JSON null body: response()->json(null) would send {}.
        return $row
            ? response()->json($this->row($row))
            : response('null', 200, ['Content-Type' => 'application/json']);
    }

    /** The pace a member will run: this run's override, else their profile range. */
    private function effectivePace(SessionAttendee $row, $prefs): array
    {
        if ($row->pace_from_s !== null && $row->pace_unit !== null) {
            return [$row->pace_unit, (int) $row->pace_from_s, $row->pace_to_s !== null ? (int) $row->pace_to_s : null];
        }

        $pref = $prefs->get($row->member_id);

        if ($pref && $pref->pace_from_s !== null) {
            return [$pref->pace_unit, (int) $pref->pace_from_s, $pref->pace_to_s !== null ? (int) $pref->pace_to_s : null];
        }

        return [null, null, null];
    }

    /** Anonymous, sorted pace list for the given rows (members with no pace are left out). */
    private function paces($rows, $prefs): array
    {
        $paces = [];

        foreach ($rows as $row) {
            [$unit, $from, $to] = $this->effectivePace($row, $prefs);

            if ($from !== null) {
                $paces[] = ['fromSPerKm' => GroupPresenter::perKm($from, $unit), 'toSPerKm' => GroupPresenter::perKm($to, $unit)];
            }
        }

        usort($paces, function ($a, $b) {
            return [$a['fromSPerKm'], $a['toSPerKm'] ?? 0] <=> [$b['fromSPerKm'], $b['toSPerKm'] ?? 0];
        });

        return $paces;
    }

    private function names($rows, $prefs): array
    {
        return $rows->map(function ($row) use ($prefs) {
            [$unit, $from, $to] = $this->effectivePace($row, $prefs);

            return [
                'memberId' => $row->member_id,
                'displayName' => $row->member ? $row->member->display_name : null,
                'status' => $row->status,
                'paceUnit' => $unit,
                'paceFromS' => $from,
                'paceToS' => $to,
            ];
        })->sortBy('displayName')->values()->all();
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/plan",
     *   summary="Who is coming and at what pace. Names only for the groups the caller leads, and for everyone to committee/admin/coordinator.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The plan"),
     *   @OA\Response(response=404, description="No such session"),
     * )
     */
    public function plan(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $session = $this->findSession($club, $sessionId);

        if (!$session) {
            return $this->notFound('No such session.');
        }

        $session->load(GroupPresenter::eagerLoads());
        $seeAll = $this->isManagerOrCoordinator($member, $session);

        $rows = SessionAttendee::with('member')
            ->where('session_id', $session->id)
            ->whereIn('status', [SessionAttendee::GOING, SessionAttendee::MAYBE])
            ->get();

        $prefs = MemberPreference::where('club_id', $club->id)
            ->whereIn('member_id', $rows->pluck('member_id')->all())
            ->get()->keyBy('member_id');

        $groups = [];
        $liveIds = $session->groups->pluck('id')->all();

        foreach ($session->groups as $group) {
            $inGroup = $rows->where('group_id', $group->id);
            $entry = ['groupId' => $group->id, 'paces' => $this->paces($inGroup, $prefs)];

            if ($seeAll || $group->leaders->contains('member_id', $member->id)) {
                $entry['attendees'] = $this->names($inGroup, $prefs);
            }

            $groups[] = $entry;
        }

        $loose = $rows->filter(function ($row) use ($liveIds) {
            return $row->group_id === null || !in_array($row->group_id, $liveIds, true);
        });

        $unassigned = [
            'goingCount' => $loose->where('status', SessionAttendee::GOING)->count(),
            'maybeCount' => $loose->where('status', SessionAttendee::MAYBE)->count(),
            'paces' => $this->paces($loose, $prefs),
        ];

        if ($seeAll) {
            $unassigned['members'] = $this->names($loose, $prefs);
        }

        return response()->json(['sessionId' => $session->id, 'groups' => $groups, 'unassigned' => $unassigned]);
    }
}
