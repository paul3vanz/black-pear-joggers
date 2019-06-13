<?php

namespace App\Http\Controllers;

use Goutte\Client;
use App\Http\Controllers\MembershipController;
use App\Jobs\RegisterAthleteJob;
use App\Models\Athlete;
use App\Models\Registration;
use App\Models\Member;
use DB;
use Log;

class RegistrationController extends Controller {

    public function __construct() {}

    public function queueAllRegistrations() {
        $registrations = Registration::get()->all();

        foreach($registrations as $registration) {
            dispatch(new RegisterAthleteJob($registration));
        }

        return response()->json($registrations);
    }

    public function processRegistration(Registration $registration) {
        Log::info("processRegistration($registration->id)");

        $error = null;
        $athleteId = $this->fetchPowerOfTenAthleteId($registration->urn);

        Log::info("Got athlete ID: $athleteId");

        if ($athleteId) {
            // Fetch athlete from uka
            $membershipController = new MembershipController();
            $membershipDetails = $membershipController->checkUrn($registration->urn);

            Log::info("checkUrn: {$membershipDetails->CheckRegistrationStatus_UrnResult}");

            // Check last name and age match against registration
            if (strpos($membershipDetails->result->FirstClaimClub, 'Black Pear Joggers') !== 0) {
                $error = "Not listed in club: {$membershipDetails->result->FirstClaimClub}";
            }

            if ($membershipDetails->result->LastName !== $registration->lastName) {
                $error = "No matching last name: {$membershipDetails->result->LastName}";
            }

            if ($error) {
                $registration->notes = $error;
                $registration->save();

                return;
            }

            // Add athlete to athlete table
            $this->createAthlete(
                $athleteId,
                $registration->urn,
                $membershipDetails->result->FirstName,
                $membershipDetails->result->LastName,
                $registration->gender,
                $registration->dateOfBirth,
                $membershipDetails->result->Age,
                $membershipDetails->result->Registered,
                DB::raw('now()'),
                $membershipDetails->CheckRegistrationStatus_UrnResult,
                $membershipDetails->result->FirstClaimClub
            );

            $registration->delete();
        }
    }

    private function fetchPowerOfTenAthleteId($athleteUrn) {
        Log::info("fetchPowerOfTenProfile($athleteUrn)");

        $fetchUrl = 'https://www.thepowerof10.info/athletes/profile.aspx?ukaurn=' . $athleteUrn;
        $httpClient = new Client();
        $html = $httpClient->request('GET', $fetchUrl);

        $findProfileLink = $html->filter('a[id=cphBody_lnkRBProfile]');

        if ($findProfileLink->count()) {
            $profileUrl = $findProfileLink->link()->getUri();
            $athleteId = substr($profileUrl, strpos($profileUrl,'athleteid=')+10);
            Log::info("Found athlete ID: $athleteId");
        } else {
            return null;
        }

        return $athleteId;
    }

    private function createAthlete($id, $urn, $firstName, $lastName, $gender, $dateOfBirth, $age, $active, $membershipCheck, $membershipCheckStatus, $club) {
        $category = '';

        $record = Athlete::firstOrCreate([
            'urn' => $urn
        ],[
            'id' => $id,
            'athlete_id' => $id,
            'first_name' => $firstName,
            'last_name' => $lastName,
            'gender' => $gender,
            'dob' => $dateOfBirth,
            'age' => $age,
            'category' => $category,
            'active' => $active,
            'membership_check' => $membershipCheck,
            'membership_check_status' => $membershipCheckStatus,
            'club' => $club
        ]);
    }
}
