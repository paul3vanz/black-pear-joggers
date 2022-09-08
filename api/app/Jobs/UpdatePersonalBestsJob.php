<?php

namespace App\Jobs;

use App\Http\Controllers\FetchPerformancesController;
use Log;

class UpdatePersonalBestsJob extends Job
{
    protected $athlete;
    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct()
    {
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        $fetchPerformancesController = new FetchPerformancesController();
        $fetchPerformancesController->updatePersonalBests();

        Log::channel('slackInfo')->info("Run update personal bests job");
    }
}
