<?php

namespace App\Http\Controllers;

use App\Models\MagicMile;
use App\Models\Meeting;
use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Str;

class MagicMileController extends Controller
{

    public function __construct()
    {
    }

    public function getAll()
    {
        $query = MagicMile::query()
        ->select('magicmile.*', 'performances.isPersonalBest', DB::raw('MAX(awards.id) AS award'))
        ->leftJoin('meetings', function ($join) {
            $join->on('meetings.date', '=', 'magicmile.date')
                 ->where('meetings.event', '=', '1M');
        })
        ->leftJoin('performances', function ($join) {
            $join->on('performances.athlete_id', '=', 'magicmile.athleteId')
                 ->on('meetings.id', '=', 'performances.meetingId');
        })
        ->leftJoin('events', function ($join) {
            $join->on('meetings.event', '=', 'events.alias');
        })
        ->leftJoin('standards', function ($join) {
            $join->on('magicmile.gender', '=', 'standards.gender')
                ->on('standards.category', '=', 'magicmile.category')
                ->on('standards.event_id', '=', 'events.has_standard')
                ->on('standards.time_parsed', '>=', 'magicmile.actualTime');
        })
        ->leftJoin('awards', function ($join) {
            $join->on('standards.award_id', '=', 'awards.id');
        })
        ->groupBy('magicmile.id')
        ->orderBy('magicmile.date', 'desc')
        ->orderBy('magicmile.actualTime')
        ->orderBy('magicmile.lastName');

        $results = $query->get()->all();

        return response()->json($results);
    }

    public function store(Request $request)
    {
        if (!Gate::allows('magicMile:admin')) {
            abort(403);
        }

        $validatedData = $this->validate($request, [
            'firstName' => 'required',
            'lastName' => 'required',
            'gender' => 'required',
            'category' => 'required',
            'date' => 'required',
            'location' => 'required',
            'predictedTime' => 'required',
            'actualTime' => 'required',
        ]);

        $record = MagicMile::firstOrCreate([
            'athleteId' => $request->input('athleteId') || null,
            'firstName' => $request->input('firstName'),
            'lastName' => $request->input('lastName'),
            'gender' => $request->input('gender'),
            'category' => $request->input('category'),
            'date' => $request->input('date'),
            'location' => $request->input('location'),
            'predictedTime' => $request->input('predictedTime'),
            'actualTime' => $request->input('actualTime'),
        ]);

        return response()->json($record);
    }

    public function create()
    {
        return view('magicmile.create');
    }

    public function delete(string $id)
    {
        if (!Gate::allows('magicMile:admin')) {
            abort(403);
        }

        $result = MagicMile::destroy($id);
        return response()->json($id);
    }

    public function syncMagicMileResults()
    {
        $results = MagicMile::query()->where(function ($query) {
            $query
                ->where('athleteId', '>', 1)
                ->whereNotNull('athleteId');
        })->get()->all();

        $meetingsCreated = [];
        $performanceUpdated = [];
        $performanceUntouched = [];
        $performanceCreated = [];

        foreach ($results as $result) {
            $meeting = Meeting::firstOrCreate(
                [
                    'event' => '1M',
                    'name' => $result['location'],
                    'date' => $result['date'],
                ],
                [
                    'id' => Str::uuid(),
                ]
            );

            if ($meeting->wasRecentlyCreated) {
                $meetingsCreated[] = $meeting;
            }

            $performance = Performance::updateOrCreate([
                'athlete_id' => $result['athleteId'],
                'meetingId' => $meeting->id,
                'manual' => 1,
            ], [
                'category' => $result['category'],
                'time_parsed' => $result['actualTime'],
            ]);

            if ($performance->wasRecentlyCreated) {
                $performanceCreated[] = $performance;
            }

            if (!$performance->wasRecentlyCreated && $performance->wasChanged()) {
                $performanceUpdated[] = $performance;
            }

            if (!$performance->wasRecentlyCreated && !$performance->wasChanged()) {
                $performanceUntouched[] = $performance;
            }
        }

        return response()->json([
            'meetingsCreated' => $meetingsCreated,
            'performanceCreated' => $performanceCreated,
            'performanceUpdated' => $performanceUpdated,
            'performanceUntouched' => $performanceUntouched,
        ]);
    }
}
