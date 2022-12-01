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
    public function checkNameDob(string $firstName, string $lastName, string $dateOfBirth)
    {
        if (!Gate::allows('members:read')) {
            abort(403);
        }

        $date = date("Y-m-d");

        return response()->json(MembershipController::fetchUrl("/race-provider/individuals?firstname=$firstName&lastname=$lastName&dob=$dateOfBirth"));
    }

    public function responseCheckUrn(int $urn)
    {
        if (!Gate::allows('members:read')) {
            abort(403);
        }

        return response()->json($this->checkUrn($urn));
    }

    public function getClubs()
    {
        if (!Gate::allows('clubs:read')) {
            abort(403);
        }
        return response()->json(MembershipController::fetchUrl('/race-provider/clubs'));
    }

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

    public function storeClubMembers()
    {
        $athletes = MembershipController::getClubMembers(1606, true)->getData()->Athletes;

        if (count($athletes)) {
            Membership::truncate();
        }

        $members = collect($athletes)->each(function ($value, $key) {
            Membership::firstOrCreate([
                'urn' => $value->Urn,
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

    public function getRegisteredMembers(Request $request)
    {
        $members = Membership::query()->where('competitiveRegStatus', 'Registered')->get();

        $members = $members->all();

        return response()->json($members);
    }
}
