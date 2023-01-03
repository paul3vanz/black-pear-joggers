<?php

namespace App\Http\Controllers;

use App\Models\Performance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class PerformanceController extends Controller
{
    public $allowedFilters = [
        'athleteId',
        'fromDate',
        'isPersonalBest',
        'limit',
        'meetingId',
        'onlyAwards',
        'search',
        'sort',
        'toDate',
    ];

    public function __construct()
    {
    }

    public function getPerformances(Request $request)
    {
        $filters = array_filter($request->all(), function ($item) {
            return in_array($item, $this->allowedFilters);
        }, ARRAY_FILTER_USE_KEY);

        ksort($filters);

        $cacheKey = 'performances-v2-' . json_encode($filters);

        $performances = Cache::remember($cacheKey, 5, function () use ($request) {

            $performances = DB::table('performances')
                ->join('athletes', 'performances.athlete_id', '=', 'athletes.id')
                ->leftJoin('events', 'performances.event', '=', 'events.alias')
                ->leftJoin('standards', function ($join) {
                    $join->on('athletes.gender', '=', 'standards.gender')
                        ->on('standards.category', '=', 'performances.category')
                        ->on('standards.event_id', '=', 'events.has_standard')
                        ->on('standards.time_parsed', '>=', 'performances.time_parsed');
                })
                ->leftJoin('awards', 'standards.award_id', '=', 'awards.id')
                ->join('memberships', function ($join) {
                    $join->on('athletes.urn', '=', 'memberships.urn')
                        ->where('memberships.competitiveRegStatus', '=', 'Registered');
                })
                ->join('meetings', 'performances.meetingId', '=', 'meetings.id')
                ->groupBy('performances.id')
                ->select(
                    DB::raw(
                        'MAX(awards.id) AS award'
                    ),
                    'athletes.id AS athleteId',
                    'athletes.first_name AS firstName',
                    'athletes.last_name AS lastName',
                    'athletes.gender',
                    'meetings.date',
                    'meetings.event',
                    'meetings.ukaMeetingId',
                    'meetings.name AS meetingName',
                    'memberships.competitiveRegStatus AS membershipStatus',
                    'performances.id',
                    'performances.category',
                    'performances.time',
                    'performances.time_parsed AS timeParsed',
                    'performances.meetingId',
                    'performances.isPersonalBest'
                );

            $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));
            if ($searchTerm) {
                $performances = $performances->where('performances.race', 'LIKE', "%$searchTerm%");
            }

            if ($request->input('athleteId')) {
                $performances = $performances->where('performances.athlete_id', '=', $request->input('athleteId'));
            }

            if ($request->input('meetingId')) {
                $performances = $performances->where('performances.meetingId', '=', $request->input('meetingId'));
            }

            if ($request->input('isPersonalBest')) {
                $performances = $performances->where('performances.isPersonalBest', true);
            }

            if ($request->input('fromDate')) {
                $performances = $performances->where('performances.date', '>=', $request->input('fromDate'));
            }

            if ($request->input('toDate')) {
                $performances = $performances->where('performances.date', '<=', $request->input('toDate'));
            }

            if ($request->input('onlyAwards')) {
                $performances = $performances->havingRaw('MAX(awards.id) IS NOT NULL');
            }

            if ($request->input('sort') == 'athlete') {
                $performances = $performances->orderBy('athletes.last_name', 'desc')
                    ->orderBy('athletes.first_name', 'desc')
                    ->orderBy('performances.date', 'desc')
                    ->orderBy('performances.time_parsed', 'asc');
            } else {
                $performances = $performances->orderBy('performances.date', 'desc')->orderBy('performances.time_parsed', 'asc');
            }

            $paginate = $request->input('limit') ? $request->input('limit') : 500;

            return $performances->paginate($paginate);
        });

        return response()->json($performances);
    }

    public function getPerformance($id)
    {
        $performance = Performance::query()->find($id)->with('meeting')->with('meeting');
        return response()->json($performance);
    }

    public function queryRecord(Request $request)
    {
        DB::table('performanceFlags')->insert(
            [
                'athlete_id' => $request->input('record.athlete_id'),
                'meeting_id' => $request->input('record.meeting_id'),
                'date' => $request->input('record.date'),
                'flag' => $request->input('reason'),
                'notes' => $request->input('notes')
            ]
        );
        // return response()->json('true');
    }
}
