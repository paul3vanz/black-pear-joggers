<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\RegistrationController;
use App\Http\Controllers\MembershipController;
use Log;
use DB;

class StartDatabaseCleanup extends Command
{
    protected $name = 'db:cleanup';

    public function handle()
    {
        Log::info('StartDatabaseCleanup');

        DB::delete('DELETE FROM logs WHERE created_at <= NOW() - INTERVAL 1 WEEK');
}
}
