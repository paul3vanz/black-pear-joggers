<?php

namespace App\Http\Controllers;

use Goutte\Client;
use App\Jobs\FetchPerformancesJob;
use App\Jobs\UpdatePersonalBestsJob;
use App\Models\Athlete;
use App\Models\Meeting;
use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Log;
use DateTime;

class FetchPerformancesController extends Controller
{
    public function __construct()
    {
    }

    public function queueAllFetchPerformances()
    {
        $athleteIds = array();

        $athletes = Athlete::whereNotNull('urn')
            ->has('activeMembership')
            ->get();

        foreach ($athletes as $athlete) {
            dispatch(new FetchPerformancesJob($athlete));

            $athleteIds[] = $athlete->athlete_id;
        }

        return response()->json($athleteIds);
    }

    public function fetchPerformances($athleteId)
    {
        Log::channel('slackInfo')->info("fetchPerformances($athleteId)");
        $addedPerformances = array();

        $athletes = Athlete::where('athlete_id', '=', $athleteId)->get();

        foreach ($athletes as $athlete) {
            $html = $this->fetchPowerOfTenAthleteProfile($athlete->urn);

            $addedPerformances = $this->parsePerformanceHistory($athlete, $html);

            Log::channel('slackInfo')->info('Added ' . sizeof($addedPerformances));
        }

        return response()->json($addedPerformances);
    }

    public function updatePersonalBests()
    {
        $update = DB::update("
        UPDATE performances p2
        INNER JOIN (
            SELECT
                t.*,
                e.distance,
                CASE WHEN exists(
                    SELECT 1
                    FROM performances t1
                    INNER JOIN meetings m1 ON m1.id = t1.meetingId
                    LEFT JOIN events e1 ON e1.alias = m1.event
                    WHERE
                        t1.athlete_id = t.athlete_id
                        AND e1.distance = e.distance
                        AND m1.date < m.date
                        AND t1.time_parsed <= t.time_parsed
                )
                    THEN FALSE
                    ELSE TRUE
                END calculateIsPersonalBest
            FROM performances t
            INNER JOIN meetings m ON m.id = t.meetingId
            LEFT JOIN events e ON e.alias = m.event
            ORDER BY date
        ) pbs ON pbs.id = p2.id
        SET p2.isPersonalBest = pbs.calculateIsPersonalBest
      ");

        Log::channel('slackInfo')->info("Updated $update PBs");

        return response()->json(['affectedRows' => $update]);
    }

    public function queueUpdatePersonalBests()
    {
        dispatch(new UpdatePersonalBestsJob());
    }

    private function fetchPowerOfTenAthleteProfile($athleteUrn)
    {
        Log::channel('slackInfo')->info("fetchPowerOfTenProfile($athleteUrn)");

        $fetchUrl = 'https://www.thepowerof10.info/athletes/profile.aspx?ukaurn=' . $athleteUrn;
        $httpClient = new Client();
        $html = $httpClient->request('GET', $fetchUrl);

        return $html;
    }

    private function createPerformance($performance)
    {
        $meeting = Meeting::firstOrCreate(
            [
                'ukaMeetingId' => $performance['ukaMeetingId'],
                'event' => $performance['event'],
                'name' => $performance['race'],
                'date' => $performance['date']
            ],
            [
                'id' => Str::uuid(),
            ]
        );

        return Performance::firstOrCreate([
            'athlete_id' => $performance['athlete_id'],
            'category' => $performance['category'],
            'meetingId' => $meeting->id,
            'time_parsed' => $performance['time_parsed'],
            'time' => $performance['time']
        ]);
    }

    private function rowIsYearAgeGroupHeader($tableRow)
    {
        return strpos($tableRow, 'colspan="12"') !== false;
    }

    private function parsePerformanceHistory(Athlete $athlete, $html)
    {

        $addedPerformances = array();

        $tableRows = $html->filter('div[id=cphBody_pnlPerformances] table[class=alternatingrowspanel] tr');

        // TODO: We want to keep all old data, just mark as old, not remove
        $stalePerformances = Performance::whereNull('manual')
            ->where('athlete_id', $athlete->id)
            ->delete();

        $currentHeader = '';
        $currentYear = '';
        $currentAgeGroup = '';

        $tableRows->each(function ($tableRow, $i) use ($athlete, &$addedPerformances) {
            // Check if this is a new division by age group
            if ($this->rowIsYearAgeGroupHeader($tableRow->html())) {
                $currentHeader = explode(' ', $tableRow->eq(0)->text());
                $currentYear = $currentHeader[0];
                $currentAgeGroup = $currentHeader[1];

                if (!$currentAgeGroup) {
                    Log::channel('slackInfo')->info('Error extracting year/age group: ' . $tableRow->eq(0)->text());
                    die();
                }

                // Log::channel('slackInfo')->info('Found group of performances: ' . $currentYear . ', ' . $currentAgeGroup);

                return;
            }

            // Skip if the row is full of headings, not data
            if (trim($tableRow->children()->eq(0)->text()) === 'Event') {
                return;
            }

            $tableCells = $tableRow->filter('td');

            // <tr style="background-color:WhiteSmoke;">
            // 0 <td>HM</td>
            // 1 <td>84:16</td>
            // 2 <td></td>
            // 3 <td nowrap="" align="right"></td>
            // 4 <td>84:19</td>
            // 5 <td>23</td>
            // 6 <td></td>
            // 7 <td></td>
            // 8 <td></td>
            // 9 <td><a href="../results/results.aspx?meetingid=294267&amp;event=HM&amp;venue=Worcester&amp;date=15-Sep-19" target="_blank">Worcester</a></td>
            // 10 <td>Worcester City Runs Half Marathon</td>
            // 11 <td nowrap="" align="right">15 Sep 19</td>
            // </tr>
            $athleteId = $athlete->id;
            $event = trim($tableCells->eq(0)->text());
            $gunTime = trim($tableCells->eq(4)->text());
            $chipTime = trim($tableCells->eq(1)->text());
            $time = ($chipTime) ? $chipTime : $gunTime;
            $timeParsed = $this->parseTime($time);
            $race = trim($tableCells->eq(10)->text());
            $dateTimestamp = strtotime(trim($tableCells->eq(11)->text()));
            $date = date('Y-m-d', $dateTimestamp);

            preg_match('/meetingid=([0-9]*)/i', $tableCells->eq(9)->filter('a')->first()->link()->getUri(), $ukaMeetingId);
            $ukaMeetingId = $ukaMeetingId[1];

            // Correct age category if date of birth known
            if ($athlete->dob && $athlete->dob != '0000-00-00') {
                $raceDate = new DateTime($date);
                $birthDate = new DateTime($athlete->dob);
                $ageAtRace = $raceDate->diff($birthDate);
                $currentAgeGroup = $this->convertAgeToAgeGroup((int) $ageAtRace->format('%y'));
            }

            if (!$timeParsed) {
                return;
            }

            $addedPerformances[] = $this->createPerformance([
                'athlete_id' => $athleteId,
                'event' => $event,
                'time' => $time,
                'time_parsed' => $timeParsed,
                'race' => $race,
                'date' => $date,
                'category' => $currentAgeGroup,
                'ukaMeetingId' => $ukaMeetingId,
            ]);
        });

        return $addedPerformances;
    }

    private function parseTime($time)
    {
        $timeParts = explode(':', $time);
        $timePartCount = sizeof($timeParts);

        if ($timePartCount === 2) {
            $timeParsed = ((int) $timeParts[0] * 60) + ((float) $timeParts[1]);
        } else if ($timePartCount === 3) {
            $timeParsed = ((int) $timeParts[0] * 3600) + ((int) $timeParts[1] * 60) + ((float) $timeParts[2]);
        } else {
            $timeParsed = (float) $time;
        }

        return $timeParsed;
    }

    private function convertAgeToAgeGroup($age)
    {
        if ($age < 20) {
            return 'U20';
        } else if ($age < 23) {
            return 'U23';
        } else if ($age < 35) {
            return 'SEN';
        } else {
            return 'V' . (floor($age / 5) * 5);
        }
    }
}
