<?php

namespace App\Jobs;

use App\Http\Controllers\FetchPerformancesController;
use App\Http\Controllers\FetchRankingsController;
use App\Models\Athlete;
use App\Services\PowerOfTenClient;
use Log;

/**
 * Everything we scrape for one athlete, from one download of their page.
 *
 * The performances and the runBritain handicap live on the same Power of 10
 * page, and fetching them as separate jobs downloaded it twice a night for
 * every member. Share one client between the two so the second read comes out
 * of the page it is already holding.
 */
class FetchAthleteJob extends Job
{
    protected $athlete;

    public function __construct(Athlete $athlete)
    {
        $this->athlete = $athlete;
    }

    public function handle()
    {
        $powerOfTen = new PowerOfTenClient();

        (new FetchPerformancesController($powerOfTen))->fetchPerformances($this->athlete->athlete_id);
        (new FetchRankingsController($powerOfTen))->fetchRankings($this->athlete->athlete_id);

        Log::info('Fetch athlete', ['athleteId' => $this->athlete->athlete_id]);
    }
}
