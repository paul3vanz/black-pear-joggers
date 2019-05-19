<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\RegistrationController;
use Log;

class QueueProcessRegistrations extends Command
{
    protected $name = 'queue:registrations';

    public function handle()
    {
        Log::info('QueueProcessRegistrations');
        $registrationController = new RegistrationController();
        $registrationController->queueAllRegistrations();
    }

}