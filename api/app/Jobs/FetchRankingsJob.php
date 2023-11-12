<?php

namespace App\Jobs;

use App\Http\Controllers\FetchRankingsController;
use App\Models\Athlete;
use Log;

class FetchRankingsJob extends Job
{
    protected $athlete;
    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(Athlete $athlete)
    {
        $this->athlete = $athlete;
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        $fetchRankingsController = new FetchRankingsController();
        $fetchRankingsController->fetchRankings($this->athlete->id);

        Log::info('Fetch rankings', ['athleteId' => $this->athlete->id]);
    }
}
