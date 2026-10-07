<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesRuns;
use App\Models\ClubSession;
use App\Models\SessionSeries;
use App\Models\Venue;
use App\Services\NotificationPresenter;
use App\Services\RunPresenter;
use Illuminate\Http\Request;

class AppVenueController extends Controller
{
    use ManagesRuns;

    private function rules(bool $creating): array
    {
        return [
            'id' => 'nullable|uuid',
            'name' => ($creating ? 'required' : 'sometimes|required') . '|string|max:255',
            'address' => 'nullable|string|max:255',
            'lat' => 'nullable|numeric|between:-90,90',
            'lng' => 'nullable|numeric|between:-180,180',
            'notes' => 'nullable|string',
        ];
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/venues",
     *   summary="Venues the club runs from. With since: changes and tombstones.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: Venue[], serverTime }"),
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

        $query = Venue::where('club_id', $club->id)->orderBy('updated_at')->orderBy('id');

        if ($since) {
            $query->withTrashed()->where('updated_at', '>=', $since);
        }

        return response()->json([
            'items' => $query->get()->map(function ($venue) {
                return RunPresenter::venue($venue);
            })->all(),
            'serverTime' => NotificationPresenter::time($serverTime),
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/venues",
     *   summary="Add a venue (committee/admin). Idempotent on the client id.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"name"},
     *       @OA\Property(property="id", type="string", format="uuid"),
     *       @OA\Property(property="name", type="string"),
     *       @OA\Property(property="address", type="string", nullable=true),
     *       @OA\Property(property="lat", type="number", nullable=true),
     *       @OA\Property(property="lng", type="number", nullable=true),
     *       @OA\Property(property="notes", type="string", nullable=true),
     *     )
     *   ),
     *   @OA\Response(response=201, description="The venue (200 when the id was already used)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=409, description="The id belongs to another club"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change venues.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(true));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $id = $request->input('id');

        if ($id && ($existing = Venue::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id) {
                return $this->idConflict();
            }

            return response()->json(RunPresenter::venue($existing), 200);
        }

        $venue = new Venue([
            'club_id' => $club->id,
            'name' => $request->input('name'),
            'address' => $request->input('address'),
            'lat' => $request->input('lat'),
            'lng' => $request->input('lng'),
            'notes' => $request->input('notes'),
        ]);

        if ($id) {
            $venue->id = $id;
        }

        $venue->save();

        return response()->json(RunPresenter::venue($venue->fresh()), 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/venues/{id}",
     *   summary="Edit a venue (committee/admin). Accepts the same fields as create.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="The updated venue"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such venue"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change venues.');
        }

        $venue = Venue::where('club_id', $club->id)->find($id);

        if (!$venue) {
            return $this->notFound('No such venue.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(false));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        foreach (['name', 'address', 'lat', 'lng', 'notes'] as $field) {
            if ($request->has($field)) {
                $venue->{$field} = $request->input($field);
            }
        }

        $venue->save();

        return response()->json(RunPresenter::venue($venue->fresh()));
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/venues/{id}",
     *   summary="Soft-delete a venue (committee/admin). 409 in_use while an active series or future session uses it.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=204, description="Deleted (also when it was already deleted)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such venue"),
     *   @OA\Response(response=409, description="in_use"),
     * )
     */
    public function destroy(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change venues.');
        }

        $venue = Venue::withTrashed()->where('club_id', $club->id)->find($id);

        if (!$venue) {
            return $this->notFound('No such venue.');
        }

        if ($venue->trashed()) {
            return response('', 204);
        }

        $inUse = SessionSeries::where('club_id', $club->id)->where('venue_id', $venue->id)->exists()
            || ClubSession::where('club_id', $club->id)->where('venue_id', $venue->id)
                ->where('local_date', '>=', $this->clubToday($club))->exists();

        if ($inUse) {
            return response()->json([
                'error' => 'in_use',
                'message' => 'This venue is used by a series or an upcoming run.',
            ], 409);
        }

        $venue->delete();

        return response('', 204);
    }
}
