<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FetchPerformancesController;
use Log;

class QueueFetchPerformances extends Command
{
    protected $name = 'queue:fetch:performances';

    public function handle()
    {
        Log::channel('slackInfo')->info('QueueFetchPerformances');
        $FetchPerformancesController = new FetchPerformancesController();
        $FetchPerformancesController->queueAllFetchPerformances();
    }
}
