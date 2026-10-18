<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesGroups;
use App\Models\ClubSession;
use App\Models\EventLocation;
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
            'locationId' => 'nullable|uuid',
        ];
    }

    /** Events and race groups are events: they have no pace. */
    private function isEventGroup(SessionGroup $group): bool
    {
        return $group->kind === 'event' || $group->session->isEventMode();
    }

    private function raceGroupFixed()
    {
        return response()->json([
            'error' => 'race_group_fixed',
            'message' => 'A race has exactly one group, so it cannot be added or removed.',
        ], 409);
    }

    /** 422 when a request for an event group carries pace fields or asks to lead, else null. */
    private function checkEventRequest(Request $request)
    {
        foreach (['paceUnit', 'paceFromS', 'paceToS'] as $key) {
            $value = $request->input($key);

            if ($request->has($key) && $value !== null && $value !== '') {
                return $this->invalidField('paceFromS', 'Events have no pace.');
            }
        }

        if (filter_var($request->input('lead', false), FILTER_VALIDATE_BOOLEAN)) {
            return $this->invalidField('paceFromS', 'Events have no pace and no leaders.');
        }

        return null;
    }

    /** Distance needs its unit; the label of an event may not be empty. */
    private function checkEventSpec(array $values)
    {
        if ($values['distance_value'] !== null && $values['distance_unit'] === null) {
            return $this->invalidField('distanceUnit', 'distanceUnit is required when distanceValue is given.');
        }

        if (trim((string) $values['label']) === '') {
            return $this->invalidField('label', 'label is required (or pick a location).');
        }

        return null;
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

        // A group with no pace is told apart by its name ("Walk", "Route A"), so the label is required then.
        if ($values['pace_from_s'] === null && trim((string) $values['label']) === '') {
            return $this->invalidField('label', 'label is required when the group has no pace.');
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
        return $session->expectsLeaders();
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/groups",
     *   summary="Create a pace group. Any linked member with lead=true (they lead it); leaderless groups need committee, admin or the coordinator. With lead=true: 409 already_leading (with groupId) when the caller already leads another group of the run. Idempotent on id. A group with no pace needs a label (422 on label). On an events run any linked member adds an event (locationId and/or label; kind forced to event; the same locationId returns the existing group with 200; the caller is marked going; pace fields and lead are 422 on paceFromS; 422 on locationId when it is not a live location of the club). On a race run: 409 race_group_fixed.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="The group (200 on a replayed id)"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such session"),
     *   @OA\Response(response=409, description="session_cancelled | session_past | conflict | race_group_fixed | already_leading"),
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

        if ($session->isEventMode()) {
            return $this->storeEvent($request, $club, $member, $session);
        }

        if ($request->input('kind') === 'event') {
            return $this->invalidField('kind', 'Event groups can only be added to events and race runs.');
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

        if ($lead && ($led = $this->groupLedIn($session, $member))) {
            return $this->alreadyLeading($led);
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

        // Always: a pace group may match people, and any new group may be worth a "pick your group" nudge.
        app(RunNotifier::class)->queueGroupMatch($group, $member->id);

        return $this->respond($group, 201);
    }

    /** POST groups on an `events` (or `race`) run: any linked member adds an event (D76-D78). */
    private function storeEvent(Request $request, $club, $member, ClubSession $session)
    {
        if ($session->group_mode === 'race') {
            return $this->raceGroupFixed();
        }

        if ($bad = $this->checkEventRequest($request)) {
            return $bad;
        }

        $location = null;

        if ($request->input('locationId')) {
            $location = EventLocation::where('club_id', $club->id)->find($request->input('locationId'));

            if (!$location) {
                return $this->invalidField('locationId', 'locationId does not match an event location of this club.');
            }
        }

        $values = $this->fromRequest($request) + ['label' => null, 'description' => null, 'distance_value' => null, 'distance_unit' => null];
        $values = array_intersect_key($values, array_flip(['label', 'description', 'distance_value', 'distance_unit']));
        $values['label'] = trim((string) $values['label']) !== ''
            ? trim((string) $values['label'])
            : ($location ? mb_substr($location->name, 0, 80) : null);
        $values['kind'] = 'event';

        if ($bad = $this->checkEventSpec($values)) {
            return $bad;
        }

        $id = $request->input('id');

        if ($id && ($existing = SessionGroup::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id || $existing->session_id !== $session->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            return $this->respond($existing, 200);
        }

        if ($bad = $this->closedResponse($session)) {
            return $bad;
        }

        [$group, $created] = DB::transaction(function () use ($club, $member, $session, $values, $id, $location) {
            $existing = $location
                ? SessionGroup::where('session_id', $session->id)->where('location_id', $location->id)->orderBy('created_at')->first()
                : null;

            if ($existing) {
                $group = $existing;
                $created = false;
            } else {
                $group = new SessionGroup($values + [
                    'club_id' => $club->id,
                    'session_id' => $session->id,
                    'created_by_member_id' => $member->id,
                    'location_id' => $location ? $location->id : null,
                    'status' => SessionGroup::STATUS_ACTIVE,
                    'sort_order' => $this->nextSortOrder($session),
                ]);

                if ($id) {
                    $group->id = $id;
                }

                $group->save();
                $created = true;
            }

            // The member who adds (or re-adds) an event is going to it.
            $this->attendInGroup($club, $session, $group, $member);
            $session->touchForChange();

            return [$group, $created];
        });

        return $this->respond($group, $created ? 201 : 200);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{id}",
     *   summary="Edit a group (its leaders, the coordinator, committee or admin; an event group: its creator, the coordinator, committee or admin). Fields sent as null are cleared. The result must have a pace or a label (422 on label). Event groups take label, description and distance only.",
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

        if ($this->isEventGroup($group)) {
            if ($bad = $this->checkEventRequest($request)) {
                return $bad;
            }

            if (isset($changes['kind']) && $changes['kind'] !== 'event') {
                return $this->invalidField('kind', 'An event group stays an event.');
            }

            // Events have no pace and keep their kind.
            $changes = array_diff_key($changes, array_flip(['kind', 'pace_unit', 'pace_from_s', 'pace_to_s']));
            $final = $changes + $group->only(array_values(self::FIELDS));

            if ($bad = $this->checkEventSpec($final)) {
                return $bad;
            }
        } else {
            if (isset($changes['kind']) && $changes['kind'] === 'event') {
                return $this->invalidField('kind', 'Event groups can only be added to events and race runs.');
            }

            $final = $changes + $group->only(array_values(self::FIELDS));

            if ($bad = $this->checkSpec($final)) {
                return $bad;
            }
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
        // An event group has no leaders: its creator, the coordinator and the committee manage it.
        if ($this->isEventGroup($group)) {
            return $this->isManagerOrCoordinator($member, $group->session)
                || ($group->created_by_member_id !== null && $group->created_by_member_id === $member->id);
        }

        return $this->isManagerOrCoordinator($member, $group->session) || $this->isLeaderOf($group, $member);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{id}",
     *   summary="Delete a group (its leaders, the coordinator, committee or admin; an event group: its creator, the coordinator, committee or admin). Its attendees become unassigned. 409 race_group_fixed for the group of a race run.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Deleted (also when already deleted)"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past | race_group_fixed"),
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

        if ($group->session->group_mode === 'race') {
            return $this->raceGroupFixed();
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
     *   summary="The caller joins the group as leader, co_leader or backmarker (any linked member). A needs_leader group becomes active. 409 already_leading (with groupId) when they already lead another group of the run; 409 leader_exists for role leader when the group already has a confirmed leader. Re-joining the same group is idempotent.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The group"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past | already_leading | leader_exists"),
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

        $role = $request->input('role') ?: 'leader';

        // One group per leader and one `leader` per group (D108); event groups have no leaders to limit.
        if (!$group->session->isEventMode() && $group->kind !== 'event') {
            if ($led = $this->groupLedIn($group->session, $member, $group)) {
                return $this->alreadyLeading($led);
            }

            if ($role === 'leader' && SessionGroupLeader::where('group_id', $group->id)
                ->where('status', SessionGroupLeader::CONFIRMED)->where('role', 'leader')
                ->where('member_id', '!=', $member->id)->exists()) {
                return response()->json([
                    'error' => 'leader_exists',
                    'message' => 'This group already has a leader. Join as co-leader or backmarker.',
                ], 409);
            }
        }

        DB::transaction(function () use ($club, $member, $group, $role) {
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
     *   summary="The caller steps down as leader (D109). They are removed from the group (still going; optional body {notGoing:true} makes them not going). The creator leaving a group nobody else is in deletes it (200 with deletedAt, no notifications); otherwise the last leader leaving a paced/single run makes the group needs_leader and fitting members are asked to lead. Replays return the group.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(required=false, @OA\JsonContent(@OA\Property(property="notGoing", type="boolean"))),
     *   @OA\Response(response=200, description="The group (deletedAt set when it was deleted)"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     *   @OA\Response(response=422, description="notGoing is not a boolean"),
     * )
     */
    public function withdraw(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $group = $this->groupFor($club, $id, true);

        if (!$group) {
            return $this->notFound('No such group.');
        }

        if ($request->has('notGoing') && !is_bool($request->input('notGoing'))) {
            return $this->invalidField('notGoing', 'notGoing must be true or false.');
        }

        // Replay after the group was deleted (by this call or by anyone): same payload, deletedAt set.
        if ($group->trashed()) {
            return $this->respond($group);
        }

        if ($bad = $this->closedResponse($group->session)) {
            return $bad;
        }

        $notGoing = $request->input('notGoing') === true;

        $row = SessionGroupLeader::where('group_id', $group->id)
            ->where('member_id', $member->id)
            ->where('status', SessionGroupLeader::CONFIRMED)
            ->first();

        $needsLeader = false;

        if ($row) {
            DB::transaction(function () use ($row, $group, $member, $notGoing, &$needsLeader) {
                $row->fill(['status' => SessionGroupLeader::WITHDRAWN, 'withdrawn_at' => Carbon::now()])->save();

                $mine = SessionAttendee::where('session_id', $group->session_id)->where('member_id', $member->id)->first();

                if ($mine && ($mine->group_id === $group->id || $notGoing)) {
                    $mine->group_id = null;
                    $mine->status = $notGoing ? SessionAttendee::NOT_GOING : $mine->status;
                    $mine->updated_at = Carbon::now();
                    $mine->save();
                } elseif (!$mine && $notGoing) {
                    SessionAttendee::create([
                        'club_id' => $group->club_id,
                        'session_id' => $group->session_id,
                        'member_id' => $member->id,
                        'status' => SessionAttendee::NOT_GOING,
                    ]);
                }

                $remaining = SessionGroupLeader::where('group_id', $group->id)
                    ->where('status', SessionGroupLeader::CONFIRMED)->count();

                // An unused group the caller made goes away instead of waiting for a leader.
                if ($remaining === 0
                    && $group->created_by_member_id === $member->id
                    && !SessionAttendee::where('group_id', $group->id)->exists()) {
                    $group->delete();
                } elseif ($remaining === 0 && $this->expectsLeaders($group->session)) {
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
