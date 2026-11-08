<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\ClubSession;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Services\RunNotifier;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * The group the caller last led (D127), so the "Lead a group" form can start from it on a phone that
 * never saw them create one (a new phone, a reinstall, or a group they joined as co-leader).
 */
class AppLastLedController extends Controller
{
    use AppResponses;

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/members/me/last-led",
     *   summary="The group the caller most recently led (a confirmed leader row), preferring one in the series given by seriesId and otherwise any run. Withdrawn sign-ups and event groups don't count.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="seriesId", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Response(response=200, description="{ group: { kind, label, description, paceUnit, paceFromS, paceToS, distanceValue, distanceUnit, sessionTitle, ledOn, sameSeries } | null }"),
     * )
     */
    public function show(Request $request, $clubId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $seriesId = $request->query('seriesId');

        $groupIds = SessionGroupLeader::where('member_id', $member->id)
            ->where('status', SessionGroupLeader::CONFIRMED)->pluck('group_id')->all();

        if (!$groupIds) {
            return response()->json(['group' => null]);
        }

        $groups = SessionGroup::withTrashed()->whereIn('id', $groupIds)->where('kind', '!=', 'event')->get();
        $sessions = ClubSession::withTrashed()->where('club_id', $club->id)
            ->whereIn('id', $groups->pluck('session_id')->unique())->get()->keyBy('id');

        $candidates = $groups->filter(fn (SessionGroup $g) => $sessions->has($g->session_id));
        $sameSeries = $seriesId === null || $seriesId === ''
            ? collect()
            : $candidates->filter(fn (SessionGroup $g) => $sessions->get($g->session_id)->series_id === $seriesId);

        $pool = $sameSeries->isNotEmpty() ? $sameSeries : $candidates;

        if ($pool->isEmpty()) {
            return response()->json(['group' => null]);
        }

        $latest = $pool->sortByDesc(fn (SessionGroup $g) => $sessions->get($g->session_id)->starts_at->getTimestamp())->first();
        $session = $sessions->get($latest->session_id);
        $tz = app(RunNotifier::class)->tz($club);

        return response()->json(['group' => [
            'kind' => $latest->kind,
            'label' => $latest->label,
            'description' => $latest->description,
            'paceUnit' => $latest->pace_unit,
            'paceFromS' => $latest->pace_from_s,
            'paceToS' => $latest->pace_to_s,
            'distanceValue' => $latest->distance_value !== null ? (float) $latest->distance_value : null,
            'distanceUnit' => $latest->distance_unit,
            'sessionTitle' => $session->title,
            'ledOn' => Carbon::parse($session->starts_at)->setTimezone($tz)->format('Y-m-d'),
            'sameSeries' => $sameSeries->isNotEmpty(),
        ]]);
    }
}
