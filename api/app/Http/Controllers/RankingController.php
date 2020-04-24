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
