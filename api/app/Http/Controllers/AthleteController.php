<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Input;
use Illuminate\Support\Facades\DB;
use App\Models\Athlete;
use Illuminate\Support\Facades\Auth;

class AthleteController extends Controller
{
    public function getAthletes(Request $request)
    {
        $user = Auth::check();

        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));

        if ($searchTerm) {
            $athletes = Athlete::where(function ($query) use ($searchTerm) {
                $query->where('first_name', 'LIKE', "%$searchTerm%")
                    ->orWhere('last_name', 'LIKE', "%$searchTerm%")
                    ->orWhere(DB::raw("CONCAT(first_name, ' ', last_name)"), 'LIKE', "%$searchTerm%");
            });

            $athletes = $athletes->has('activeMembership')->with('latestRanking');

            $athletes = $athletes->get();
        } else {
            $athletes = Athlete::query()->has('activeMembership')->get();
        }

        if ($user) {
            $athletes->makeVisible(['urn', 'dob', 'age']);
        }

        $athletes = $athletes->all();

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

    private function validateRequest(Request $request)
    {
        $this->validate($request, [
            'id' => 'required|integer',
            'urn' => 'required|integer',
            'athleteId' => 'required|integer',
            'athleteIdAlt' => 'integer|nullable',
            'firstName' => 'required|string',
            'lastName' => 'required|string',
            'gender' => 'required|in:M,W',
            'dob' => 'required|date',
        ]);
    }

    public function createAthlete(Request $request)
    {
        $this->validateRequest($request);

        Athlete::create([
            'id' => Input::get('id'),
            'urn' => Input::get('urn'),
            'athlete_id' => Input::get('athleteId'),
            'first_name' => Input::get('firstName'),
            'last_name' => Input::get('lastName'),
            'gender' => Input::get('gender'),
            'dob' => Input::get('dob')
        ]);
    }

    public function updateAthlete($id, $request)
    {
        $this->validateRequest($request);

        Athlete::find($id)->update([
            'urn' => Input::get('urn'),
            'athlete_id' => Input::get('athleteId'),
            'first_name' => Input::get('firstName'),
            'last_name' => Input::get('lastName'),
            // 'gender' => Input::get('gender')
            // 'dob' => Input::get('dob')
        ]);
    }

    public function deleteAthlete($id)
    {
        $athlete = Athlete::find($id);

        $hasDeleted = $athlete->delete();

        return $hasDeleted ? response()->noContent() : response('Failed', 500);
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
