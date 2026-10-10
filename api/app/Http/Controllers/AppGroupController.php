<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesGroups;
use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Services\GroupPresenter;
use App\Services\RunNotifier;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Pace groups and their leaders (Phase 4). Contract: mobile/docs/api-contract.md.
 */
class AppGroupController extends Controller
{
    use ManagesGroups;

    /** Request key => column. */
    private const FIELDS = [
        'kind' => 'kind',
        'label' => 'label',
        'description' => 'description',
        'paceUnit' => 'pace_unit',
        'paceFromS' => 'pace_from_s',
        'paceToS' => 'pace_to_s',
        'distanceValue' => 'distance_value',
        'distanceUnit' => 'distance_unit',
    ];

    private function rules(): array
    {
        return [
            'id' => 'nullable|uuid',
            'kind' => 'nullable|in:' . implode(',', SessionGroup::KINDS),
            'label' => 'nullable|string|max:80',
            'description' => 'nullable|string|max:1000',
            'paceUnit' => 'nullable|in:mi,km',
            'paceFromS' => 'nullable|integer|between:180,1800',
            'paceToS' => 'nullable|integer|between:180,1800',
            'distanceValue' => 'nullable|numeric|between:0.1,200',
            'distanceUnit' => 'nullable|in:mi,km',
            'lead' => 'nullable|boolean',
        ];
    }

    /** Combination rules on the final values of a group, or null when fine. */
    private function checkSpec(array $values)
    {
        if ($bad = $this->checkPaceRange($values['pace_unit'], $values['pace_from_s'], $values['pace_to_s'])) {
            return $bad;
        }

        if ($values['distance_value'] !== null && $values['distance_unit'] === null) {
            return $this->invalidField('distanceUnit', 'distanceUnit is required when distanceValue is given.');
        }

        return null;
    }

    /** Column values from the request, only for the keys present. */
    private function fromRequest(Request $request): array
    {
        $values = [];

        foreach (self::FIELDS as $key => $column) {
            if ($request->has($key)) {
                $value = $request->input($key);

                if ($value === '') {
                    $value = null;
                }

                if ($column === 'distance_value' && $value !== null) {
                    $value = round((float) $value, 2);
                } elseif (in_array($column, ['pace_from_s', 'pace_to_s'], true) && $value !== null) {
                    $value = (int) $value;
                } elseif ($column === 'kind' && $value === null) {
                    $value = 'run';
                }

                $values[$column] = $value;
            }
        }

        return $values;
    }

    private function respond(SessionGroup $group, int $status = 200)
    {
        $group = SessionGroup::withTrashed()->find($group->id);
        $group->load('leaders.member');

        return response()->json(GroupPresenter::group($group), $status);
    }

    private function groupFor($club, $id, bool $withTrashed = false): ?SessionGroup
    {
        $query = SessionGroup::where('club_id', $club->id);

        if ($withTrashed) {
            $query->withTrashed();
        }

        $group = $query->find($id);

        return $group && $group->session && !$group->session->trashed() ? $group : null;
    }

    private function nextSortOrder(ClubSession $session): int
    {
        $max = SessionGroup::where('session_id', $session->id)->max('sort_order');

        return $max === null ? 0 : (int) $max + 1;
    }

    /** True when a group in a mode that expects leaders has none left. */
    private function expectsLeaders(ClubSession $session): bool
    {
        return in_array($session->group_mode, ['paced', 'single'], true);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/groups",
     *   summary="Create a pace group. Any linked member with lead=true (they lead it); leaderless groups need committee, admin or the coordinator. Idempotent on id.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="The group (200 on a replayed id)"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such session"),
     *   @OA\Response(response=409, description="session_cancelled | session_past | conflict"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $session = $this->findSession($club, $sessionId);

        if (!$session) {
            return $this->notFound('No such session.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules());

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $values = $this->fromRequest($request) + [
            'kind' => 'run', 'label' => null, 'description' => null, 'pace_unit' => null, 'pace_from_s' => null,
            'pace_to_s' => null, 'distance_value' => null, 'distance_unit' => null,
        ];

        if ($bad = $this->checkSpec($values)) {
            return $bad;
        }

        $id = $request->input('id');

        if ($id && ($existing = SessionGroup::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id || $existing->session_id !== $session->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            return $this->respond($existing, 200);
        }

        $lead = filter_var($request->input('lead', false), FILTER_VALIDATE_BOOLEAN);

        if (!$lead && !$this->isManagerOrCoordinator($member, $session)) {
            return $this->forbidden('Only the committee or the run coordinator can add a group without leading it.');
        }

        if ($bad = $this->closedResponse($session)) {
            return $bad;
        }

        $group = DB::transaction(function () use ($club, $member, $session, $values, $id, $lead) {
            $group = new SessionGroup($values + [
                'club_id' => $club->id,
                'session_id' => $session->id,
                'created_by_member_id' => $member->id,
                'status' => $lead || !$this->expectsLeaders($session)
                    ? SessionGroup::STATUS_ACTIVE
                    : SessionGroup::STATUS_NEEDS_LEADER,
                'sort_order' => $this->nextSortOrder($session),
            ]);

            if ($id) {
                $group->id = $id;
            }

            $group->save();

            if ($lead) {
                SessionGroupLeader::create([
                    'club_id' => $club->id,
                    'group_id' => $group->id,
                    'member_id' => $member->id,
                    'role' => 'leader',
                ]);
                $this->attendAsLeader($club, $session, $group, $member);
            }

            $session->touchForChange();

            return $group;
        });

        if ($group->pace_from_s !== null) {
            app(RunNotifier::class)->queueGroupMatch($group, $member->id);
        }

        return $this->respond($group, 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{id}",
     *   summary="Edit a group (its leaders, the coordinator, committee or admin). Fields sent as null are cleared.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The group"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $group = $this->groupFor($club, $id);

        if (!$group) {
            return $this->notFound('No such group.');
        }

        if (!$this->canEdit($group, $member)) {
            return $this->forbidden('Only the group leaders, the run coordinator or the committee can edit this group.');
        }

        $rules = $this->rules();
        unset($rules['id'], $rules['lead']);
        $validator = $this->makeValidator($request->all(), $rules);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $changes = $this->fromRequest($request);
        $final = $changes + $group->only(array_values(self::FIELDS));

        if ($bad = $this->checkSpec($final)) {
            return $bad;
        }

        if ($bad = $this->closedResponse($group->session)) {
            return $bad;
        }

        $paceBefore = $this->paceOf($group);

        DB::transaction(function () use ($group, $changes) {
            $group->fill($changes)->save();
            $group->session->touchForChange();
        });

        if ($group->pace_from_s !== null && $paceBefore !== $this->paceOf($group)) {
            app(RunNotifier::class)->queueGroupMatch($group, $member->id);
        }

        return $this->respond($group);
    }

    /** The pace columns as a comparable value. */
    private function paceOf(SessionGroup $group): array
    {
        return [$group->pace_unit, $group->pace_from_s, $group->pace_to_s];
    }

    private function canEdit(SessionGroup $group, $member): bool
    {
        return $this->isManagerOrCoordinator($member, $group->session) || $this->isLeaderOf($group, $member);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{id}",
     *   summary="Delete a group (its leaders, the coordinator, committee or admin). Its attendees become unassigned.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Deleted (also when already deleted)"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     * )
     */
    public function destroy(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $group = $this->groupFor($club, $id, true);

        if (!$group) {
            return $this->notFound('No such group.');
        }

        if (!$this->canEdit($group, $member)) {
            return $this->forbidden('Only the group leaders, the run coordinator or the committee can delete this group.');
        }

        if ($group->trashed()) {
            return response('', 204);
        }

        if ($bad = $this->closedResponse($group->session)) {
            return $bad;
        }

        $signedUp = SessionAttendee::where('group_id', $group->id)
            ->whereIn('status', [SessionAttendee::GOING, SessionAttendee::MAYBE])
            ->pluck('member_id')->all();

        DB::transaction(function () use ($group) {
            SessionAttendee::where('group_id', $group->id)->update(['group_id' => null, 'updated_at' => Carbon::now()]);
            $group->delete();
            $group->session->touchForChange();
        });

        if ($signedUp) {
            app(RunNotifier::class)->groupRemoved($group, $signedUp, $member->id);
        }

        return response('', 204);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{id}/leaders",
     *   summary="The caller joins the group as a leader (any linked member). A needs_leader group becomes active.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The group"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     *   @OA\Response(response=422, description="Unknown role"),
     * )
     */
    public function join(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $group = $this->groupFor($club, $id);

        if (!$group) {
            return $this->notFound('No such group.');
        }

        $validator = $this->makeValidator($request->all(), ['role' => 'nullable|in:' . implode(',', SessionGroupLeader::ROLES)]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        if ($bad = $this->closedResponse($group->session)) {
            return $bad;
        }

        DB::transaction(function () use ($club, $member, $group, $request) {
            $role = $request->input('role') ?: 'leader';
            $row = SessionGroupLeader::where('group_id', $group->id)->where('member_id', $member->id)->first();

            if ($row) {
                $row->fill(['role' => $role, 'status' => SessionGroupLeader::CONFIRMED, 'withdrawn_at' => null])->save();
            } else {
                SessionGroupLeader::create([
                    'club_id' => $club->id,
                    'group_id' => $group->id,
                    'member_id' => $member->id,
                    'role' => $role,
                ]);
            }

            if ($group->status !== SessionGroup::STATUS_ACTIVE) {
                $group->status = SessionGroup::STATUS_ACTIVE;
                $group->save();
            }

            $this->attendAsLeader($club, $group->session, $group, $member);
            $group->session->touchForChange();
        });

        return $this->respond($group);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{id}/leaders/me",
     *   summary="The caller withdraws as leader. The last leader leaving a paced/single run makes the group needs_leader.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The group"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     * )
     */
    public function withdraw(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $group = $this->groupFor($club, $id);

        if (!$group) {
            return $this->notFound('No such group.');
        }

        if ($bad = $this->closedResponse($group->session)) {
            return $bad;
        }

        $row = SessionGroupLeader::where('group_id', $group->id)
            ->where('member_id', $member->id)
            ->where('status', SessionGroupLeader::CONFIRMED)
            ->first();

        $needsLeader = false;

        if ($row) {
            DB::transaction(function () use ($row, $group, &$needsLeader) {
                $row->fill(['status' => SessionGroupLeader::WITHDRAWN, 'withdrawn_at' => Carbon::now()])->save();

                $remaining = SessionGroupLeader::where('group_id', $group->id)
                    ->where('status', SessionGroupLeader::CONFIRMED)->count();

                if ($remaining === 0 && $this->expectsLeaders($group->session)) {
                    $group->status = SessionGroup::STATUS_NEEDS_LEADER;
                    $group->save();
                    $needsLeader = true;
                }

                $group->session->touchForChange();
            });
        }

        if ($needsLeader) {
            app(RunNotifier::class)->leaderWithdrawn($group, $member->id);
        }

        return $this->respond($group);
    }
}
