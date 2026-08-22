<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FetchAthletesController;
use Log;

class QueueFetchAthletes extends Command
{
    protected $name = 'queue:fetch:athletes';

    public function handle()
    {
        Log::info('QueueFetchAthletes');
        $fetchAthletesController = new FetchAthletesController();
        $fetchAthletesController->queueAllFetchAthletes();
    }
}
