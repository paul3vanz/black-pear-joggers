<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Contracts\Auth\Factory as Auth;
use Illuminate\Support\Facades\DB;

use App\Models\Athlete;

class AthleteController extends Controller
{
  public function __construct(Auth $auth)
  {
    $this->auth = $auth;
  }

  public function getAthletes(Request $request)
  {
    $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));

    if ($searchTerm) {
      $athletes = Athlete::where(function ($query) use ($searchTerm) {
        $query->where('first_name', 'LIKE', "%$searchTerm%")
          ->orWhere('last_name', 'LIKE', "%$searchTerm%")
          ->orWhere(DB::raw("CONCAT(first_name, ' ', last_name)"), 'LIKE', "%$searchTerm%");
      });

      $athletes = $athletes->where('active', '=', 1)->with('latestRanking');

      $athletes = $athletes->get();
    } else {
      $athletes = Athlete::query()->get()->all();
    }

    return response()->json($athletes);
  }

  public function getAthlete($id)
  {
    $athlete = Athlete::query()
      ->with('latestPerformance')
      ->with('firstPerformance')
      ->with('latestRanking')
      ->with('membership')
      ->find($id);
    return response()->json($athlete);
  }

  public function getAthletePerformances($id)
  {
    $athlete = Athlete::with('performances')->find($id);
    return response()->json($athlete);
  }

  public function getAthleteStandards($id)
  {
    $athlete = Athlete::with('standards')->find($id);
    return response()->json($athlete);
  }

  public function getMembershipTotals()
  {
    $results = DB::select("
            SELECT 'all' AS 'type', COUNT(1) AS 'total', MAX(updated_at) AS 'updated_at' FROM members WHERE paid_status = 'Paid'
            UNION
            SELECT 'affiliated' AS 'type', COUNT(1) AS 'total', MAX(updated_at) AS 'updated_at' FROM members WHERE paid_status = 'Paid' AND membership_type NOT LIKE '%basic%'
            UNION
            SELECT 'basic' AS 'type', COUNT(1) AS 'total', MAX(updated_at) AS 'updated_at' FROM members WHERE paid_status = 'Paid' AND membership_type LIKE '%basic%'
        ");

    return response()->json($results);
  }
}
