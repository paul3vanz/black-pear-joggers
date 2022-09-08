<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\RegistrationController;
use App\Http\Controllers\MembershipController;
use Log;

class QueueProcessRegistrations extends Command
{
    protected $name = 'queue:registrations';

    public function handle()
    {
        Log::channel('slackInfo')->info('QueueProcessRegistrations');
        $registrationController = new RegistrationController(new MembershipController());
        $registrationController->createRegistrationsFromMemberships();
        $registrationController->queueAllRegistrations();
    }
}
