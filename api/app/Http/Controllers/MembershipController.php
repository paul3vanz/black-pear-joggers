<?php

namespace App\Http\Controllers;

use GuzzleHttp\Client as GuzzleClient;
use App\Models\Athlete;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Input;
use Illuminate\Http\Request;
use SoapClient;
use Log;
use DateTime;
use DateTimeZone;

class MembershipController extends Controller {

  public function __construct() {}

    private static $soapClient;

    public function updateMembershipStatusAll() {

    }

    public function updateMembershipStatus() {
      $athletesWithUrns = Athlete::query()
        ->whereNotNull('urn')
        ->where(function($query) {
          $query
            ->where('membership_check', '<=', time() - (24*60*60))
            ->orWhereNull('membership_check');
        })
        ->limit(100)
        ->get()
        ->makeVisible([ 'urn', 'age' ]);

      $affected = array();

      foreach ($athletesWithUrns as $athlete) {
        $membershipCheck = $this->soapCall('CheckRegistrationStatus_Urn', array(
          'urn' => $athlete->urn
        ));

        if (!$membershipCheck) continue;

        $athlete->membership_check_status = $membershipCheck->CheckRegistrationStatus_UrnResult;
          if ($membershipCheck->CheckRegistrationStatus_UrnResult === 'MatchFound') {
            $athlete->age = $membershipCheck->result->Age;
            $athlete->active = $membershipCheck->result->Registered;
            $athlete->club = $membershipCheck->result->FirstClaimClub;
          } else {
            $athlete->age = null;
            $athlete->active = null;
            $athlete->club = null;
          }

          $athlete->membership_check = DB::raw('now()');

          $athlete->save();

          $affected[] = $athlete;
      }

      return response()->json($affected);
    }

    public function checkNameDob(string $firstName, string $lastName, string $dateOfBirth) {
      $date = date("Y-m-d");

      return response()->json(MembershipController::fetchUrl("/race-provider/individuals?firstname=$firstName&lastname=$lastName&dob=$dateOfBirth"));
    }

    public function responseCheckUrn(int $urn) {
      return response()->json($this->checkUrn($urn));
    }

    public function getClubs() {
      return response()->json(MembershipController::fetchUrl('/race-provider/clubs'));
    }

    public function getClubMembers(int $clubId = 1606) {
      $date = date("Y-m-d");

      return response()->json(MembershipController::fetchUrl("/race-provider/clubs/$clubId/individuals?eventDate=$date"));
    }

    public function checkUrn(int $urn) {
      $date = date("Y-m-d");

      return MembershipController::fetchUrl("/race-provider/individuals/$urn?eventDate=$date");
    }

    private function fetchUrl(string $url) {
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

    private function getHeaders() {
      $timestamp = gmdate("Y-m-d\TH:i:s");

      return [
        'X-TRAPI-CALLKEY' => env(env('UKA_ENVIRONMENT') . '_UKA_HEADER_X_TRAPI_CALLKEY', null),
        'X-TRAPI-CALLSECRET' => env(env('UKA_ENVIRONMENT') . '_UKA_HEADER_X_TRAPI_CALLSECRET', null),
        'X-TRAPI-CALLDATETIME' => $timestamp,
      ];
    }

    private function getCertificate() {
      return getcwd() . '\\' . env(env('UKA_ENVIRONMENT') . '_UKA_PEM_FILENAME');
    }
}
