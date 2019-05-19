<?php

namespace App\Http\Controllers;

use App\Models\Award;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class AwardController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct() {

    }

    public function getAwards() {
        $awards = Award::query()->get()->all();
        return response()->json($awards);
    }

    public function getAward($id) {
        $award = Award::query()->find($id);
        return response()->json($award);
    }

    public function deleteAward($id) {
        $award = Award::query()->find($id);
        return response()->json($award);
    }

    public function getAthleteAwards(Request $request) {
        $filters = [];
        $filterString = '';

        $athlete = (int)$request->input('athlete') || null;
        $year = (int)$request->input('year') || null;

        if ($year) $filters[] = 'YEAR(pf.`date`) = 2017' . $year;
        if ($athlete) $filters[] = 'at.id' . $athlete;

        if ($filters) $filterString = 'HAVING ' . implode(' AND ', $filters);

        $results = DB::select("
            SELECT
            MAX(aw.id) AS award,
            at.id, at.first_name, at.last_name, at.gender, pf.category,
            pf.event, ev.alias, ev.distance, pf.`time`, pf.time_parsed, pf.race, pf.`date`,
            m.paid_status, m.paid_date
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
            /*  at.first_name = 'Paul'
            AND
            at.last_name = 'Evans'
            AND*/
            YEAR(pf.`date`) = 2017
            GROUP BY pf.id
            HAVING 
            MAX(aw.id)
            ORDER BY
            at.last_name,
            at.first_name,
            pf.category,
            ev.distance ASC,
            MAX(aw.id) DESC,
            pf.time_parsed ASC,
            pf.`date` DESC
        ");

        return response()->json($results);
    }
}
