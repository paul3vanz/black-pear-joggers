<?php

namespace App\Http\Controllers;

use App\Models\Ranking;
use Illuminate\Support\Facades\Artisan;

class RankingController extends Controller
{
  /**
   * Create a new controller instance.
   *
   * @return void
   */
  public function __construct()
  {
  }

  /**
   * @OA\Get(
   *   tags={"Rankings"},
   *   path="/rankings/{athleteId}",
   *   summary="Get an athlete's runBritain rankings history",
   *   @OA\Parameter(name="athleteId", in="path", required=true, @OA\Schema(type="integer")),
   *   @OA\Response(response=200, description="OK"),
   * )
   * @OA\Get(
   *   tags={"Rankings"},
   *   path="/rankings/{athleteId}/{year}",
   *   summary="Get an athlete's runBritain rankings history for a year",
   *   @OA\Parameter(name="athleteId", in="path", required=true, @OA\Schema(type="integer")),
   *   @OA\Parameter(name="year", in="path", required=true, @OA\Schema(type="integer")),
   *   @OA\Response(response=200, description="OK"),
   * )
   */
  public function getRankingsByAthlete($athleteId, $year = null)
  {
    $rankings = Ranking::where('athlete_id', $athleteId)
      ->when($year, function ($query, $year) {
        return $query->whereYear('date', $year);
      })
      ->orderBy('date')
      ->get()
      ->all();

    return response()->json($rankings);
  }
}
