<?php

namespace App\Http\Controllers;

use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class PerformanceController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
    }

    public function getPerformancesIndividual(Request $request)
    {
        $performances = Cache::remember('performancesIndividual-' . $request->input('fromDate') . '-' . $request->input('isPersonalBest'), 28800, function () use ($request) {
            $performances = $this->getPerformances($request);

            return $performances->paginate(50);
        });

        return response()->json($performances);
    }

    public function getPerformancesByAthlete($id, Request $request)
    {
        $performances = $this->getPerformances($request);
        if ($id) {
            $paginate = 1000;
            $performances = $performances->where('performances.athlete_id', '=', $id);
        }
        $performances = $performances->paginate($paginate);
        return response()->json($performances);
    }

    public function getPerformancesByMeeting($date, $meeting, Request $request)
    {
        $performances = $this->getPerformances($request);
        if ($date) {
            $paginate = 500;
            $performances = $performances->where('performances.meeting_id', '=', $meeting);
            $performances = $performances->where('performances.date', '=', $date);
        }
        $performances = $performances->paginate($paginate);
        return response()->json($performances);
    }

    public function getPerformances(Request $request)
    {

        $paginate = 50;

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
            ->groupBy('performances.id')
            ->select(
                DB::raw(
                    'MAX(awards.id) AS award'
                ),
                'athletes.id AS athlete_id',
                'athletes.first_name',
                'athletes.last_name',
                'athletes.gender',
                'memberships.competitiveRegStatus',
                'performances.id AS performance_id',
                'performances.category',
                'performances.event',
                'performances.time',
                'performances.time_parsed',
                'performances.meeting_id',
                'performances.race',
                'performances.date',
                'performances.isPersonalBest'
            );

        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));
        if ($searchTerm) {
            $performances = $performances->where('performances.race', 'LIKE', "%$searchTerm%");
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

        return $performances;
    }

    public function getPerformanceSummaries(Request $request)
    {
        $performances = Performance::query()
            ->select('meeting_id', 'date', 'race', 'event', 'manual', 'first_name', 'last_name', 'performances.created_at', 'performances.updated_at')
            ->addSelect(DB::raw('count(1) AS total_results'))
            ->join('athletes', 'athletes.id', '=', 'performances.athlete_id')
            ->groupBy('date', 'meeting_id')
            ->orderBy('date', 'DESC')
            ->orderBy('race', 'ASC')
            ->orderBy('time_parsed', 'ASC');

        if ($request->input('year')) {
            $performances = $performances->whereYear('date', '=', $request->input('year'));
        }

        $searchTerm = preg_replace('/[^\da-z ]/i', '', $request->input('search'));
        if ($searchTerm) {
            $performances = $performances->where('performances.race', 'LIKE', "%$searchTerm%");
        }

        if ($request->input('fromDate')) {
            $performances = $performances->where('performances.date', '>=', $request->input('fromDate'));
        }

        if ($request->input('toDate')) {
            $performances = $performances->where('performances.date', '<=', $request->input('toDate'));
        }

        $performances = $performances->paginate(1000);

        return response()->json($performances);
    }

    public function getPerformance($id)
    {
        $performance = Performance::query()->find($id);
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
