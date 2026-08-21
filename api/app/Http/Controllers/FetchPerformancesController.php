<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ChecksPowerOfTenColumn;
use App\Jobs\FetchPerformancesJob;
use App\Jobs\UpdatePersonalBestsJob;
use App\Models\Athlete;
use App\Models\Meeting;
use App\Models\Performance;
use App\Services\PowerOfTenClient;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Log;
use DateTime;

class FetchPerformancesController extends Controller
{
    use ChecksPowerOfTenColumn;

    private PowerOfTenClient $powerOfTen;

    public function __construct(?PowerOfTenClient $powerOfTen = null)
    {
        $this->powerOfTen = $powerOfTen ?: new PowerOfTenClient();
    }

    public function queueAllFetchPerformances()
    {
        $athleteIds = array();

        if (!$this->powerOfTenColumnExists()) {
            return response()->json($athleteIds);
        }

        // po10_guid replaces urn as the lookup key: the rebuilt Power of 10
        // site is keyed by GUID and has no route that accepts a UKA URN.
        $athletes = Athlete::whereNotNull('po10_guid')
            ->get()
            ->filter(function ($item) { return $item->affiliated; })
            ->values();

        foreach ($athletes as $athlete) {
            dispatch(new FetchPerformancesJob($athlete));

            $athleteIds[] = $athlete->athlete_id;
        }

        return response()->json($athleteIds);
    }

    public function fetchPerformances($athleteId)
    {
        Log::info('fetchPerformances', ['athleteId' => $athleteId]);

        $addedPerformances = array();

        $athletes = Athlete::where('athlete_id', '=', $athleteId)->get();

        foreach ($athletes as $athlete) {
            if (!$athlete->po10_guid) {
                Log::info('Skipping athlete with no Power of 10 GUID', ['athleteId' => $athleteId]);

                continue;
            }

            try {
                $html = $this->powerOfTen->fetchAthletePage($athlete->po10_guid);

                if ($html === null) {
                    Log::info('No Power of 10 profile for athlete', ['athleteId' => $athleteId]);

                    continue;
                }

                $addedPerformances = $this->storePerformances(
                    $athlete,
                    $this->powerOfTen->parsePerformances($html)
                );

                Log::info('Added performances', [
                    'athleteId' => $athleteId,
                    'total' => sizeof($addedPerformances),
                ]);
            } catch (\Exception $e) {
                Log::error('Error parsing performance history', [
                    'athleteId' => $athleteId,
                    'error' => $e->getMessage(),
                ]);

                return null;
            }
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

        Log::info('Updated PBs', ['affectedRows' => $update]);

        return response()->json(['affectedRows' => $update]);
    }

    public function queueUpdatePersonalBests()
    {
        dispatch(new UpdatePersonalBestsJob());
    }

    /**
     * Replace the athlete's scraped performances with a freshly parsed set.
     *
     * Manually entered performances (manual = 1) are left alone, matching the
     * previous behaviour.
     */
    private function storePerformances(Athlete $athlete, array $performances): array
    {
        // TODO: We want to keep all old data, just mark as old, not remove
        Performance::whereNull('manual')
            ->where('athlete_id', $athlete->id)
            ->delete();

        $added = array();

        foreach ($performances as $performance) {
            $added[] = $this->createPerformance([
                'athlete_id' => $athlete->id,
                'event' => $performance['event'],
                'time' => $performance['time'],
                'time_parsed' => $performance['timeParsed'],
                'race' => $performance['meeting'],
                'date' => $performance['date'],
                'category' => $this->categoryForRace($athlete, $performance),
                'po10MeetingId' => $performance['po10MeetingId'],
            ]);
        }

        return $added;
    }

    /**
     * Prefer the athlete's real age at the race where we know their date of
     * birth, falling back to the age group Power of 10 recorded.
     */
    private function categoryForRace(Athlete $athlete, array $performance): ?string
    {
        if ($athlete->dob && $athlete->dob != '0000-00-00') {
            $raceDate = new DateTime($performance['date']);
            $birthDate = new DateTime($athlete->dob);
            $ageAtRace = $raceDate->diff($birthDate);

            return $this->convertAgeToAgeGroup((int) $ageAtRace->format('%y'));
        }

        return $performance['ageGroup'] ?? null;
    }

    private function createPerformance($performance)
    {
        $meeting = $this->resolveMeeting($performance);

        return Performance::firstOrCreate([
            'athlete_id' => $performance['athlete_id'],
            'category' => $performance['category'],
            'meetingId' => $meeting->id,
            'time_parsed' => $performance['time_parsed'],
            'time' => $performance['time']
        ]);
    }

    /**
     * Find or create the meeting a performance belongs to.
     *
     * Meetings used to be identified by the integer ukaMeetingId scraped from
     * the old site. The rebuilt site issues GUIDs, and only supplies one for
     * the most recent year, so we match on event + date + name instead.
     *
     * The complication is that the progression charts cap meeting names at 30
     * characters ("Worcester Pitchcroft parkru..."), roughly a tenth of them.
     * Treat a truncated name as a prefix match against what we already hold so
     * we neither duplicate the meeting nor overwrite a good full name with a
     * clipped one.
     */
    private function resolveMeeting($performance): Meeting
    {
        $name = (string) $performance['race'];

        // Only a handful of meetings can share an event and a date, so pull the
        // candidates and prefix match in PHP. Doing it here rather than with a
        // LIKE keeps names containing % or _ working and avoids depending on
        // MySQL's non-standard backslash escaping.
        $candidates = Meeting::where('event', $performance['event'])
            ->where('date', $performance['date'])
            ->get();

        $meeting = $candidates->first(fn($candidate) => $this->isSameMeeting($candidate->name, $name));

        // Upgrade a previously truncated name now that we have the full one.
        if ($meeting && !$this->isTruncated($name) && $meeting->name !== $name) {
            $meeting->name = $name;
            $meeting->save();
        }

        if (!$meeting) {
            $meeting = Meeting::create([
                'id' => Str::uuid(),
                'event' => $performance['event'],
                'date' => $performance['date'],
                'name' => $name,
                'po10MeetingId' => $performance['po10MeetingId'],
            ]);
        }

        if ($performance['po10MeetingId'] && !$meeting->po10MeetingId) {
            $meeting->po10MeetingId = $performance['po10MeetingId'];
            $meeting->save();
        }

        return $meeting;
    }

    private function isTruncated(string $name): bool
    {
        return str_ends_with($name, '...');
    }

    /**
     * Two meeting names refer to the same meeting if they are equal, or if
     * either is the truncated form of the other.
     */
    private function isSameMeeting(string $stored, string $incoming): bool
    {
        if ($stored === $incoming) {
            return true;
        }

        if ($this->isTruncated($incoming) && str_starts_with($stored, substr($incoming, 0, -3))) {
            return true;
        }

        if ($this->isTruncated($stored) && str_starts_with($incoming, substr($stored, 0, -3))) {
            return true;
        }

        return false;
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
