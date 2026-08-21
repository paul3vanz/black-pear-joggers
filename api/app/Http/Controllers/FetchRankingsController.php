<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChecksPowerOfTenColumn;
use App\Jobs\FetchRankingsJob;
use App\Models\Athlete;
use App\Models\Ranking;
use App\Services\PowerOfTenClient;
use Log;

/**
 * Rankings used to come from runbritainrankings.com/runners/profile.aspx, which
 * no longer exists: the URL returns "Not Found" and the domain redirects to
 * powerof10.uk. The runBritain handicap now lives on the Power of 10 athlete
 * page as an embedded chart, so this reads the same page the performance fetch
 * uses rather than a second site.
 */
class FetchRankingsController extends Controller
{
    use ChecksPowerOfTenColumn;

    private PowerOfTenClient $powerOfTen;

    public function __construct(?PowerOfTenClient $powerOfTen = null)
    {
        $this->powerOfTen = $powerOfTen ?: new PowerOfTenClient();
    }

    public function queueAllFetchRankings()
    {
        $athleteIds = array();

        if (!$this->powerOfTenColumnExists()) {
            return response()->json($athleteIds);
        }

        $athletes = Athlete::whereNotNull('po10_guid')
            ->get()
            ->filter(function ($item) { return $item->affiliated; })
            ->values();

        foreach ($athletes as $athlete) {
            dispatch(new FetchRankingsJob($athlete));

            $athleteIds[] = $athlete->athlete_id;
        }

        return response()->json($athleteIds);
    }

    public function fetchRankings($athleteId)
    {
        Log::info("fetchRankings($athleteId)");

        $addedRankings = array();

        $athletes = Athlete::where('athlete_id', '=', $athleteId)->get();

        foreach ($athletes as $athlete) {
            if (!$athlete->po10_guid) {
                Log::info('Skipping athlete with no Power of 10 GUID', ['athleteId' => $athleteId]);

                continue;
            }

            $html = $this->powerOfTen->fetchAthletePage($athlete->po10_guid);

            if ($html === null) {
                Log::info('No ranking profile for athlete ' . $athleteId);

                continue;
            }

            $addedRankings = $this->storeRankings(
                $athlete,
                $this->powerOfTen->parseRankings($html)
            );

            Log::info('Added ' . sizeof($addedRankings) . ' rankings for athlete ' . $athleteId);
        }

        return response()->json($addedRankings);
    }

    private function storeRankings(Athlete $athlete, array $rankings): array
    {
        if (!$rankings) {
            Log::info("no rankings for $athlete->id");

            return array();
        }

        // TODO: We want to keep all old data, just mark as old, not remove
        Ranking::where('athlete_id', $athlete->id)->delete();

        $added = array();

        foreach ($rankings as $ranking) {
            $added[] = Ranking::firstOrCreate([
                'athlete_id' => $athlete->id,
                'date' => $ranking['date'],
                'ranking' => $ranking['ranking'],
            ]);
        }

        return $added;
    }
}
