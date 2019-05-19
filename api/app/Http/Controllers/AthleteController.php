<?php

namespace App\Http\Controllers;

use App\Models\Athlete;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class AthleteController extends Controller {

    public function __construct() {}

    public function getAthletes(Request $request) {
        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));
        if ($searchTerm) {
            $athletes = Athlete::where(function ($query) use ($searchTerm) {
                $query->where('first_name', 'LIKE', "%$searchTerm%")
                ->orWhere('last_name', 'LIKE', "%$searchTerm%")
                ->orWhere(DB::raw("CONCAT(first_name, ' ', last_name)"), 'LIKE', "%$searchTerm%");
            });

            // if ($request->input('active')) {
                $athletes = $athletes->where('active', '=', 1);
            // }

            $athletes = $athletes->get();
        } else {
            $athletes = Athlete::query()->get()->all();
        }

        return response()->json($athletes);
    }

    public function getAthlete($id) {
        $athlete = Athlete::query()
            ->with('latestPerformance')
            ->with('firstPerformance')
            ->find($id);
        return response()->json($athlete);
    }

    public function getAthletePerformances($id) {
        $athlete = Athlete::with('performances')->find($id);
        return response()->json($athlete);
    }

    public function getAthleteStandards($id) {
        $athlete = Athlete::with('standards')->find($id);
        return response()->json($athlete);
    }

    public function getMembershipTotals() {
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
