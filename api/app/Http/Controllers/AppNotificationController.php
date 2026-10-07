<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Services\NotificationCategories;
use App\Services\NotificationPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class AppNotificationController extends Controller
{
    use AppResponses;

    /** How many inbox rows a first (no since) fetch returns, newest first. */
    const FIRST_PAGE = 200;

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/notifications",
     *   summary="The caller's inbox. With since: rows created or changed (e.g. read) since then.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: Notification[], serverTime, unreadCount }"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     * )
     */
    public function index(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);

        $mine = function () use ($club, $member) {
            return Notification::where('club_id', $club->id)->where('member_id', $member->id);
        };

        if ($since) {
            $items = $mine()->where('updated_at', '>=', $since)->orderBy('updated_at')->orderBy('id')->get();
        } else {
            $items = $mine()->orderByDesc('created_at')->orderByDesc('id')->limit(self::FIRST_PAGE)->get()->reverse()->values();
        }

        return response()->json([
            'items' => $items->map(function ($n) {
                return NotificationPresenter::notification($n);
            })->all(),
            'serverTime' => NotificationPresenter::time($serverTime),
            'unreadCount' => $mine()->whereNull('read_at')->count(),
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/notifications/read",
     *   summary="Mark some (ids) or all of the caller's notifications read",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="ids", type="array", @OA\Items(type="string", format="uuid")),
     *       @OA\Property(property="all", type="boolean"),
     *     )
     *   ),
     *   @OA\Response(response=204, description="Marked read"),
     *   @OA\Response(response=422, description="Neither ids nor all given"),
     * )
     */
    public function markRead(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        $validator = $this->makeValidator($request->all(), [
            'ids' => 'required_without:all|array',
            'ids.*' => 'string',
            'all' => 'required_without:ids|boolean',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $query = Notification::where('club_id', $club->id)
            ->where('member_id', $member->id)
            ->whereNull('read_at');

        if (!$request->boolean('all')) {
            $query->whereIn('id', $request->input('ids', []));
        }

        $query->update(['read_at' => Carbon::now(), 'updated_at' => Carbon::now()]);

        return response('', 204);
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/notification-preferences",
     *   summary="The caller's push settings per notification category",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="{ categories: [...] }"),
     * )
     */
    public function preferences(Request $request)
    {
        return response()->json($this->preferencesFor($request));
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/notification-preferences",
     *   summary="Set push on/off per category, e.g. { club_updates: false }. Locked and unknown categories are ignored.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="{ categories: [...] }"),
     *   @OA\Response(response=422, description="A value is not a boolean"),
     * )
     */
    public function updatePreferences(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $input = $request->json()->all() ?: $request->all();

        $visible = NotificationCategories::visibleFor($member);
        $changes = [];

        foreach ($input as $category => $value) {
            if (!isset($visible[$category]) || NotificationCategories::isLocked($category)) {
                continue;
            }

            if (!is_bool($value)) {
                return response()->json([
                    'error' => 'validation_failed',
                    'message' => "$category must be true or false.",
                    'errors' => [$category => ["$category must be true or false."]],
                ], 422);
            }

            $changes[$category] = $value;
        }

        foreach ($changes as $category => $enabled) {
            NotificationPreference::updateOrCreate(
                ['member_id' => $member->id, 'category' => $category],
                ['club_id' => $club->id, 'push_enabled' => $enabled]
            );
        }

        return response()->json($this->preferencesFor($request));
    }

    private function preferencesFor(Request $request): array
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        $saved = NotificationPreference::where('club_id', $club->id)
            ->where('member_id', $member->id)
            ->pluck('push_enabled', 'category');

        $enabled = [];
        foreach (NotificationCategories::visibleFor($member) as $category => $def) {
            $enabled[$category] = $saved->has($category)
                ? (bool) $saved->get($category)
                : NotificationCategories::defaultFor($category, $member);
        }

        return NotificationPresenter::categories($member, $enabled);
    }
}
