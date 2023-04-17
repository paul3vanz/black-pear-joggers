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
        'category',
        'event',
        'fromDate',
        'gender',
        'isPersonalBest',
        'limit',
        'meetingId',
        'onlyAwards',
        'search',
        'sort',
        'toDate',
        'year',
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

        $cacheKey = 'performances-v5-' . json_encode($filters);

        $performances = Cache::remember($cacheKey, 5, function () use ($request) {

            $performances = DB::table('performances')
                ->join('athletes', 'performances.athlete_id', '=', 'athletes.id')
                ->join('meetings', 'performances.meetingId', '=', 'meetings.id')
                ->leftJoin('events', 'meetings.event', '=', 'events.alias')
                ->leftJoin('standards', function ($join) {
                    $join->on('athletes.gender', '=', 'standards.gender')
                        ->on('standards.category', '=', 'performances.category')
                        ->on('standards.event_id', '=', 'events.has_standard')
                        ->on('standards.time_parsed', '>=', 'performances.time_parsed');
                })
                ->leftJoin('awards', 'standards.award_id', '=', 'awards.id')
                ->join('memberships', function ($join) use ($request) {
                    $join->on('athletes.urn', '=', 'memberships.urn')
                        ->when(!$request->input('includeAllMembers'), function ($query) {
                            $query->where('memberships.competitiveRegStatus', '=', 'Registered');
                        });
                })
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
                if (strpos($searchTerm, ' OR ') !== false) {
                    $searchTermArray = explode(' OR ', $searchTerm);
                    $performances = $performances->where(function ($query) use ($searchTermArray, $performances) {
                        foreach ($searchTermArray as $term) {
                            $query->orWhere('meetings.name', 'LIKE', "%$term%");
                        }
                    });
                } else {
                    $performances = $performances->where('meetings.name', 'LIKE', "%$searchTerm%");
                }
            }

            if ($request->input('athleteId')) {
                $performances = $performances->where('performances.athlete_id', '=', $request->input('athleteId'));
            }

            if ($request->input('meetingId')) {
                $performances = $performances->where('performances.meetingId', '=', $request->input('meetingId'));
            }

            if ($request->input('gender')) {
                $performances = $performances->where('athletes.gender', '=', $request->input('gender'));
            }

            if ($request->input('category')) {
                $performances = $performances->where('performances.category', '=', $request->input('category'));
            }

            if ($request->input('event')) {
                $performances = $performances->where('meetings.event', '=', $request->input('event'));
            }

            if ($request->input('distance')) {
                $performances = $performances->where('events.distance', '=', $request->input('distance'));
            }

            if ($request->input('isPersonalBest')) {
                $performances = $performances->where('performances.isPersonalBest', true);
            }

            if ($request->input('fromDate')) {
                $performances = $performances->where('meetings.date', '>=', $request->input('fromDate'));
            }

            if ($request->input('toDate')) {
                $performances = $performances->where('meetings.date', '<=', $request->input('toDate'));
            }

            if ($request->input('year')) {
                $performances = $performances->whereYear('meetings.date', '=', $request->input('year'));
            }

            if ($request->input('onlyAwards')) {
                $performances = $performances->havingRaw('MAX(awards.id) IS NOT NULL');
            }

            if ($request->input('sort') == 'athlete') {
                $performances = $performances->orderBy('athletes.last_name', 'desc')
                    ->orderBy('athletes.first_name', 'desc')
                    ->orderBy('meetings.date', 'desc')
                    ->orderBy('performances.time_parsed', 'asc');
            } else if ($request->input('sort') == 'time') {
                $performances = $performances->orderBy('performances.time_parsed', 'asc')
                    ->orderBy('meetings.date', 'asc')
                    ->orderBy('athletes.last_name', 'asc');
            } else {
                $performances = $performances->orderBy('meetings.date', 'desc')->orderBy('performances.time_parsed', 'asc');
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
}
