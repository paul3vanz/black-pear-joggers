<?php

namespace App\Http\Controllers;

use Goutte\Client;
use App\Jobs\FetchPerformancesJob;
use App\Jobs\UpdatePersonalBestsJob;
use App\Models\Athlete;
use App\Models\Performance;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
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
      ->where('active', '=', '1')
      ->where('club', 'like', 'Black Pear%')
      ->get();

    foreach ($athletes as $athlete) {
      dispatch(new FetchPerformancesJob($athlete));

      $athleteIds[] = $athlete->id;
    }

    return response()->json($athleteIds);
  }

  public function fetchPerformances($athleteId)
  {
    Log::info("fetchPerformances($athleteId)");
    $addedPerformances = array();

    $athletes = Athlete::where('athlete_id', '=', $athleteId)->get();

    foreach ($athletes as $athlete) {
      $html = $this->fetchPowerOfTenAthleteProfile($athlete->urn);

      $addedPerformances = $this->parsePerformanceHistory($athlete, $html);

      Log::info('Added ' . sizeof($addedPerformances));
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
                    LEFT JOIN events e1 ON e1.alias = t1.event
                    WHERE
                        t1.athlete_id = t.athlete_id
                        AND e1.distance = e.distance
                        AND t1.date < t.date
                        AND t1.time_parsed <= t.time_parsed
                )
                    THEN FALSE
                    ELSE TRUE
                END calculateIsPersonalBest
            FROM performances t
            LEFT JOIN events e ON e.alias = t.event
            ORDER BY date
        ) pbs ON pbs.id = p2.id
        SET p2.isPersonalBest = pbs.calculateIsPersonalBest
      ");

    Log::info("Updated $update PBs");

    return response()->json(['affectedRows' => $update]);
  }

  public function queueUpdatePersonalBests()
  {
    dispatch(new UpdatePersonalBestsJob());
  }

  private function fetchPowerOfTenAthleteProfile($athleteUrn)
  {
    Log::info("fetchPowerOfTenProfile($athleteUrn)");

    $fetchUrl = 'https://www.thepowerof10.info/athletes/profile.aspx?ukaurn=' . $athleteUrn;
    $httpClient = new Client();
    $html = $httpClient->request('GET', $fetchUrl);

    return $html;
  }

  private function createPerformance($performance)
  {
    return Performance::firstOrCreate([
      'athlete_id' => $performance['athlete_id'],
      'category' => $performance['category'],
      'date' => $performance['date'],
      'event' => $performance['event'],
      'meeting_id' => $performance['meeting_id'],
      'race' => $performance['race'],
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
          Log::info('Error extracting year/age group: ' . $tableRow->eq(0)->text());
          die();
        }

        // Log::info('Found group of performances: ' . $currentYear . ', ' . $currentAgeGroup);

        return;
      }

      // Skip if the row is full of headings, not data
      if (trim($tableRow->children()->eq(0)->text()) === 'Event') {
        return;
      }

      $tableCells = $tableRow->filter('td');

      $athleteId = $athlete->id;
      $event = trim($tableCells->eq(0)->text());
      $gunTime = trim($tableCells->eq(1)->text());
      $chipTime = trim($tableCells->eq(4)->text());
      $time = ($chipTime) ? $chipTime : $gunTime;
      $timeParsed = $this->parseTime($time);
      $race = trim($tableCells->eq(10)->text());
      $dateTimestamp = strtotime(trim($tableCells->eq(11)->text()));
      $date = date('Y-m-d', $dateTimestamp);

      preg_match('/meetingid=([0-9]*)/i', $tableCells->eq(9)->filter('a')->first()->link()->getUri(), $meetingId);
      $meetingId = $meetingId[1];

      // Correct age category if date of birth known
      if ($athlete->dob && $athlete->dob != '0000-00-00') {
        $raceDate = new DateTime($date);
        $birthDate = new DateTime($athlete->dob);
        $ageAtRace = $raceDate->diff($birthDate);
        $currentAgeGroup = $this->ageGroup((int) $ageAtRace->format('%y'));
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
        'meeting_id' => $meetingId,
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
      Log::info('Unable to parse time: ' . $time);

      return false;
    }

    return $timeParsed;
  }

  private function ageGroup($age)
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
