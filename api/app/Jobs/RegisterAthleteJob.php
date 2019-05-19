<?php

namespace App\Jobs;

use App\Http\Controllers\RegistrationController;
use App\Models\Registration;
use Log;

class RegisterAthleteJob extends Job
{
    protected $registration;
    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(Registration $registration)
    {
        $this->registration = $registration;
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        $registrationController = new RegistrationController();
        $registrationController->processRegistration($this->registration);

        Log::info("Process registration ID #" . $this->registration->id);
    }
}
