<?php

namespace App\Http\Controllers;

use GuzzleHttp\Client as GuzzleClient;
use App\Models\Athlete;
use App\Models\Membership;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use SoapClient;
use Log;
use DateTime;
use DateTimeZone;

class MembershipController extends Controller
{
    /**
     * @OA\Get(
     *   tags={"Membership"},
     *   path="/membership/{firstName}/{lastName}/{dateOfBirth}",
     *   summary="Check UKA membership by name and date of birth",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="firstName", in="path", required=true, @OA\Schema(type="string")),
     *   @OA\Parameter(name="lastName", in="path", required=true, @OA\Schema(type="string")),
     *   @OA\Parameter(name="dateOfBirth", in="path", required=true, @OA\Schema(type="string", format="date")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function checkNameDob(string $firstName, string $lastName, string $dateOfBirth)
    {
        if (!Gate::allows('members:read')) {
            abort(403);
        }

        $date = date("Y-m-d");

        return response()->json(MembershipController::fetchUrl("/race-provider/individuals?firstname=$firstName&lastname=$lastName&dob=$dateOfBirth"));
    }

    /**
     * @OA\Get(
     *   tags={"Membership"},
     *   path="/membership/{urn}",
     *   summary="Check UKA membership by URN",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="urn", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function responseCheckUrn(int $urn)
    {
        if (!Gate::allows('members:read')) {
            abort(403);
        }

        return response()->json($this->checkUrn($urn));
    }

    /**
     * @OA\Get(
     *   tags={"Membership"},
     *   path="/clubs",
     *   summary="Get all UKA clubs",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function getClubs()
    {
        if (!Gate::allows('clubs:read')) {
            abort(403);
        }
        return response()->json(MembershipController::fetchUrl('/race-provider/clubs'));
    }

    /**
     * @OA\Get(
     *   tags={"Membership"},
     *   path="/clubs/{clubId}/members",
     *   summary="Get all UKA members of a club",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function getClubMembers(int $clubId = 1606, $skipAuthCheck = false)
    {
        if (!Gate::allows('members:read') && !$skipAuthCheck) {
            abort(403);
        }

        $date = date("Y-m-d");

        return response()->json(MembershipController::fetchUrl("/race-provider/clubs/$clubId/individuals?eventDate=$date"));
    }

    public function checkUrn(int $urn)
    {
        $date = date("Y-m-d");

        return MembershipController::fetchUrl("/race-provider/individuals/$urn?eventDate=$date");
    }

    /**
     * @OA\Get(
     *   tags={"Membership"},
     *   path="/storeClubMembers",
     *   summary="Fetch club members from UKA and store them in the membership table",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function storeClubMembers()
    {
        Log::info('storeClubMembers executed');

        $athletes = MembershipController::getClubMembers(1606, true)->getData()->Athletes;

        if (count($athletes)) {
            Membership::truncate();
        }

        $members = collect($athletes)->each(function ($value, $key) {
            Membership::updateOrCreate([
                'urn' => $value->Urn
            ], [
                'firstName' => $value->Firstname,
                'lastName' => $value->Lastname,
                'dob' => $value->Dob,
                'gender' => $value->Gender,
                'foreignFlag' => $value->ForeignFlag,
                'competitiveRegStatus' => $value->CompetitiveRegStatus,
                'firstClaimClubId' => $value->FirstClaimClubId,
                'firstClaimClubName' => $value->FirstClaimClubName,
                'firstClaimOtherId' => $value->FirstClaimOtherId,
                'firstClaimOtherName' => $value->FirstClaimOtherName,
                'higherClaimClubId' => $value->HigherClaimClubId,
                'higherClaimClubName' => $value->HigherClaimClubName,
                'secondClaimClubId' => $value->SecondClaimClubId,
                'secondClaimClubName' => $value->SecondClaimClubName,
            ]);
        });

        return response()->json([
            'count' => count($members),
        ]);
    }

    private function fetchUrl(string $url)
    {
        $url = env(env('UKA_ENVIRONMENT') . '_UKA_TRINITY_API_URL') . $url;

        $client = new GuzzleClient();
        $res = $client->get($url, [
            'headers' => MembershipController::getHeaders(),
            'cert' => MembershipController::getCertificate(),
        ]);

        if ($res->getStatusCode() === 200) {
            $response = json_decode($res->getBody());
            return $response;
        } else {
            return 'api error';
        }
    }

    private function getHeaders()
    {
        $timestamp = gmdate("Y-m-d\TH:i:s");

        return [
            'X-TRAPI-CALLKEY' => env(env('UKA_ENVIRONMENT') . '_UKA_HEADER_X_TRAPI_CALLKEY', null),
            'X-TRAPI-CALLSECRET' => env(env('UKA_ENVIRONMENT') . '_UKA_HEADER_X_TRAPI_CALLSECRET', null),
            'X-TRAPI-CALLDATETIME' => $timestamp,
        ];
    }

    private function getCertificate()
    {
        return getcwd() . DIRECTORY_SEPARATOR . env(env('UKA_ENVIRONMENT') . '_UKA_PEM_FILENAME');
    }

    /**
     * @OA\Get(
     *   tags={"Membership"},
     *   path="/members/leaguemembers",
     *   summary="Get all registered members",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getRegisteredMembers(Request $request)
    {
        $members = Membership::query()->where('competitiveRegStatus', 'Registered')->get();

        $members = $members->all();

        return response()->json($members);
    }
}
