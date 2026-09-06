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
    public function __construct() {}

    /**
     * @OA\Get(
     *   tags={"Records"},
     *   path="/records",
     *   summary="Get club records",
     *   @OA\Parameter(name="gender", in="query", required=false, @OA\Schema(type="string", enum={"M", "W"})),
     *   @OA\Parameter(name="category", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Parameter(name="event", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Parameter(name="group", in="query", required=false, @OA\Schema(type="string", enum={"distance", "gender"})),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    /* Club records */
    public function getRecords(Request $request)
    {
        $records = Cache::remember('records-v5', 28800, function () use ($request) {
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
                        p.time_parsed, e.distance, a.id AS athlete_id, a.po10_guid, m.ukaMeetingId, p.id
                      FROM performances p
                      LEFT JOIN athletes a ON a.id = p.athlete_id
                      INNER JOIN meetings m ON m.id = p.meetingId
                      INNER JOIN events e ON e.alias = m.event
                      LEFT JOIN performanceFlags pf ON pf.athlete_id = p.athlete_id AND pf.meeting_id = m.ukaMeetingId AND pf.`date` = m.`date` AND pf.approved IS NOT NULL
                      WHERE pf.flag IS NULL
                      AND p.category != ''
                      AND a.gender IS NOT NULL
                      AND IF(p.athlete_id IS NOT NULL AND a.created_at > '2021-01-01' AND a.created_at > m.date, 1, 0) != 1
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

    /**
     * @OA\Post(
     *   tags={"Records"},
     *   path="/records/query",
     *   summary="Flag a club record performance for review",
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"record","reason"},
     *       @OA\Property(property="record", type="object"),
     *       @OA\Property(property="reason", type="string"),
     *       @OA\Property(property="notes", type="string", nullable=true),
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function queryRecord(Request $request)
    {
        $insert = DB::table('performanceFlags')->insert(
            [
                'athlete_id' => $request->input('record.athlete_id'),
                'meeting_id' => $request->input('record.ukaMeetingId'),
                'date' => $request->input('record.date'),
                'flag' => $request->input('reason'),
                'notes' => $request->input('notes')
            ]
        );

        Cache::forget('records-v5');

        return response()->json($insert);
    }
}
