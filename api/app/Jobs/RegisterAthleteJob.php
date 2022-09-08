<?php

namespace App\Jobs;

use App\Http\Controllers\RegistrationController;
use App\Http\Controllers\MembershipController;
use App\Models\Registration;
use Log;

class RegisterAthleteJob extends Job
{
    protected $membershipController;
    protected $registration;
    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(MembershipController $membershipController, Registration $registration)
    {
        $this->membershipController = $membershipController;
        $this->registration = $registration;
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        $registrationController = new RegistrationController($this->membershipController);
        $registrationController->processRegistration($this->registration);

        Log::channel('slackInfo')->info("Process registration ID #" . $this->registration->id);
    }
}
