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
        $results = MagicMile::query()->get()->all();
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
            'predictedTimeParsed' => 'required',
            'actualTime' => 'required',
            'actualTimeParsed' => 'required'
        ]);

        $record = MagicMile::firstOrCreate([
            'athlete_id' => $request->input('athleteId') || null,
            'first_name' => $request->input('firstName'),
            'last_name' => $request->input('lastName'),
            'gender' => $request->input('gender'),
            'category' => $request->input('category'),
            'date' => $request->input('date'),
            'location' => $request->input('location'),
            'predicted_time' => $request->input('predictedTime'),
            'predicted_time_parsed' => $request->input('predictedTimeParsed'),
            'actual_time' => $request->input('actualTime'),
            'actual_time_parsed' => $request->input('actualTimeParsed'),
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

    // Fetches all results in specific format needed for Angular application
    public function getAllLegacy()
    {
        $results = DB::select("
            SELECT
                m.id AS id,
                m.athlete_id AS athleteId,
                m.first_name AS firstName,
                m.last_name AS lastName,
                m.gender AS gender,
                m.category AS category,
                m.date AS date,
                m.location AS location,
                m.predicted_time AS predictedTime,
                m.predicted_time_parsed AS predictedTimeParsed,
                m.actual_time AS actualTime,
                m.actual_time_parsed AS actualTimeParsed,
                m.created_at AS createdAt,
                m.updated_at AS updatedAt,
                p.isPersonalBest,
                MAX(awards.id) AS award
            FROM
                magicMile m
            LEFT JOIN meetings me
                ON me.date = m.date
                AND me.event = '1M'
            LEFT JOIN performances p
                ON p.athlete_id = m.athlete_id
                AND me.id = p.meetingId
                AND p.time_parsed = m.actual_time_parsed
            LEFT JOIN events ON me.event = events.alias
            LEFT JOIN standards
                ON m.gender = standards.gender
                AND standards.category = m.category
                AND standards.event_id = events.has_standard
                AND standards.time_parsed >= m.actual_time_parsed
            LEFT JOIN awards ON standards.award_id = awards.id
            GROUP BY m.id
            ORDER BY
                date DESC,
                actual_time_parsed ASC,
                last_name ASC
        ");

        return response()->json($results);
    }

    public function syncMagicMileResults()
    {
        $results = MagicMile::query()->where(function ($query) {
            $query->where('athlete_id', '!=', 0)
                ->whereNotNull('athlete_id');
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
                'athlete_id' => $result['athlete_id'],
                'meetingId' => $meeting->id,
                'manual' => 1,
            ], [
                'category' => $result['category'],
                'time_parsed' => $result['actual_time_parsed'],
                'time' => $result['actual_time'],
            ]);

            if (!$performance->wasRecentlyCreated && $performance->wasChanged()) {
                $performanceUpdated[] = $performance;
            }

            if (!$performance->wasRecentlyCreated && !$performance->wasChanged()) {
                $performanceUntouched[] = $performance;
            }

            if ($performance->wasRecentlyCreated) {
                $performanceCreated[] = $performance;
            }
        }

        return response()->json([
            'meetingsCreated' => $meetingsCreated,
            'performanceUpdated' => $performanceUpdated,
            'performanceUntouched' => $performanceUntouched,
            'performanceCreated' => $performanceCreated,
        ]);
    }
}
