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
    /**
     * @OA\Get(
     *   tags={"Athletes"},
     *   path="/athletes",
     *   summary="Get all athletes",
     *   @OA\Parameter(name="search", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Parameter(name="includeAllMembers", in="query", required=false, @OA\Schema(type="boolean")),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getAthletes(Request $request)
    {
        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));

        if ($searchTerm) {
            $athletes = Athlete::where(function ($query) use ($searchTerm) {
                $query->where('first_name', 'LIKE', "%$searchTerm%")
                    ->orWhere('last_name', 'LIKE', "%$searchTerm%")
                    ->orWhere(DB::raw("CONCAT(first_name, ' ', last_name)"), 'LIKE', "%$searchTerm%");
            });

            $athletes = $athletes->with('latestRanking');

            $athletes = $athletes
                ->get()
                ->filter(function ($item) use ($request) {
                    return $request->input('includeAllMembers')
                        ? true
                        : $item->affiliated;
                })
                ->values();
        } else {
            $athletes = Athlete::query()
                ->get()
                ->filter(function ($item) use ($request) {
                    return $request->input('includeAllMembers')
                        ? true
                        : $item->affiliated;
                })
                ->values();
        }

        if (Gate::allows('athletes:admin')) {
            $athletes->makeVisible(['urn', 'dob', 'age', 'payments', 'membership']);
        }

        $athletes = $athletes->all();

        return response()->json($athletes);
    }

    /**
     * @OA\Get(
     *   tags={"Athletes"},
     *   path="/athlete/{id}",
     *   summary="Get an athlete by ID",
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
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

    /**
     * @OA\Get(
     *   tags={"Athletes"},
     *   path="/athleteIdvCheck",
     *   summary="Check an athlete's identity by URN and date of birth",
     *   @OA\Parameter(name="urn", in="query", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="dob", in="query", required=true, @OA\Schema(type="string", format="date")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=404, description="Not found"),
     * )
     */
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

    /**
     * @OA\Post(
     *   tags={"Athletes"},
     *   path="/athlete",
     *   summary="Create an athlete",
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"id","urn","athleteId","firstName","lastName","gender","dob"},
     *       @OA\Property(property="id", type="integer"),
     *       @OA\Property(property="urn", type="integer"),
     *       @OA\Property(property="athleteId", type="integer"),
     *       @OA\Property(property="firstName", type="string"),
     *       @OA\Property(property="lastName", type="string"),
     *       @OA\Property(property="gender", type="string", enum={"M", "W"}),
     *       @OA\Property(property="dob", type="string", format="date"),
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
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

    /**
     * @OA\Patch(
     *   tags={"Athletes"},
     *   path="/athlete/{id}",
     *   summary="Update an athlete",
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"id","urn","athleteId","firstName","lastName","gender","dob"},
     *       @OA\Property(property="id", type="integer"),
     *       @OA\Property(property="urn", type="integer"),
     *       @OA\Property(property="athleteId", type="integer"),
     *       @OA\Property(property="firstName", type="string"),
     *       @OA\Property(property="lastName", type="string"),
     *       @OA\Property(property="gender", type="string", enum={"M", "W"}),
     *       @OA\Property(property="dob", type="string", format="date"),
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
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

    /**
     * @OA\Delete(
     *   tags={"Athletes"},
     *   path="/athlete/{id}",
     *   summary="Delete an athlete",
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=204, description="No content"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
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

    /**
     * @OA\Get(
     *   tags={"Athletes"},
     *   path="/members/totals",
     *   summary="Get total counts of paid members, by membership type",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
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
