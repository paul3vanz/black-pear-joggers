<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FetchController;
use Log;

class QueueFetchPerformances extends Command
{
    protected $name = 'queue:fetch:performances';

    public function handle()
    {
        Log::info('QueueFetchPerformances');
        $fetchController = new FetchController();
        $fetchController->queueAllFetchPerformances();
    }

}