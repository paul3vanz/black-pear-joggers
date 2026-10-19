<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\MemberSeriesPref;
use App\Services\FollowResolver;
use App\Services\SeriesFollows;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * "Runs I follow" (D117): the caller's follow | auto | hide per weekly series, which decides both
 * what shows in My runs and which runs they are reminded about. Writes apply on tap and are
 * idempotent; the bulk write returns the previous modes so the app can offer Undo.
 */
class AppFollowController extends Controller
{
    use AppResponses;

    /** @var SeriesFollows */
    private $follows;

    public function __construct(SeriesFollows $follows)
    {
        $this->follows = $follows;
    }

    /** @return array[] one entry per given series, in the given order */
    private function rows($club, $member, $series): array
    {
        $modes = $this->follows->modesForMember($club->id, $member->id, $series);
        $now = Carbon::now();

        return $series->map(function ($s) use ($modes, $member, $now) {
            $usual = in_array($member->id, $this->follows->usualMemberIds($s, $now), true);
            $mode = $modes[$s->id];

            return [
                'seriesId' => $s->id,
                'title' => $s->title,
                'weekday' => (int) $s->weekday,
                'localStartTime' => $s->startHm(),
                'groupMode' => $s->group_mode,
                'mode' => $mode,
                'usuallyComes' => $usual,
                'followed' => FollowResolver::resolve(null, $mode, $usual)['followed'],
            ];
        })->values()->all();
    }

    /** 422 naming the first id that is not a live series of the club, or null. */
    private function unknownSeries($club, array $ids)
    {
        $live = $this->follows->series($club->id)->pluck('id')->all();

        foreach ($ids as $id) {
            if (!in_array((string) $id, $live, true)) {
                return response()->json([
                    'error' => 'validation_failed',
                    'message' => "series.$id is not a series of this club.",
                    'errors' => ["series.$id" => ["series.$id is not a series of this club."]],
                ], 422);
            }
        }

        return null;
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/follows",
     *   summary="The caller's mode (follow|auto|hide) for every live series in week order, with usuallyComes (went to one of the last 6 runs) and followed (what the mode resolves to).",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="{ series: [{ seriesId, title, weekday, localStartTime, groupMode, mode, usuallyComes, followed }] }"),
     * )
     */
    public function index(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        return response()->json(['series' => $this->rows($club, $member, $this->follows->series($club->id))]);
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/follows/{seriesId}",
     *   summary="Set one series to follow, auto or hide. Returns that series' entry.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="seriesId", in="path", required=true, @OA\Schema(type="string")),
     *   @OA\Response(response=200, description="{ seriesId, title, weekday, localStartTime, groupMode, mode, usuallyComes, followed }"),
     *   @OA\Response(response=404, description="Not a live series of this club"),
     *   @OA\Response(response=422, description="Bad mode"),
     * )
     */
    public function update(Request $request, $clubId, $seriesId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        $validator = $this->makeValidator($request->all(), ['mode' => 'required|in:' . implode(',', MemberSeriesPref::MODES)]);
        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $series = $this->follows->series($club->id)->where('id', (string) $seriesId)->values();
        if ($series->isEmpty()) {
            return $this->notFound('No such series.');
        }

        $this->follows->set($club->id, $member->id, [(string) $seriesId => $request->input('mode')]);

        return response()->json($this->rows($club, $member, $series)[0]);
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/follows",
     *   summary="Set many series at once: { seriesIds: [...], mode } (Follow all, Follow everything) or { modes: { seriesId: mode } } (Undo). Returns { previous: { seriesId: mode }, series: [all entries] }; nothing is saved when any id or mode is bad.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="{ previous, series }"),
     *   @OA\Response(response=422, description="Neither form given, a bad mode, or a series that is not a live series of this club"),
     * )
     */
    public function updateMany(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $input = $request->json()->all() ?: $request->all();
        $modeRule = 'in:' . implode(',', MemberSeriesPref::MODES);

        if (array_key_exists('modes', $input)) {
            $validator = $this->makeValidator($input, ['modes' => 'required|array', 'modes.*' => 'required|' . $modeRule]);
            if ($validator->fails()) {
                return $this->validationFailed($validator);
            }
            $modes = array_map('strval', $input['modes']);
        } else {
            $validator = $this->makeValidator($input, [
                'seriesIds' => 'present|array',
                'seriesIds.*' => 'string',
                'mode' => 'required|' . $modeRule,
            ]);
            if ($validator->fails()) {
                return $this->validationFailed($validator);
            }
            $modes = array_fill_keys($input['seriesIds'], $input['mode']);
        }

        if ($bad = $this->unknownSeries($club, array_keys($modes))) {
            return $bad;
        }

        $previous = $modes ? $this->follows->set($club->id, $member->id, $modes) : [];

        return response()->json([
            'previous' => (object) $previous,
            'series' => $this->rows($club, $member, $this->follows->series($club->id)),
        ]);
    }
}
