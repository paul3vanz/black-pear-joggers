<?php

namespace App\Http\Controllers;

use Goutte\Client;
use App\Http\Controllers\MembershipController;
use App\Jobs\RegisterAthleteJob;
use App\Models\Athlete;
use App\Models\Registration;
use DB;
use Log;

class RegistrationController extends Controller
{

    protected $membershipController;

    public function __construct(
        MembershipController $membershipController
    ) {
        $this->membershipController = $membershipController;
    }

    /**
     * @OA\Get(
     *   tags={"Registrations"},
     *   path="/registrations",
     *   summary="Get all registrations",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getAll()
    {
        $standards = Registration::get()->all();

        return response()->json($standards);
    }

    public function delete(string $id)
    {
        $result = Registration::destroy($id);
        return response()->json($id);
    }

    public function queueAllRegistrations()
    {
        $registrations = Registration::get()->all();

        foreach ($registrations as $registration) {
            dispatch(new RegisterAthleteJob($this->membershipController, $registration));
        }

        return response()->json($registrations);
    }

    public function processRegistration(Registration $registration)
    {
        Log::info("processRegistration($registration->id)");

        $error = null;
        $athleteId = $this->fetchPowerOfTenAthleteId($registration->urn);

        Log::info("Got athlete ID: $athleteId");

        if ($athleteId) {
            // Fetch athlete from uka
            $membershipDetails = $this->membershipController->checkUrn($registration->urn);

            Log::info("checkUrn: {$membershipDetails->Urn}");

            // Check last name and age match against registration
            if (strpos($membershipDetails->FirstClaimClubName, 'Black Pear Joggers') !== 0) {
                $error = "Not listed in club: {$membershipDetails->FirstClaimClubName}";
            }

            if (trim($membershipDetails->Lastname) !== trim($registration->lastName)) {
                $error = "No matching last name: '{$membershipDetails->Lastname}' ";
            }

            if ($error) {
                $registration->notes = $error;
                $registration->save();

                return;
            }

            // Add athlete to athlete table
            $athlete = $this->createAthlete(
                [
                    'urn' => $membershipDetails->Urn,
                    'id' => $athleteId,
                    'athlete_id' => $athleteId,
                    'first_name' => $membershipDetails->Firstname,
                    'last_name' => $membershipDetails->Lastname,
                    'gender' => $registration->gender,
                    'dob' => $registration->dateOfBirth,
                ]
            );

            if ($athlete) {
                $registration->forceDelete();
            }
        }
    }

    private function fetchPowerOfTenAthleteId($athleteUrn)
    {
        Log::info("fetchPowerOfTenProfile($athleteUrn)");

        $fetchUrl = 'https://www.thepowerof10.info/athletes/profile.aspx?ukaurn=' . $athleteUrn;
        $httpClient = new Client();
        $html = $httpClient->request('GET', $fetchUrl);

        $findProfileLink = $html->filter('a[id=cphBody_lnkEditAthlete]');

        if ($findProfileLink->count()) {
            $profileUrl = $findProfileLink->link()->getUri();
            preg_match("/athleteid=(\d+)&/i", $profileUrl, $matches);
            $athleteId = $matches[1];
            Log::info("Found athlete ID: $athleteId");
        } else {
            return null;
        }

        return $athleteId;
    }

    public function createRegistrationsFromMemberships()
    {
        $members = collect($this->membershipController->getClubMembers(1606, true)->getData()->Athletes);

        $existingAthletes = Athlete::query()->whereNotNull('urn')->get()->map(function ($value, $key) {
            return $value->urn;
        })->toArray();

        $newMembers = $members->filter(function ($value, $key) use ($existingAthletes) {
            return !in_array($value->Urn, $existingAthletes);
        })->toArray();

        foreach ($newMembers as $newMember) {
            Registration::withTrashed()->firstOrCreate(
                [
                    'urn' => $newMember->Urn,
                ],
                [
                    'firstName' => $newMember->Firstname,
                    'lastName' => $newMember->Lastname,
                    'gender' => $newMember->Gender === 'MALE' ? 'M' : 'W',
                    'dateOfBirth' => preg_replace('/(\d*)\/(\d*)\/(\d*)/', '$3-$2-$1', $newMember->Dob),
                    'notes' => 'Added from membership list',
                ]
            )->restore();
        }

        Log::info(count($newMembers) . ' new members added to registration');

        return response()->json([
            'count' => count($newMembers),
            'members' => $newMembers,
        ]);
    }

    private function createAthlete($athlete)
    {
        $record = Athlete::firstOrCreate([
            'urn' => $athlete['urn'],
        ], $athlete);

        return $record;
    }
}
