<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FetchRankingsController;
use Log;

class QueueFetchRankings extends Command
{
    protected $name = 'queue:fetch:rankings';

    public function handle()
    {
        Log::info('QueueFetchRankings');
        $FetchRankingsController = new FetchRankingsController();
        $FetchRankingsController->queueAllFetchRankings();
    }
}
