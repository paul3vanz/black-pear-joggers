<?php

namespace App\Http\Controllers;

use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class RecordsController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
    }

    /* Club records */
    public function getRecords(Request $request)
    {
        $records = Cache::remember('records-v3', 28800, function () use ($request) {
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

            return DB::select("
                    SELECT
                      *
                    FROM (
                      SELECT
                        e.event,
                        a.gender, p.category, CONCAT(a.gender, p.category) cat, p.time, a.first_name, a.last_name, m.name, m.date,
                        p.time_parsed, e.distance, a.id AS athlete_id, m.ukaMeetingId, p.id
                      FROM performances p
                      LEFT JOIN athletes a ON a.id = p.athlete_id
                      INNER JOIN meetings m ON m.id = p.meetingId
                      INNER JOIN events e ON e.alias = m.event
                      LEFT JOIN performanceFlags pf ON pf.athlete_id = p.athlete_id AND pf.meeting_id = m.ukaMeetingId AND pf.`date` = m.`date` AND pf.approved IS NOT NULL
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
        });

        return response()->json($records);
    }
}
