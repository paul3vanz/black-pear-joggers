<?php

namespace App\Jobs;

use App\Http\Controllers\FetchAthletesController;
use App\Models\Athlete;
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
        (new FetchAthletesController())->fetchAthleteFor($this->athlete->athlete_id);

        Log::info('Fetch athlete', ['athleteId' => $this->athlete->athlete_id]);
    }
}
