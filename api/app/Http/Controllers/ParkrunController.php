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

        if (strpos($challenge, ' OR ') !== false) {
          $eventNameFilter = 'm.name regexp \'^((' . join(')|(', explode(' OR ', $challenge)) . '))\'';
        } else {
          $eventNameFilter = 'm.name regexp \'^(' . $challengeSeperatedByPipes . ')\'';
        }

        $results = DB::select("
      SELECT
        *
      FROM
        (
          SELECT
            a.`id` AS `athlete_id`,
            a.`first_name` AS `first_name`,
            a.`last_name` AS `last_name`,
            SUBSTR(m.`name`, 1, 1) AS `letter`,
            m.`name` AS `race`,
            m.`date` AS `date`
          FROM
            (
              `performances` `r`
              JOIN
                `athletes` `a`
                ON((a.`id` = r.`athlete_id`))
              JOIN
                meetings m
                ON m.id = r.meetingId
            )
          WHERE
            (
              (m.`event` = 'parkrun')
              AND
              (
                $eventNameFilter
              )
              AND
              (
                YEAR(m.date) IN ($year)
              )
            )
          GROUP BY
            a.`id`,
            m.`name`
          ORDER BY
            a.`last_name`,
            a.`first_name`,
            FIELD(`letter`, $challengeSeparatedByCommasWithQuotes),
            m.`date`
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
              DISTINCT SUBSTRING(m.name, 1, POSITION(' parkrun #' IN m.name) - 1)
              ORDER BY
                m.name separator ', '
            ) AS events,
            COUNT(DISTINCT SUBSTRING(m.name, 1, POSITION('#' IN m.name) - 2)) AS event_count
          FROM
            performances p
            INNER JOIN
              athletes a
              ON a.id = p.athlete_id
            INNER JOIN
              meetings m
              ON m.id = p.meetingId
            INNER JOIN
              memberships m
              ON m.urn = a.urn
              AND m.competitiveRegStatus IN ('Registered')
          WHERE
            m.event = 'parkrun'
          GROUP BY a.athlete_id
          HAVING event_count >= 10
          ORDER BY event_count DESC
        ");
        return response()->json($results);
    }
}