<?php

namespace App\Http\Controllers;

use App\Models\Meeting;
use Illuminate\Http\Request;

class MeetingController extends Controller
{
    public function __construct()
    {
    }

    /**
     * @OA\Get(
     *   tags={"Meetings"},
     *   path="/meetings",
     *   summary="Get all meetings",
     *   @OA\Parameter(name="year", in="query", required=false, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="search", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Parameter(name="event", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Parameter(name="fromDate", in="query", required=false, @OA\Schema(type="string", format="date")),
     *   @OA\Parameter(name="toDate", in="query", required=false, @OA\Schema(type="string", format="date")),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getMeetings(Request $request)
    {
        $meetings = Meeting::query()->orderBy('date', 'desc');

        if ($request->input('year')) {
            $meetings = $meetings->whereYear('date', '=', $request->input('year'));
        }

        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));
        if ($searchTerm) {
            $meetings = $meetings->where('name', 'LIKE', "%$searchTerm%");
        }

        if ($request->input('event')) {
            $meetings = $meetings->where('event', '=', $request->input('event'));
        }

        if ($request->input('fromDate')) {
            $meetings = $meetings->where('date', '>=', $request->input('fromDate'));
        }

        if ($request->input('toDate')) {
            $meetings = $meetings->where('date', '<=', $request->input('toDate'));
        }

        $meetings = $meetings->with('athlete')->withCount('performances as performancesCount')->paginate(100);

        return response()->json($meetings);
    }

    /**
     * @OA\Get(
     *   tags={"Meetings"},
     *   path="/meetings/{id}",
     *   summary="Get a meeting by ID",
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string")),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getMeetingById($id)
    {
        $meeting = Meeting::find($id)->with('athlete')->withCount('performances as performancesCount')->first();
        return response()->json($meeting);
    }
}
