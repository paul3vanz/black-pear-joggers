<?php

namespace App\Http\Controllers;

use App\Models\Athlete;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Input;
use Illuminate\Http\Request;
use SoapClient;
use Log;

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
      return response()->json($this->soapCall('CheckRegistrationStatus_Fn_Ln_Dob', array(
        'firstName' => $firstName,
        'lastName' => $lastName,
        'dateOfBirth' => $dateOfBirth
      )));
    }

    public function responseCheckUrn(int $urn) {
      return response()->json($this->checkUrn($urn));
    }

    public function checkUrn(int $urn) {
      return $this->soapCall('CheckRegistrationStatus_Urn', array(
        'urn' => $urn
      ));
    }

    private function soapCall($function, $params) {
      // Live
      $wsdl = 'https://myathletics.uka.org.uk/LicenceCheckService/LicenceCheck.svc?singleWsdl';
      $key = env('UKA_API_KEY', null);

      $opts = array(
        'ssl' => array(
          'verify_peer' => false,
          'verify_peer_name' => false,
          'allow_self_signed' => true
          )
        );

        $context = stream_context_create($opts);

        $defaultParams = array(
          'webUserKey' => $key
        );

        try {
          if (MembershipController::$soapClient === null) {
            MembershipController::$soapClient = new \SoapClient($wsdl, array(
              'stream_context' => $context, 'trace' => true)
            );
          }

          $response = MembershipController::$soapClient->__soapCall($function, array(array_merge($defaultParams, $params)));

          return $response;
        }

        catch ( \Exception $e) {
          $error = 'Caught Exception in client'. $e->getMessage();

          return $error;
        }

    }

}
