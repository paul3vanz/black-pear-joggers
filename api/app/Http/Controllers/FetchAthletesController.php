<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChecksPowerOfTenColumn;
use App\Jobs\FetchAthleteJob;
use App\Models\Athlete;
use Log;

/**
 * Queues the nightly Power of 10 read for every affiliated member.
 *
 * This replaces queueing performances and rankings separately. Both come off
 * the same page, so one job per athlete downloads it once instead of twice.
 * The older routes stay for fetching one thing on its own by hand.
 */
class FetchAthletesController extends Controller
{
    use ChecksPowerOfTenColumn;

    public function queueAllFetchAthletes()
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
            dispatch(new FetchAthleteJob($athlete));

            $athleteIds[] = $athlete->athlete_id;
        }

        Log::info('Queued Power of 10 fetches', ['athletes' => sizeof($athleteIds)]);

        return response()->json($athleteIds);
    }
}
