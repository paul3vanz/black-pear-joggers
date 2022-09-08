<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FetchPerformancesController;
use Log;

class QueueUpdatePersonalBests extends Command
{
    protected $name = 'queue:fetch:updatepersonalbests';

    public function handle()
    {
        Log::channel('slackInfo')->info('QueueUpdatePersonalBests');
        $FetchPerformancesController = new FetchPerformancesController();
        $FetchPerformancesController->queueUpdatePersonalBests();
    }
}
