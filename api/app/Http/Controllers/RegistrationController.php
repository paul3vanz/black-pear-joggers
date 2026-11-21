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
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getAll()
    {
        $standards = Registration::get()->all();

        return response()->json($standards);
    }

    /**
     * @OA\Delete(
     *   tags={"Registrations"},
     *   path="/registrations",
     *   summary="Delete registration by ID",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function delete(string $id)
    {
        $result = Registration::destroy($id);
        return response()->json($id);
    }

    /**
     * @OA\Get(
     *   tags={"Registrations"},
     *   path="/registrations/queue",
     *   summary="Queue processing of all registrations",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     * )
     */
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

        $membershipDetails = $this->membershipController->checkUrn($registration->urn);

        // Fetch athlete from uka

        Log::info("checkUrn: {$membershipDetails->Urn}");

        // Check last name and age match against registration
        if (strpos($membershipDetails->FirstClaimClubName, 'Black Pear Joggers') !== 0) {
            $registration->notes = "Not listed in club: {$membershipDetails->FirstClaimClubName}";
            $registration->delete();

            return;
        }

        if ($membershipDetails->CompetitiveRegStatus !== "Registered") {
            $registration->notes = "Not registered, status: {$membershipDetails->CompetitiveRegStatus}";
            $registration->delete();

            return;
        }

        if (trim($membershipDetails->Lastname) !== trim($registration->lastName)) {
            $registration->notes = "No matching last name: '{$membershipDetails->Lastname}' ";
            $registration->save();

            return;
        }

        $this->createAthleteFromRegistration($registration, $membershipDetails->Firstname, $membershipDetails->Lastname);
    }

    /**
     * Turn a verified registration into an athlete, whether or not Power of 10 knows them.
     *
     * Power of 10 can no longer be searched by URN, so a new athlete starts with
     * no athlete_id (the old Power of 10 integer id) and no po10_guid. Those are
     * only needed to scrape results and to link to their profile, and can be
     * filled in later. `athletes.id` is auto-increment and is what everything
     * else (club members, performances, rankings) joins on. What the app needs
     * to link a membership is the urn and date of birth, which we already hold.
     */
    public function createAthleteFromRegistration(Registration $registration, string $firstName, string $lastName): Athlete
    {
        $athlete = $this->createAthlete([
            'urn' => $registration->urn,
            'first_name' => $firstName,
            'last_name' => $lastName,
            'gender' => $registration->gender,
            'dob' => $registration->dateOfBirth,
        ]);

        Log::info('Created athlete from registration', ['athleteId' => $athlete->id, 'urn' => $registration->urn]);

        $registration->forceDelete();

        return $athlete;
    }

    /**
     * @OA\Get(
     *   tags={"Registrations"},
     *   path="/registrations/createregistrationsfrommemberships",
     *   summary="Create registrations for club members not already tracked as athletes",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     * )
     */
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
