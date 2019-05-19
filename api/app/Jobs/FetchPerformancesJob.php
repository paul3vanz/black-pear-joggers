<?php

namespace App\Jobs;

use App\Http\Controllers\FetchController;
use App\Models\Athlete;
use Log;

class FetchPerformancesJob extends Job
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
        $fetchController = new FetchController();
        $fetchController->fetchPerformances($this->athlete->id);

        Log::info("Fetch performances athleteId #" . $this->athlete->id);
    }
}
