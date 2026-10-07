<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesRuns;
use App\Models\SessionSeries;
use App\Services\NotificationPresenter;
use App\Services\RunPresenter;
use App\Services\SessionGenerator;
use Illuminate\Http\Request;

class AppSeriesController extends Controller
{
    use ManagesRuns;

    /** request key => column */
    const FIELDS = [
        'title' => 'title',
        'description' => 'description',
        'venueId' => 'venue_id',
        'weekday' => 'weekday',
        'startTime' => 'start_time',
        'durationMin' => 'duration_min',
        'intervalWeeks' => 'interval_weeks',
        'validFrom' => 'valid_from',
        'validUntil' => 'valid_until',
        'groupMode' => 'group_mode',
        'cmsSlug' => 'cms_slug',
    ];

    private function rules(bool $creating): array
    {
        $required = $creating ? 'required' : 'sometimes|required';

        return [
            'id' => 'nullable|uuid',
            'title' => $required . '|string|max:255',
            'description' => 'nullable|string',
            'venueId' => 'nullable|uuid',
            'weekday' => $required . '|integer|between:1,7',
            'startTime' => $required . '|date_format:H:i',
            'durationMin' => $required . '|integer|between:15,600',
            'intervalWeeks' => 'sometimes|required|integer|between:1,8',
            'validFrom' => 'sometimes|required|date_format:Y-m-d',
            'validUntil' => 'nullable|date_format:Y-m-d',
            'groupMode' => $required . '|in:' . implode(',', SessionSeries::GROUP_MODES),
            'cmsSlug' => 'nullable|string|max:100',
        ];
    }

    private function untilBeforeFrom()
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => 'validUntil must not be before validFrom.',
            'errors' => ['validUntil' => ['validUntil must not be before validFrom.']],
        ], 422);
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/series",
     *   summary="Weekly run series. With since: changes and tombstones.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: Series[], serverTime }"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     * )
     */
    public function index(Request $request)
    {
        $club = $request->attributes->get('club');

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);

        $query = SessionSeries::where('club_id', $club->id)->orderBy('updated_at')->orderBy('id');

        if ($since) {
            $query->withTrashed()->where('updated_at', '>=', $since);
        }

        return response()->json([
            'items' => $query->get()->map(function ($series) {
                return RunPresenter::series($series);
            })->all(),
            'serverTime' => NotificationPresenter::time($serverTime),
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/series",
     *   summary="Create a weekly series (committee/admin) and generate its sessions. Idempotent on the client id.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"title","weekday","startTime","durationMin","groupMode"},
     *       @OA\Property(property="id", type="string", format="uuid"),
     *       @OA\Property(property="title", type="string"),
     *       @OA\Property(property="description", type="string", nullable=true),
     *       @OA\Property(property="venueId", type="string", format="uuid", nullable=true),
     *       @OA\Property(property="weekday", type="integer", minimum=1, maximum=7),
     *       @OA\Property(property="startTime", type="string", example="19:00"),
     *       @OA\Property(property="durationMin", type="integer", minimum=15, maximum=600),
     *       @OA\Property(property="intervalWeeks", type="integer", minimum=1, maximum=8),
     *       @OA\Property(property="validFrom", type="string", format="date"),
     *       @OA\Property(property="validUntil", type="string", format="date", nullable=true),
     *       @OA\Property(property="groupMode", type="string", enum={"paced","single","open","routes"}),
     *       @OA\Property(property="cmsSlug", type="string", nullable=true),
     *     )
     *   ),
     *   @OA\Response(response=201, description="The series (200 when the id was already used)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=409, description="The id belongs to another club"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request, SessionGenerator $generator)
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

        if ($id && ($existing = SessionSeries::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id) {
                return $this->idConflict();
            }

            return response()->json(RunPresenter::series($existing), 200);
        }

        if ($bad = $this->checkVenue($club, $request->input('venueId'))) {
            return $bad;
        }

        $validFrom = $request->input('validFrom') ?: $this->clubToday($club);
        $validUntil = $request->input('validUntil');

        if ($validUntil && $validUntil < $validFrom) {
            return $this->untilBeforeFrom();
        }

        $series = new SessionSeries(['club_id' => $club->id, 'valid_from' => $validFrom]);

        foreach (self::FIELDS as $key => $column) {
            if ($key !== 'validFrom' && $request->has($key)) {
                $series->{$column} = $request->input($key);
            }
        }

        if ($id) {
            $series->id = $id;
        }

        $series->save();
        $generator->generateForSeries($series->fresh());

        return response()->json(RunPresenter::series($series->fresh()), 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/series/{id}",
     *   summary="Edit a series (committee/admin). Future non-detached sessions are regenerated.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="The updated series"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such series"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request, SessionGenerator $generator, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change the runs schedule.');
        }

        $series = SessionSeries::where('club_id', $club->id)->find($id);

        if (!$series) {
            return $this->notFound('No such series.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(false));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        if ($request->has('venueId') && ($bad = $this->checkVenue($club, $request->input('venueId')))) {
            return $bad;
        }

        foreach (self::FIELDS as $key => $column) {
            if ($request->has($key)) {
                $series->{$column} = $request->input($key);
            }
        }

        $until = $series->validUntilYmd();

        if ($until !== null && $until < $series->validFromYmd()) {
            return $this->untilBeforeFrom();
        }

        $series->save();
        $generator->generateForSeries($series->fresh());

        return response()->json(RunPresenter::series($series->fresh()));
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/series/{id}",
     *   summary="Soft-delete a series (committee/admin). Its future non-detached sessions are removed.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=204, description="Deleted (also when it was already deleted)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such series"),
     * )
     */
    public function destroy(Request $request, SessionGenerator $generator, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change the runs schedule.');
        }

        $series = SessionSeries::withTrashed()->where('club_id', $club->id)->find($id);

        if (!$series) {
            return $this->notFound('No such series.');
        }

        if (!$series->trashed()) {
            $series->delete();
        }

        $generator->generateForSeries($series);

        return response('', 204);
    }
}
