<?php

namespace App\Http\Controllers;

use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ParkrunController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
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
              AND m.competitiveRegStatus IN ('Registered')
          WHERE
            p.event = 'parkrun'
          GROUP BY a.athlete_id
          HAVING event_count >= 10
          ORDER BY event_count DESC
        ");
        return response()->json($results);
    }
}