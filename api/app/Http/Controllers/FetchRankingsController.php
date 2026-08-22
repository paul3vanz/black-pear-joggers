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
        return response()->json($this->fetchRankingsFor($athleteId));
    }

    /**
     * Scrape and store one athlete's handicap history, reporting what
     * happened. Shaped like the performance fetch so the admin app can show
     * both outcomes the same way.
     *
     * @return array{success: bool, athleteId: mixed, added: int, message: ?string}
     */
    public function fetchRankingsFor($athleteId): array
    {
        Log::info("fetchRankings($athleteId)");

        $athletes = Athlete::where('athlete_id', '=', $athleteId)->get();

        if ($athletes->isEmpty()) {
            return ['success' => false, 'athleteId' => $athleteId, 'added' => 0, 'message' => 'No athlete with that id'];
        }

        $added = 0;
        $failure = null;

        foreach ($athletes as $athlete) {
            if (!$athlete->po10_guid) {
                Log::info('Skipping athlete with no Power of 10 GUID', ['athleteId' => $athleteId]);
                $failure = $failure ?: 'No Power of 10 profile linked';

                continue;
            }

            $html = $this->powerOfTen->fetchAthletePage($athlete->po10_guid);

            if ($html === null) {
                Log::info('No ranking profile for athlete ' . $athleteId);
                $failure = $failure ?: 'Power of 10 has no profile at that address';

                continue;
            }

            $added += sizeof($this->storeRankings(
                $athlete,
                $this->powerOfTen->parseRankings($html)
            ));

            Log::info('Added ' . $added . ' rankings for athlete ' . $athleteId);
        }

        if ($failure && !$added) {
            return ['success' => false, 'athleteId' => $athleteId, 'added' => 0, 'message' => $failure];
        }

        return ['success' => true, 'athleteId' => $athleteId, 'added' => $added, 'message' => null];
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
