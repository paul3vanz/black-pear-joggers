<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesGroups;
use App\Models\ClubSession;
use App\Models\SessionGroup;
use App\Models\SessionRoute;
use App\Services\GroupPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Routes set for one run (e.g. a 10 and a 14 mile route for a long run); a group picks one
 * with `routeId`. Contract: mobile/docs/api-contract.md (D130).
 */
class AppSessionRouteController extends Controller
{
    use ManagesGroups;

    private const FIELDS = [
        'label' => 'label',
        'url' => 'url',
        'distanceValue' => 'distance_value',
        'distanceUnit' => 'distance_unit',
    ];

    private function rules(bool $creating): array
    {
        return [
            'id' => 'nullable|uuid',
            'label' => ($creating ? 'required' : 'sometimes|required') . '|string|max:80',
            'url' => [$creating ? 'required' : 'sometimes', 'required', 'string', 'max:500', 'url', 'regex:/^https?:\/\//i'],
            'distanceValue' => 'nullable|numeric|between:0.1,200',
            'distanceUnit' => 'nullable|in:mi,km',
        ];
    }

    /** The request body with label and url trimmed, so stray spaces from a paste do not fail validation. */
    private function input(Request $request): array
    {
        $data = $request->all();

        foreach (['label', 'url'] as $key) {
            if (isset($data[$key]) && is_string($data[$key])) {
                $data[$key] = trim($data[$key]);
            }
        }

        return $data;
    }

    /** Column values from the request, only for the keys present. */
    private function values(Request $request): array
    {
        $values = [];

        foreach (self::FIELDS as $key => $column) {
            if (!$request->has($key)) {
                continue;
            }

            $value = $request->input($key);
            $value = is_string($value) ? trim($value) : $value;
            $value = $value === '' ? null : $value;

            if ($column === 'distance_value' && $value !== null) {
                $value = round((float) $value, 2);
            }

            $values[$column] = $value;
        }

        return $values;
    }

    private function routeFor($club, $id): ?SessionRoute
    {
        $route = SessionRoute::where('club_id', $club->id)->find($id);

        return $route && $route->session && !$route->session->trashed() ? $route : null;
    }

    private function respond(SessionRoute $route, int $status = 200)
    {
        return response()->json(GroupPresenter::route(SessionRoute::withTrashed()->find($route->id)), $status);
    }

    private function notAllowed()
    {
        return $this->forbidden('Only the committee or the run coordinator can set the routes of a run.');
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/routes",
     *   summary="Add a route to a run (committee, admin or the run's coordinator). label and an http(s) url are required; distanceValue (0.1-200) needs distanceUnit. Idempotent on id. Groups of the run may then pick it with routeId.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="The route (200 on a replayed id)"),
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

        $validator = $this->makeValidator($this->input($request), $this->rules(true));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $values = $this->values($request) + ['distance_value' => null, 'distance_unit' => null];

        if ($values['distance_value'] !== null && $values['distance_unit'] === null) {
            return $this->invalidField('distanceUnit', 'distanceUnit is required when distanceValue is given.');
        }

        $id = $request->input('id');

        if ($id && ($existing = SessionRoute::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id || $existing->session_id !== $session->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            return $this->respond($existing, 200);
        }

        if (!$this->isManagerOrCoordinator($member, $session)) {
            return $this->notAllowed();
        }

        if ($bad = $this->closedResponse($session)) {
            return $bad;
        }

        $route = DB::transaction(function () use ($club, $session, $values, $id) {
            $max = SessionRoute::where('session_id', $session->id)->max('sort_order');
            $route = new SessionRoute($values + [
                'club_id' => $club->id,
                'session_id' => $session->id,
                'sort_order' => $max === null ? 0 : (int) $max + 1,
            ]);

            if ($id) {
                $route->id = $id;
            }

            $route->save();
            $session->touchForChange();

            return $route;
        });

        return $this->respond($route, 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/routes/{id}",
     *   summary="Edit a route of a run (committee, admin or the run's coordinator). distance fields sent as null are cleared; label and url cannot be empty. Groups that picked it follow the change.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The route"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such route"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $route = $this->routeFor($club, $id);

        if (!$route) {
            return $this->notFound('No such route.');
        }

        if (!$this->isManagerOrCoordinator($member, $route->session)) {
            return $this->notAllowed();
        }

        $rules = $this->rules(false);
        unset($rules['id']);
        $validator = $this->makeValidator($this->input($request), $rules);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $changes = $this->values($request);
        $final = $changes + $route->only(array_values(self::FIELDS));

        if ($final['distance_value'] !== null && $final['distance_unit'] === null) {
            return $this->invalidField('distanceUnit', 'distanceUnit is required when distanceValue is given.');
        }

        if ($bad = $this->closedResponse($route->session)) {
            return $bad;
        }

        DB::transaction(function () use ($route, $changes) {
            $route->fill($changes)->save();
            $route->session->touchForChange();
        });

        return $this->respond($route);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/routes/{id}",
     *   summary="Delete a route of a run (committee, admin or the run's coordinator). Groups that picked it end up with no route. 204, also when already deleted.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Deleted"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such route"),
     *   @OA\Response(response=409, description="session_cancelled | session_past"),
     * )
     */
    public function destroy(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $route = SessionRoute::withTrashed()->where('club_id', $club->id)->find($id);

        if (!$route || !$route->session || $route->session->trashed()) {
            return $this->notFound('No such route.');
        }

        if (!$this->isManagerOrCoordinator($member, $route->session)) {
            return $this->notAllowed();
        }

        if ($route->trashed()) {
            return response('', 204);
        }

        if ($bad = $this->closedResponse($route->session)) {
            return $bad;
        }

        DB::transaction(function () use ($route) {
            SessionGroup::where('route_id', $route->id)->update(['route_id' => null, 'updated_at' => Carbon::now()]);
            $route->delete();
            $route->session->touchForChange();
        });

        return response('', 204);
    }
}
