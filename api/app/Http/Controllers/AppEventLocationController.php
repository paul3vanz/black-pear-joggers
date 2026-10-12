<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesRuns;
use App\Models\EventLocation;
use App\Services\NotificationPresenter;
use App\Services\RunPresenter;
use Illuminate\Http\Request;

/**
 * The club's list of event locations: parkruns, races and other places (Phase 8, D78).
 * Contract: mobile/docs/api-contract.md.
 */
class AppEventLocationController extends Controller
{
    use ManagesRuns;

    private function rules(bool $creating): array
    {
        return [
            'id' => 'nullable|uuid',
            'kind' => 'nullable|in:' . implode(',', EventLocation::KINDS),
            'name' => ($creating ? 'required' : 'sometimes|required') . '|string|max:120',
            'region' => 'nullable|string|max:80',
            'country' => 'nullable|string|size:2',
            'lat' => 'nullable|numeric|between:-90,90',
            'lng' => 'nullable|numeric|between:-180,180',
            'url' => ['nullable', 'string', 'max:255', 'regex:/^https?:\/\//'],
        ];
    }

    private function invalidField(string $field, string $message)
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => $message,
            'errors' => [$field => [$message]],
        ], 422);
    }

    /** The value to store: '' becomes null, numbers are rounded to the column's 6 decimals. */
    private function value(Request $request, string $key)
    {
        $value = $request->input($key);

        if (is_string($value)) {
            $value = trim($value);
        }

        if ($value === '') {
            return null;
        }

        if (($key === 'lat' || $key === 'lng') && $value !== null) {
            return round((float) $value, 6);
        }

        return $key === 'country' && $value !== null ? strtoupper($value) : $value;
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/event-locations",
     *   summary="The club's event locations (parkruns, races, other). Without since: every live row. With since: changes and tombstones.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: EventLocation[], serverTime }"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     *   @OA\Response(response=422, description="Bad since"),
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

        $query = EventLocation::where('club_id', $club->id)->orderBy('updated_at')->orderBy('id');

        if ($since) {
            $query->withTrashed()->where('updated_at', '>=', $since);
        }

        return response()->json([
            'items' => $query->get()->map(function ($location) {
                return RunPresenter::eventLocation($location);
            })->all(),
            'serverTime' => NotificationPresenter::time($serverTime),
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/event-locations",
     *   summary="Add an event location. Any linked member may add race/other (kind defaults to other); parkrun is committee/admin only. Idempotent on id; the same kind and name (any case) returns the existing row with 200.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"name"},
     *       @OA\Property(property="id", type="string", format="uuid"),
     *       @OA\Property(property="kind", type="string", enum={"parkrun","race","other"}),
     *       @OA\Property(property="name", type="string", maxLength=120),
     *       @OA\Property(property="region", type="string", nullable=true),
     *       @OA\Property(property="lat", type="number", nullable=true),
     *       @OA\Property(property="lng", type="number", nullable=true),
     *       @OA\Property(property="url", type="string", nullable=true),
     *     )
     *   ),
     *   @OA\Response(response=201, description="The location (200 for a replayed id or an existing duplicate)"),
     *   @OA\Response(response=403, description="A parkrun location needs the committee"),
     *   @OA\Response(response=409, description="The id belongs to another club"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if ($request->input('kind') === 'parkrun' && !$this->canManageRuns($member)) {
            return $this->forbidden('Only the committee can add parkrun locations.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(true));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $id = $request->input('id');

        if ($id && ($existing = EventLocation::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id) {
                return $this->idConflict();
            }

            return response()->json(RunPresenter::eventLocation($existing), 200);
        }

        $kind = $request->input('kind') ?: 'other';
        $name = trim((string) $request->input('name'));

        if ($name === '') {
            return $this->invalidField('name', 'The name field is required.');
        }

        $duplicate = EventLocation::where('club_id', $club->id)->where('kind', $kind)
            ->whereRaw('lower(name) = ?', [mb_strtolower($name)])->orderBy('created_at')->first();

        if ($duplicate) {
            return response()->json(RunPresenter::eventLocation($duplicate), 200);
        }

        $location = new EventLocation([
            'club_id' => $club->id,
            'kind' => $kind,
            'name' => $name,
            'region' => $this->value($request, 'region'),
            'lat' => $this->value($request, 'lat'),
            'lng' => $this->value($request, 'lng'),
            'url' => $this->value($request, 'url'),
            'source' => 'manual',
        ]);

        if ($id) {
            $location->id = $id;
        }

        $location->save();

        return response()->json(RunPresenter::eventLocation($location->fresh()), 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/event-locations/{id}",
     *   summary="Edit an event location (committee/admin): name, region, country, lat, lng, url. The kind is fixed.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="The updated location"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such location"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change event locations.');
        }

        $location = EventLocation::where('club_id', $club->id)->find($id);

        if (!$location) {
            return $this->notFound('No such event location.');
        }

        $rules = $this->rules(false);
        unset($rules['id'], $rules['kind']);
        $validator = $this->makeValidator($request->all(), $rules);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        foreach (['name', 'region', 'country', 'lat', 'lng', 'url'] as $field) {
            if ($request->has($field)) {
                $value = $this->value($request, $field);

                if ($field === 'name' && $value === null) {
                    return $this->invalidField('name', 'The name field is required.');
                }

                $location->{$field} = $value;
            }
        }

        $location->save();

        return response()->json(RunPresenter::eventLocation($location->fresh()));
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/event-locations/{id}",
     *   summary="Soft-delete an event location (committee/admin). Groups made from it keep their label and locationId.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=204, description="Deleted (also when it was already deleted)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such location"),
     * )
     */
    public function destroy(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');

        if (!$this->canManageRuns($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can change event locations.');
        }

        $location = EventLocation::withTrashed()->where('club_id', $club->id)->find($id);

        if (!$location) {
            return $this->notFound('No such event location.');
        }

        if (!$location->trashed()) {
            $location->delete();
        }

        return response('', 204);
    }
}
