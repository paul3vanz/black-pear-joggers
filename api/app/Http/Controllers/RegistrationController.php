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

    /**
     * @OA\Delete(
     *   tags={"Registrations"},
     *   path="/registrations",
     *   summary="Delete registration by ID",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
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

        $athleteId = $this->fetchPowerOfTenAthleteId($registration->urn);

        Log::info("Got athlete ID: $athleteId");

        if (!$athleteId) {
            $registration->notes = 'Needs an athlete id adding by hand: '
                . 'Power of 10 can no longer be searched by URN.';
            $registration->save();
        }

        if ($athleteId) {
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

    /**
     * There is no longer any way to look an athlete up by their UKA URN.
     *
     * This used to read thepowerof10.info/athletes/profile.aspx?ukaurn=, which
     * does not resolve at all now: the request throws rather than 404s, and it
     * was taking the whole registrations run down with it. The rebuilt site is
     * keyed by GUID and its only search is behind reCAPTCHA, so there is
     * nothing to point this at.
     *
     * Returning null leaves the registration in place rather than creating an
     * athlete we cannot identify, so somebody can finish it by hand.
     */
    private function fetchPowerOfTenAthleteId($athleteUrn)
    {
        Log::info('Cannot look up a Power of 10 id by URN, the site that allowed it is gone', [
            'urn' => $athleteUrn,
        ]);

        return null;
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
