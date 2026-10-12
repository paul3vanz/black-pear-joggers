<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesRuns;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\SessionGroup;
use App\Models\SessionSeries;
use App\Services\GroupPresenter;
use App\Services\NotificationPresenter;
use App\Services\RunNotifier;
use App\Services\RunPresenter;
use App\Services\SessionGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class AppSessionController extends Controller
{
    use ManagesRuns;

    private function rules(bool $creating): array
    {
        $required = $creating ? 'required' : 'sometimes|required';

        return [
            'id' => 'nullable|uuid',
            'title' => $required . '|string|max:255',
            'localDate' => $required . '|date_format:Y-m-d',
            'startTime' => $required . '|date_format:H:i',
            'durationMin' => 'nullable|integer|between:15,600',
            'venueId' => 'nullable|uuid',
            'notes' => 'nullable|string',
            'groupMode' => ($creating ? 'required' : 'nullable') . '|in:' . implode(',', SessionSeries::GROUP_MODES),
            'coordinatorMemberId' => 'nullable|uuid',
        ];
    }

    private function load(ClubSession $session): ClubSession
    {
        return $session->load(array_merge(['series', 'coordinator'], GroupPresenter::eagerLoads()));
    }

    private function json(Request $request, ClubSession $session, int $status = 200)
    {
        return response()->json(RunPresenter::session($this->load($session->fresh()), $this->callerId($request)), $status);
    }

    private function callerId(Request $request): ?string
    {
        $member = $request->attributes->get('member');

        return $member ? $member->id : null;
    }

    private function invalid(string $field, string $message)
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => $message,
            'errors' => [$field => [$message]],
        ], 422);
    }

    /** Stated length in minutes, null when the run has no end time. */
    private function durationOf(ClubSession $session): ?int
    {
        return $session->has_end ? (int) $session->starts_at->diffInMinutes($session->ends_at) : null;
    }

    /** 422 unless the id is a live member of this club (or empty). */
    private function checkCoordinator($club, $memberId)
    {
        if ($memberId && !ClubMember::where('club_id', $club->id)->whereKey($memberId)->exists()) {
            return $this->invalid('coordinatorMemberId', 'coordinatorMemberId does not match a member of this club.');
        }

        return null;
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions",
     *   summary="Club runs. Without since: localDate in [from, to] (default today..+60 days). With since: all changes incl. tombstones, and the runs of any series edited since then (series image).",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="from", in="query", required=false, @OA\Schema(type="string", format="date")),
     *   @OA\Parameter(name="to", in="query", required=false, @OA\Schema(type="string", format="date")),
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: Session[] (endsAt and localEndTime are null when the run has no end time; imageUrl is the series image), serverTime }"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     *   @OA\Response(response=422, description="Bad from, to or since"),
     * )
     */
    public function index(Request $request)
    {
        $club = $request->attributes->get('club');

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $validator = $this->makeValidator($request->query(), [
            'from' => 'nullable|date_format:Y-m-d',
            'to' => 'nullable|date_format:Y-m-d',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);
        $callerId = $this->callerId($request);

        $query = ClubSession::where('club_id', $club->id)
            ->with(array_merge(['series', 'coordinator'], GroupPresenter::eagerLoads()));

        if ($since) {
            // Also the runs of a series edited since then (its image shows on every run). One WHERE, so no row twice.
            $query->withTrashed()
                ->where(function ($q) use ($club, $since) {
                    $q->where('updated_at', '>=', $since)
                        ->orWhereIn('series_id', SessionSeries::where('club_id', $club->id)->where('updated_at', '>=', $since)->select('id'));
                })
                ->orderBy('updated_at')->orderBy('id');
        } else {
            $today = $this->clubToday($club);
            $from = $request->query('from') ?: $today;
            $to = $request->query('to') ?: Carbon::parse($today)->addDays(60)->format('Y-m-d');

            $query->where('local_date', '>=', $from)->where('local_date', '<=', $to)
                ->orderBy('local_date')->orderBy('local_start_time')->orderBy('id');
        }

        return response()->json([
            'items' => $query->get()->map(function ($session) use ($callerId) {
                return RunPresenter::session($session, $callerId);
            })->all(),
            'serverTime' => NotificationPresenter::time($serverTime),
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions",
     *   summary="Create an ad-hoc run with no series (committee/admin). Idempotent on the client id. A race run also gets its single event group (label = title). venueId is optional in every mode.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"title","localDate","startTime","groupMode"},
     *       @OA\Property(property="id", type="string", format="uuid"),
     *       @OA\Property(property="title", type="string"),
     *       @OA\Property(property="localDate", type="string", format="date"),
     *       @OA\Property(property="startTime", type="string", example="19:00"),
     *       @OA\Property(property="durationMin", type="integer", minimum=15, maximum=600, nullable=true, description="Optional. Omit or null = no end time (the run still counts as ending after 3 hours). On PATCH, null clears it."),
     *       @OA\Property(property="venueId", type="string", format="uuid", nullable=true),
     *       @OA\Property(property="notes", type="string", nullable=true),
     *       @OA\Property(property="groupMode", type="string", enum={"paced","single","open","routes","events","race"}),
     *       @OA\Property(property="coordinatorMemberId", type="string", format="uuid", nullable=true),
     *     )
     *   ),
     *   @OA\Response(response=201, description="The session (200 when the id was already used)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=409, description="The id belongs to another club"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change the runs schedule.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(true));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $id = $request->input('id');

        if ($id && ($existing = ClubSession::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id) {
                return $this->idConflict();
            }

            return response()->json(RunPresenter::session($this->load($existing), $this->callerId($request)), 200);
        }

        if (($bad = $this->checkVenue($club, $request->input('venueId')))
            || ($bad = $this->checkCoordinator($club, $request->input('coordinatorMemberId')))) {
            return $bad;
        }

        $session = new ClubSession([
            'club_id' => $club->id,
            'title' => $request->input('title'),
            'venue_id' => $request->input('venueId'),
            'notes' => $request->input('notes'),
            'group_mode' => $request->input('groupMode'),
            'coordinator_member_id' => $request->input('coordinatorMemberId'),
        ] + SessionGenerator::times(
            $request->input('localDate'),
            $request->input('startTime'),
            $request->input('durationMin') === null ? null : (int) $request->input('durationMin'),
            $club->timezone ?: 'Europe/London'
        ));

        if ($id) {
            $session->id = $id;
        }

        $session->save();

        // A race is exactly one event, so its single group exists from the start (no leaders, never deleted).
        if ($session->group_mode === 'race') {
            SessionGroup::create([
                'club_id' => $club->id,
                'session_id' => $session->id,
                'kind' => 'event',
                'label' => mb_substr((string) $session->title, 0, 80),
                'status' => SessionGroup::STATUS_ACTIVE,
                'sort_order' => 0,
                'created_by_member_id' => $request->attributes->get('member')->id,
            ]);
        }

        return $this->json($request, $session, 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{id}",
     *   summary="Edit one run (committee/admin). Changing title, time, duration or venue of a series occurrence detaches it from the series. durationMin null clears the end time; leaving it out keeps it.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="The updated session"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such session"),
     *   @OA\Response(response=422, description="Validation error (incl. localDate on a series occurrence)"),
     * )
     */
    public function update(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change the runs schedule.');
        }

        $session = ClubSession::where('club_id', $club->id)->find($id);

        if (!$session) {
            return $this->notFound('No such session.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(false));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        if ($request->has('localDate') && $session->series_id
            && $request->input('localDate') !== $session->localDateYmd()) {
            return $this->invalid('localDate', 'A series occurrence keeps its date. Cancel it and add an ad-hoc run instead.');
        }

        if (($request->has('venueId') && ($bad = $this->checkVenue($club, $request->input('venueId'))))
            || ($request->has('coordinatorMemberId') && ($bad = $this->checkCoordinator($club, $request->input('coordinatorMemberId'))))) {
            return $bad;
        }

        $before = [$session->title, $session->venue_id, $session->local_start_time, $this->durationOf($session)];
        $movedFrom = ['starts_at' => $session->starts_at->copy(), 'venue_id' => $session->venue_id];

        foreach (['title' => 'title', 'venueId' => 'venue_id', 'notes' => 'notes', 'coordinatorMemberId' => 'coordinator_member_id'] as $key => $column) {
            if ($request->has($key)) {
                $session->{$column} = $request->input($key);
            }
        }

        // Key absent keeps the current length; an explicit null clears the end time.
        $duration = $request->has('durationMin') ? $request->input('durationMin') : $before[3];

        $session->fill(SessionGenerator::times(
            $request->input('localDate', $session->localDateYmd()),
            $request->input('startTime', $session->local_start_time),
            $duration === null ? null : (int) $duration,
            $club->timezone ?: 'Europe/London'
        ));

        $after = [$session->title, $session->venue_id, $session->local_start_time, $this->durationOf($session)];

        // Notes and coordinator are never overwritten by the generator, so only a
        // change to something the series controls needs to detach the row.
        if ($session->series_id && $before !== $after) {
            $session->is_detached = true;
        }

        $session->save();

        // The single group of a race carries the run's title.
        if ($session->group_mode === 'race' && $request->has('title')) {
            SessionGroup::where('session_id', $session->id)->where('kind', 'event')
                ->update(['label' => mb_substr((string) $session->title, 0, 80), 'updated_at' => Carbon::now()]);
        }

        if (!$movedFrom['starts_at']->equalTo($session->starts_at) || $movedFrom['venue_id'] !== $session->venue_id) {
            app(RunNotifier::class)->sessionChanged($session, 'changed', $this->callerId($request), $movedFrom);
        }

        return $this->json($request, $session);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{id}/cancel",
     *   summary="Cancel a run (committee/admin). Detaches it from its series.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\RequestBody(@OA\JsonContent(@OA\Property(property="reason", type="string", nullable=true))),
     *   @OA\Response(response=200, description="The updated session"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such session"),
     * )
     */
    public function cancel(Request $request, $clubId, $id)
    {
        return $this->setStatus($request, $id, ClubSession::STATUS_CANCELLED);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{id}/restore",
     *   summary="Un-cancel a run (committee/admin). Stays detached from its series.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="The updated session"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such session"),
     * )
     */
    public function restore(Request $request, $clubId, $id)
    {
        return $this->setStatus($request, $id, ClubSession::STATUS_SCHEDULED);
    }

    private function setStatus(Request $request, $id, string $status)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change the runs schedule.');
        }

        $session = ClubSession::where('club_id', $club->id)->find($id);

        if (!$session) {
            return $this->notFound('No such session.');
        }

        $validator = $this->makeValidator($request->all(), ['reason' => 'nullable|string|max:255']);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $cancelling = $status === ClubSession::STATUS_CANCELLED;
        $statusBefore = $session->status;
        $session->status = $status;
        $session->cancel_reason = $cancelling ? $request->input('reason') : null;
        $session->is_detached = true;
        $session->save();

        if ($statusBefore !== $status) {
            app(RunNotifier::class)->sessionChanged($session, $cancelling ? 'cancelled' : 'restored', $this->callerId($request));
        }

        return $this->json($request, $session);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{id}",
     *   summary="Soft-delete an ad-hoc run (committee/admin). Series occurrences are cancelled instead (409 series_session).",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=204, description="Deleted (also when it was already deleted)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such session"),
     *   @OA\Response(response=409, description="series_session"),
     * )
     */
    public function destroy(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change the runs schedule.');
        }

        $session = ClubSession::withTrashed()->where('club_id', $club->id)->find($id);

        if (!$session) {
            return $this->notFound('No such session.');
        }

        if ($session->series_id) {
            return response()->json([
                'error' => 'series_session',
                'message' => 'This run belongs to a series. Cancel it instead.',
            ], 409);
        }

        if (!$session->trashed()) {
            $session->delete();
        }

        return response('', 204);
    }
}
