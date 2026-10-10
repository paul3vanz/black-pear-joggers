<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\SessionSeries;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Push settings beyond per-category on/off: the daily push limit and the
 * run-reminder override per weekly series (Phase 5, D34/D35).
 */
class AppNotificationSettingsController extends Controller
{
    use AppResponses;

    const MAX_CAP = 50;

    private function body($club, $member): array
    {
        $pref = MemberPreference::where('club_id', $club->id)->where('member_id', $member->id)->first();

        $overrides = MemberSeriesPref::where('club_id', $club->id)
            ->where('member_id', $member->id)
            ->pluck('reminders', 'series_id');

        $series = SessionSeries::where('club_id', $club->id)
            ->orderBy('weekday')->orderBy('start_time')->orderBy('title')
            ->get()
            ->map(function ($s) use ($overrides) {
                return [
                    'seriesId' => $s->id,
                    'title' => $s->title,
                    'weekday' => (int) $s->weekday,
                    'localStartTime' => $s->startHm(),
                    'reminders' => $overrides->get($s->id, MemberSeriesPref::AUTO),
                ];
            })
            ->all();

        return [
            'dailyPushCap' => NotificationService::capFrom($pref ? $pref->push_daily_cap : null),
            'defaultDailyPushCap' => NotificationService::DEFAULT_DAILY_CAP,
            'series' => $series,
        ];
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/notification-settings",
     *   summary="The caller's daily push limit (0 = no limit) and run-reminder setting (auto|on|off) per live series.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="{ dailyPushCap, defaultDailyPushCap, series: [...] }"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     * )
     */
    public function show(Request $request)
    {
        return response()->json($this->body($request->attributes->get('club'), $request->attributes->get('member')));
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/notification-settings",
     *   summary="Save any of { dailyPushCap: 0..50, series: { seriesId: auto|on|off } }. auto removes the override. Returns the GET shape.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="The saved settings"),
     *   @OA\Response(response=422, description="Bad cap, bad value, or a series that is not a live series of this club (nothing saved)"),
     * )
     */
    public function update(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $input = $request->json()->all() ?: $request->all();

        $validator = $this->makeValidator($input, [
            'dailyPushCap' => 'integer|between:0,' . self::MAX_CAP,
            'series' => 'array',
            'series.*' => 'required|in:auto,on,off',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $series = $input['series'] ?? [];

        if ($series) {
            $live = SessionSeries::where('club_id', $club->id)->whereIn('id', array_map('strval', array_keys($series)))->pluck('id')->all();

            foreach (array_keys($series) as $id) {
                if (!in_array((string) $id, $live, true)) {
                    return response()->json([
                        'error' => 'validation_failed',
                        'message' => "series.$id is not a series of this club.",
                        'errors' => ["series.$id" => ["series.$id is not a series of this club."]],
                    ], 422);
                }
            }
        }

        DB::transaction(function () use ($club, $member, $input, $series) {
            if (array_key_exists('dailyPushCap', $input)) {
                $pref = MemberPreference::firstOrNew(['club_id' => $club->id, 'member_id' => $member->id]);
                $pref->pace_unit = $pref->pace_unit ?: 'mi';
                $pref->distance_unit = $pref->distance_unit ?: 'mi';
                $pref->push_daily_cap = (int) $input['dailyPushCap'];
                $pref->save();
            }

            foreach ($series as $id => $value) {
                if ($value === MemberSeriesPref::AUTO) {
                    MemberSeriesPref::where('member_id', $member->id)->where('series_id', $id)->delete();

                    continue;
                }

                MemberSeriesPref::updateOrCreate(
                    ['member_id' => $member->id, 'series_id' => (string) $id],
                    ['club_id' => $club->id, 'reminders' => $value]
                );
            }
        });

        return response()->json($this->body($club, $member));
    }
}
