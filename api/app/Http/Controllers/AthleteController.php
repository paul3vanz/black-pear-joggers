<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Athlete;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\ItemNotFoundException;
use Illuminate\Support\Facades\Gate;

class AthleteController extends Controller
{
    public function getAthletes(Request $request)
    {
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

        if (Gate::allows('athletes:admin')) {
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

    public function athleteIdvCheck(Request $request)
    {
        $this->validate($request, [
            'urn' => 'required|integer',
            'dob' => 'required|date',
        ]);

        $athlete = Athlete::where('urn', $request->urn)->where('dob', $request->dob)->get()->first();

        if (!$athlete) {
            return response('', 404);
        }

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
        if (!Gate::allows('athletes:admin')) {
            abort(403);
        }

        $this->validateRequest($request);

        Athlete::create([
            'id' => $request->input('id'),
            'urn' => $request->input('urn'),
            'athlete_id' => $request->input('athleteId'),
            'first_name' => $request->input('firstName'),
            'last_name' => $request->input('lastName'),
            'gender' => $request->input('gender'),
            'dob' => $request->input('dob')
        ]);
    }

    public function updateAthlete($id, Request $request)
    {
        if (!Gate::allows('athletes:admin')) {
            abort(403);
        }

        $this->validateRequest($request);

        Athlete::find($id)->update([
            'urn' => $request->input('urn'),
            'athlete_id' => $request->input('athleteId'),
            'first_name' => $request->input('firstName'),
            'last_name' => $request->input('lastName'),
            'gender' => $request->input('gender'),
            'dob' => $request->input('dob')
        ]);
    }

    public function deleteAthlete($id)
    {
        if (!Gate::allows('athletes:admin')) {
            abort(403);
        }

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
