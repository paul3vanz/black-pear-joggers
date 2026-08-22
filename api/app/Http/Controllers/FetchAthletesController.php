<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChecksPowerOfTenColumn;
use App\Jobs\FetchAthleteJob;
use App\Models\Athlete;
use App\Services\PowerOfTenClient;
use Log;

/**
 * Everything we scrape from Power of 10 for an athlete, in one place.
 *
 * The performances and the runBritain handicap both come off the same page, so
 * fetching them separately downloaded it twice. These read it once. The older
 * per-thing routes stay for fetching just one of them by hand.
 */
class FetchAthletesController extends Controller
{
    use ChecksPowerOfTenColumn;

    private PowerOfTenClient $powerOfTen;

    public function __construct(?PowerOfTenClient $powerOfTen = null)
    {
        $this->powerOfTen = $powerOfTen ?: new PowerOfTenClient();
    }

    /**
     * Queue the nightly read for every affiliated member with a profile.
     */
    public function queueAllFetchAthletes()
    {
        if (!$this->powerOfTenColumnExists()) {
            return response()->json(['queued' => 0, 'athleteIds' => []]);
        }

        $athletes = Athlete::whereNotNull('po10_guid')
            ->get()
            ->filter(function ($item) { return $item->affiliated; })
            ->values();

        $athleteIds = array();

        foreach ($athletes as $athlete) {
            dispatch(new FetchAthleteJob($athlete));

            $athleteIds[] = $athlete->athlete_id;
        }

        Log::info('Queued Power of 10 fetches', ['athletes' => sizeof($athleteIds)]);

        return response()->json([
            'queued' => sizeof($athleteIds),
            'athleteIds' => $athleteIds,
        ]);
    }

    public function fetchAthlete($athleteId)
    {
        return response()->json($this->fetchAthleteFor($athleteId));
    }

    /**
     * Both scrapes for one athlete, from one download of their page.
     *
     * Sharing the client is what makes the second read free: it holds on to
     * the page the first read fetched.
     */
    public function fetchAthleteFor($athleteId): array
    {
        $athlete = Athlete::where('athlete_id', '=', $athleteId)->first();

        $performances = (new FetchPerformancesController($this->powerOfTen))
            ->fetchPerformancesFor($athleteId);

        $rankings = (new FetchRankingsController($this->powerOfTen))
            ->fetchRankingsFor($athleteId);

        return [
            // The handicap is often missing for someone who races plenty, so
            // the performances alone decide whether this worked.
            'success' => $performances['success'],
            'athleteId' => $athleteId,
            'name' => $athlete ? trim($athlete->first_name . ' ' . $athlete->last_name) : null,
            'message' => $performances['message'],
            'performances' => $performances,
            'rankings' => $rankings,
        ];
    }
}
