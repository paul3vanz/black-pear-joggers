<?php

namespace App\Http\Controllers;

use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

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
            ->groupBy('performances.id')
            ->select(
                DB::raw(
                    'MAX(awards.id) AS award'
                ),
                'athletes.id AS athlete_id',
                'athletes.first_name',
                'athletes.last_name',
                'athletes.gender',
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

        $performances = $performances->paginate(1000);

        return response()->json($performances);
    }

    public function getPerformance($id)
    {
        $performance = Performance::query()->find($id);
        return response()->json($performance);
    }

    public function getAwards(Request $request)
    {

        $filters = [];
        $filterString = '';

        $athlete = (int) $request->input('athlete') || null;
        $year = (int) $request->input('year') || null;

        if ($year) $filters[] = 'YEAR(pf.`date`) = 2017' . $year;
        if ($athlete) $filters[] = 'at.id' . $athlete;

        if ($filters) $filterString = 'HAVING ' . implode(' AND ', $filters);

        $results = DB::select("
            SELECT
            MAX(aw.id) AS award,
            at.id, at.first_name, at.last_name, at.gender, pf.category,
            pf.event, ev.alias, ev.distance, pf.`time`, pf.time_parsed, pf.race, pf.`date`
            FROM
            performances pf
            INNER JOIN
            athletes at
            ON at.id = pf.athlete_id
            LEFT JOIN
            events ev
            ON ev.alias = pf.`event`
            LEFT JOIN
            standards st
            ON st.gender = at.gender
            AND st.category = pf.category
            AND st.event_id = ev.has_standard
            AND st.time_parsed >= pf.time_parsed
            LEFT JOIN
            awards aw
            ON aw.id = st.award_id
            LEFT JOIN
            members m
            ON m.urn = at.urn
            WHERE
            $filterString
            GROUP BY pf.id
            HAVING
            MAX(aw.id)
            ORDER BY
            at.last_name,
            at.first_name,
            pf.category DESC,
            ev.distance ASC,
            MAX(aw.id) DESC,
            pf.time_parsed ASC,
            pf.`date` DESC
        ");

        return response()->json($records);
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

    /* Club records */
    public function getRecords(Request $request)
    {

        $filters = [];
        $filterString = '';
        $groupString = '';

        $gender = $request->input('gender');
        $category = $request->input('category');
        $event = $request->input('event');
        $group = $request->input('group');

        if ($gender) $filters[] = 'gender = "' . $gender . '"';
        if ($category) $filters[] = 'category = "' . $category . '"';
        if ($event) $filters[] = 'event = "' . $event . '"';

        if ($filters) $filterString = 'HAVING ' . implode(' AND ', $filters);

        switch ($group) {
            case 'distance':
                $groupString = 'distance';
                break;
            case 'gender':
                $groupString = 'event, gender';
                break;
            default:
                $groupString = 'distance, gender, category';
                break;
        }

        $records = DB::select("
                SELECT
                  *
                FROM (
                  SELECT
                    e.event,
                    a.gender, p.category, CONCAT(a.gender, p.category) cat, p.time, a.first_name, a.last_name, p.race, p.date,
                    p.time_parsed, e.distance, a.id AS athlete_id, p.meeting_id, p.id
                  FROM performances p
                  LEFT JOIN athletes a ON a.id = p.athlete_id
                  INNER JOIN events e ON e.alias = p.event
                  LEFT JOIN performanceFlags pf ON pf.athlete_id = p.athlete_id AND pf.meeting_id = p.meeting_id AND pf.`date` = p.`date` AND pf.approved IS NOT NULL
                  WHERE pf.flag IS NULL
                  AND p.category != ''
                  AND p.time_parsed IS NOT NULL
                  ORDER BY p.time_parsed ASC LIMIT 100000000) AS t
                  GROUP BY $groupString
                  $filterString
                  ORDER BY gender,
                  CASE category
                       WHEN 'U20' THEN 1
                       WHEN 'U23' THEN 2
                       WHEN 'SEN' THEN 3
                       ELSE 4
                  END,
                  cat,
                  category,
                  distance
        ");
        return response()->json($records);
    }

    public function getParkrunAlphabet(Request $request)
    {
        $year = $request->input('year');
        $challenge = $request->input('challenge');

        $challengeSeperatedByPipes = join('|', str_split($challenge));
        $challengeSeparatedByCommasWithQuotes = '\'' . join('\', \'', str_split($challenge)) . '\'';

        $results = DB::select("
      SELECT
        *
      FROM
        (
          SELECT
            `a`.`id` AS `athlete_id`,
            `a`.`first_name` AS `first_name`,
            `a`.`last_name` AS `last_name`,
            SUBSTR(`r`.`race`, 1, 1) AS `letter`,
            `r`.`race` AS `race`,
            `r`.`date` AS `date`
          FROM
            (
              `performances` `r`
              JOIN
                `athletes` `a`
                ON((`a`.`id` = `r`.`athlete_id`))
            )
          WHERE
            (
              (`r`.`event` = 'parkrun')
              AND
              (
                `r`.`race` regexp '^($challengeSeperatedByPipes)'
              )
              AND
              (
                YEAR(`r`.`DATE`) IN ($year)
              )
            )
          GROUP BY
            `a`.`id`,
            r.`race`
          ORDER BY
            `a`.`last_name`,
            `a`.`first_name`,
            FIELD(`letter`, $challengeSeparatedByCommasWithQuotes),
            r.`DATE`
        )
        AS results
      GROUP BY
        `last_name`,
        `first_name`,
        `letter`
      ORDER BY
        `last_name`,
        `first_name`,
        FIELD(`letter`, $challengeSeparatedByCommasWithQuotes)
    ");

        return response()->json($results);
    }

    public function getParkrunTourists(Request $request)
    {
        $results = DB::select("
          SELECT
            a.athlete_id,
            a.first_name,
            a.last_name,
            GROUP_CONCAT(
              DISTINCT SUBSTRING(race, 1, POSITION(' parkrun #' IN race) - 1)
              ORDER BY
                race separator ', '
            ) AS events,
            COUNT(DISTINCT SUBSTRING(race, 1, POSITION('#' IN race) - 2)) AS event_count
          FROM
            performances p
            INNER JOIN
              athletes a
              ON a.id = p.athlete_id
            INNER JOIN
              memberships m
              ON m.urn = a.urn
              AND m.competitiveRegStatus IN ('Registered', 'Registration Being Processed', 'Registration Being Processed By Club', 'Awaiting Registration with Club')
          WHERE
            p.event = 'parkrun'
          GROUP BY a.athlete_id
          HAVING event_count >= 10
          ORDER BY event_count DESC
        ");
        return response()->json($results);
    }

    public function syncMagicMileResults()
    {
        $results = DB::affectingStatement("
      INSERT INTO performances
      (
          athlete_id,
          category,
          meeting_id,
          event,
          time,
          time_parsed,
          race,
          date,
          manual,
          isPersonalBest
      )
      SELECT
          m.athlete_id,
          m.category,
          0,
          '1M',
          m.actual_time,
          m.actual_time_parsed,
          m.location,
          m.date,
          1,
          0
      FROM magicMile m
      LEFT JOIN performances p2
          ON m.athlete_id = p2.athlete_id
          AND m.date = p2.date
          AND m.location = p2.race
          AND m.actual_time_parsed = p2.time_parsed
      WHERE m.athlete_id IS NOT NULL
      AND m.athlete_id != 0
      AND p2.id IS NULL
    ");

        return response()->json(['recordsInserted' => $results]);
    }
}
