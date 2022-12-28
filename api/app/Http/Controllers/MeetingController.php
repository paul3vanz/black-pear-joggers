<?php

namespace App\Http\Controllers;

use App\Models\Meeting;
use Illuminate\Http\Request;

class MeetingController extends Controller
{
    public function __construct()
    {
    }

    public function getMeetings(Request $request)
    {
        $meetings = Meeting::query();

        if ($request->input('year')) {
            $meetings = $meetings->whereYear('date', '=', $request->input('year'));
        }

        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));
        if ($searchTerm) {
            $meetings = $meetings->where('name', 'LIKE', "%$searchTerm%");
        }

        if ($request->input('fromDate')) {
            $meetings = $meetings->where('date', '>=', $request->input('fromDate'));
        }

        if ($request->input('toDate')) {
            $meetings = $meetings->where('date', '<=', $request->input('toDate'));
        }

        $meetings = $meetings->with('firstPerformance')->withCount('performances as performancesCount')->get()->all();

        return response()->json($meetings);
    }

    public function getMeetingById($id)
    {
        $meeting = Meeting::find($id)->with('performances')->withCount('performances as performancesCount')->first();
        return response()->json($meeting);
    }
}
