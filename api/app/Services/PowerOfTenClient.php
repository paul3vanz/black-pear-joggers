<?php

namespace App\Services;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use Log;

/**
 * Reads athlete data from the rebuilt Power of 10 site (powerof10.uk).
 *
 * Background: the redesign put every JSON endpoint behind Google reCAPTCHA, so
 * GetAthletePerformances / RunAthleteSearch / SearchRankings*Club all answer
 * {"status":"RECAPTCHA_REQUIRED"} to an unattended client. The server-rendered
 * pages are NOT protected, and the athlete page happens to embed everything we
 * need as plain JavaScript literals:
 *
 *   let gridData = {...}   the byte-for-byte response GetAthletePerformances
 *                          would return (status "OK") for the most recent year
 *                          holding data, for each of the Full/Road/Track/XC tabs.
 *   var dataRp*<n>         per-event race progression arrays: the athlete's FULL
 *                          multi-year history (dates, times, meetings, venues,
 *                          positions, age groups).
 *   hcapHistData/Dates     the runBritain handicap history. runbritainrankings.com
 *                          now redirects here and its profile.aspx is gone, so
 *                          this replaces the old rankings scrape.
 *
 * One page fetch therefore replaces the two requests (Power of 10 + runBritain)
 * the old implementation made.
 *
 * Known limitation: the progression charts cover road and track events only.
 * Cross country and race walk performances appear in gridData but have no chart
 * series, so for those we can only see the most recent year that has data.
 */
class PowerOfTenClient
{
    private const BASE_URL = 'https://www.powerof10.uk';

    private const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        . 'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

    /**
     * Chart value encodings. MinSec/SecCs/MinSecCs are hundredths of a second,
     * HrMinSec is whole seconds, and MetreCm/KmMetre are hundredths of a METRE.
     * A 12.13m triple jump must never be read as a time of 12:13.
     */
    private const CENTISECOND_FORMATS = ['MinSec', 'SecCs', 'MinSecCs'];
    private const SECOND_FORMATS = ['HrMinSec'];
    private const DISTANCE_FORMATS = ['MetreCm', 'KmMetre'];

    /**
     * Field events, which the performances table cannot represent (time_parsed
     * drives the personal best calculation). Used as a fallback for grid rows,
     * which carry no format flag of their own.
     */
    private const FIELD_EVENTS = [
        'long jump', 'triple jump', 'high jump', 'pole vault', 'shot', 'discus',
        'javelin', 'hammer', 'weight', 'ball',
    ];

    /**
     * Maps Power of 10 event labels onto the aliases already in our events
     * table, so the personal best query keeps working. Anything unmapped is
     * stored as-is and simply does not pick up a distance (the PB query left
     * joins), which is the same behaviour unusual events had before.
     */
    private const EVENT_ALIASES = [
        'half marathon' => 'HM',
        'half_marathon' => 'HM',
        'marathon' => 'Mar',
        '20 miles' => '20M',
        '20m' => '20M',
        '15 miles' => '15M',
        '15m' => '15M',
        '10 miles' => '10M',
        '10m' => '10M',
        '6 miles road' => '6M',
        '5 miles' => '5M',
        '5m' => '5M',
        'mile' => '1M',
        '1 mile road' => '1M',
        'milew' => 'MileW',
        '5k road' => '5K',
        'parkrun' => 'parkrun',
    ];

    private Client $httpClient;

    public function __construct(?Client $httpClient = null)
    {
        $this->httpClient = $httpClient ?: new Client([
            'timeout' => 45,
            'headers' => [
                'User-Agent' => self::USER_AGENT,
                'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language' => 'en-GB,en;q=0.9',
            ],
        ]);
    }

    /**
     * Fetch an athlete profile page. Returns null when the athlete is unknown.
     */
    public function fetchAthletePage(string $guid): ?string
    {
        $url = self::BASE_URL . '/Home/Athlete/' . $guid;

        try {
            $response = $this->httpClient->request('GET', $url);
        } catch (GuzzleException $e) {
            Log::error('Power of 10 fetch failed', ['guid' => $guid, 'error' => $e->getMessage()]);

            return null;
        }

        $html = (string) $response->getBody();

        // The site answers 200 with a friendly page rather than a 404.
        if (str_contains($html, 'could not be found')) {
            Log::info('Power of 10 athlete not found', ['guid' => $guid]);

            return null;
        }

        return $html;
    }

    // ---------------------------------------------------------------- profile

    public function parseProfile(string $html): array
    {
        // Athletes with a profile photo expose their legacy integer id as the
        // image filename, which is our athletes.athlete_id. Only around a
        // quarter of athletes have one, so this confirms a mapping rather than
        // establishing it.
        $legacyId = null;
        if (preg_match('#/Images/Athletes/(\d+)\.jpg#', $html, $m)) {
            $legacyId = (int) $m[1];
        }

        $club = null;
        if (preg_match('/First Claim Club:\s*([^"]+)"/', $html, $m)) {
            $club = trim($m[1]);
        }

        $ageGroup = null;
        if (preg_match('/id="divAllAgeGroup"[^>]*>([^<]*)</', $html, $m)) {
            $ageGroup = trim($m[1]);
        }

        return [
            'legacyAthleteId' => $legacyId,
            'club' => $club,
            'ageGroup' => $ageGroup ?: null,
        ];
    }

    // ----------------------------------------------------------- performances

    /**
     * The athlete's full performance history, newest last.
     *
     * Built from the progression charts (every year) and then overlaid with the
     * embedded grid payload (most recent year only, but richer: chip times,
     * meeting GUIDs, and the cross country events the charts omit).
     *
     * @return array<int, array<string, mixed>>
     */
    public function parsePerformances(string $html): array
    {
        $performances = $this->parseChartHistory($html);
        $formats = $this->eventFormats($html);

        foreach ($this->parseGridPerformances($html, $formats) as $row) {
            $key = $this->performanceKey($row);
            $performances[$key] = array_merge($performances[$key] ?? [], $row);
        }

        $performances = array_values($performances);
        usort($performances, fn($a, $b) => strcmp($a['date'], $b['date']));

        return $performances;
    }

    private function performanceKey(array $row): string
    {
        return $row['event'] . '|' . $row['date'] . '|' . round((float) $row['timeParsed'], 2);
    }

    /**
     * Event code => chart value format, e.g. "Long_Jump" => "MetreCm".
     */
    private function eventFormats(string $html): array
    {
        $formats = [];

        foreach ($this->chartEventKeys($html) as $index => $event) {
            if (preg_match('/var dataFormatToUse' . $index . " = '(.*?)';/", $html, $m)) {
                $formats[$this->normaliseEvent($event)] = $m[1];
            }
        }

        return $formats;
    }

    /**
     * @return array<int, string> chart index => event key
     */
    private function chartEventKeys(string $html): array
    {
        preg_match_all("/evntKeys\.set\((\d+), '(.*?)'\)/", $html, $matches, PREG_SET_ORDER);

        $keys = [];
        foreach ($matches as $match) {
            $keys[(int) $match[1]] = $match[2];
        }

        return $keys;
    }

    /**
     * Full multi-year history from the per-event progression charts.
     */
    private function parseChartHistory(string $html): array
    {
        $performances = [];

        foreach ($this->chartEventKeys($html) as $index => $eventKey) {
            $format = 'MinSec';
            if (preg_match('/var dataFormatToUse' . $index . " = '(.*?)';/", $html, $m)) {
                $format = $m[1];
            }

            if (in_array($format, self::DISTANCE_FORMATS, true)) {
                continue; // field event, cannot be stored as a time
            }

            $dates = $this->jsStringArray($html, 'dataRpMeetDates' . $index);
            $values = $this->jsNumberArray($html, 'dataRpValues' . $index);
            $meetings = $this->jsStringArray($html, 'dataRpMeetings' . $index);
            $venues = $this->jsStringArray($html, 'dataRpLocations' . $index);
            $positions = $this->jsStringArray($html, 'dataRpPositions' . $index);
            $ageGroups = $this->jsStringArray($html, 'dataRpAgeGroups' . $index);

            $event = $this->normaliseEvent($eventKey);

            foreach ($dates as $i => $date) {
                if (!$date || !isset($values[$i])) {
                    continue;
                }

                $seconds = $this->decodeChartValue($values[$i], $format);
                if ($seconds === null) {
                    continue;
                }

                [$day, $month, $year] = explode('/', $date);

                $row = [
                    'event' => $event,
                    'rawEvent' => $eventKey,
                    'date' => sprintf('%s-%s-%s', $year, $month, $day),
                    'timeParsed' => $seconds,
                    'time' => $this->formatSeconds($seconds),
                    'meeting' => $meetings[$i] ?? null,
                    'venue' => $venues[$i] ?? null,
                    'position' => $positions[$i] ?? null,
                    'ageGroup' => $this->normaliseAgeGroup($ageGroups[$i] ?? null),
                    'po10MeetingId' => null,
                    'source' => 'chart',
                ];

                $performances[$this->performanceKey($row)] = $row;
            }
        }

        return $performances;
    }

    /**
     * The embedded copy of the GetAthletePerformances response. Covers only the
     * most recent year holding data per tab, but is the only source for cross
     * country, and carries chip times and meeting GUIDs.
     */
    private function parseGridPerformances(string $html, array $formats = []): array
    {
        $grid = $this->parseGridData($html);
        if (!$grid || empty($grid['perfs']['dictpgs'])) {
            return [];
        }

        $rows = [];

        foreach ($grid['perfs']['dictpgs'] as $block) {
            $year = $block['yr'] ?? null;
            if (!$year) {
                continue;
            }

            foreach ($block['pgs'] ?? [] as $page) {
                foreach ($page['results'] ?? [] as $result) {
                    $event = $this->normaliseEvent($result['evnt'] ?? '');

                    if ($this->isFieldEvent($event, $formats)) {
                        continue;
                    }

                    $date = $this->parseGridDate($result['dte'] ?? '', (int) $year);
                    if (!$date) {
                        continue;
                    }

                    // Chip time is the athlete's actual time where recorded.
                    $display = $result['perfchip'] ?: ($result['perf'] ?? '');
                    $seconds = $this->parseTime($display);
                    if ($seconds === null) {
                        continue;
                    }

                    $rows[] = [
                        'event' => $event,
                        'rawEvent' => $result['evnt'] ?? null,
                        'date' => $date,
                        'timeParsed' => $seconds,
                        'time' => $display,
                        'meeting' => $result['mtn'] ?? null,
                        'venue' => $result['venn'] ?? null,
                        'position' => $result['pos'] ?? null,
                        'ageGroup' => null,
                        'po10MeetingId' => $result['mtid'] ?: null,
                        'source' => 'grid',
                    ];
                }
            }
        }

        return $rows;
    }

    public function parseGridData(string $html): ?array
    {
        if (!preg_match('/let gridData = (\{.*?\});\s*\n/s', $html, $m)) {
            return null;
        }

        return json_decode($m[1], true);
    }

    // --------------------------------------------------------------- rankings

    /**
     * runBritain handicap history, replacing the dead runbritainrankings scrape.
     *
     * The chart is paginated: hcapHistData and hcapHistDates are pushed one
     * array per page and align 1:1 within a page, but the pages are not in
     * chronological order (page 0 is the most recent block), so pair per page
     * and sort afterwards.
     *
     * Note this series samples at the points the handicap actually changed,
     * where the old runBritain scrape recorded whatever the value was on the
     * day the cron ran. Same metric and scale, different sample dates.
     *
     * @return array<int, array{date: string, ranking: float}>
     */
    public function parseRankings(string $html): array
    {
        preg_match_all('/hcapHistData\.push\(\[(.*?)\]\);/s', $html, $dataPages);
        preg_match_all('/hcapHistDates\.push\(\[(.*?)\]\);/s', $html, $datePages);

        $rankings = [];

        foreach ($dataPages[1] as $page => $dataPage) {
            if (!isset($datePages[1][$page])) {
                continue;
            }

            preg_match_all('/y:\s*([\d.]+)/', $dataPage, $values);
            preg_match_all("/'(.*?)'/", $datePages[1][$page], $dates);

            foreach ($values[1] as $i => $value) {
                if (!isset($dates[1][$i])) {
                    continue;
                }

                $date = $this->parseTextDate($dates[1][$i]);
                if (!$date) {
                    continue;
                }

                $rankings[$date] = ['date' => $date, 'ranking' => (float) $value];
            }
        }

        ksort($rankings);

        return array_values($rankings);
    }

    // ---------------------------------------------------------------- helpers

    /**
     * Read a JavaScript array of single quoted strings. Written by hand rather
     * than by swapping quotes, because meeting names legitimately contain both
     * escaped apostrophes and double quotes.
     */
    private function jsStringArray(string $html, string $name): array
    {
        if (!preg_match('/(?:var|let)\s+' . preg_quote($name, '/') . '\s*=\s*\[(.*?)\];/s', $html, $m)) {
            return [];
        }

        preg_match_all("/'((?:[^'\\\\]|\\\\.)*)'/s", $m[1], $items);

        return array_map(
            fn($value) => stripslashes($value),
            $items[1]
        );
    }

    private function jsNumberArray(string $html, string $name): array
    {
        if (!preg_match('/(?:var|let)\s+' . preg_quote($name, '/') . '\s*=\s*\[(.*?)\];/s', $html, $m)) {
            return [];
        }

        preg_match_all('/-?\d+(?:\.\d+)?/', $m[1], $items);

        return array_map('floatval', $items[0]);
    }

    /**
     * Chart integer to seconds, or null when the value is a distance.
     */
    private function decodeChartValue(float $value, string $format): ?float
    {
        if (in_array($format, self::SECOND_FORMATS, true)) {
            return $value;
        }

        if (in_array($format, self::CENTISECOND_FORMATS, true)) {
            return round($value / 100, 2);
        }

        return null;
    }

    private function isFieldEvent(string $event, array $formats): bool
    {
        if (isset($formats[$event])) {
            return in_array($formats[$event], self::DISTANCE_FORMATS, true);
        }

        $needle = strtolower($event);
        foreach (self::FIELD_EVENTS as $fieldEvent) {
            if (str_contains($needle, $fieldEvent)) {
                return true;
            }
        }

        return false;
    }

    public function normaliseEvent(string $event): string
    {
        $event = trim($event);
        $key = strtolower($event);

        return self::EVENT_ALIASES[$key] ?? $event;
    }

    /**
     * "Veteran 40" => "V40", "Senior" => "SEN", "Under 20" => "U20".
     */
    private function normaliseAgeGroup(?string $ageGroup): ?string
    {
        if (!$ageGroup) {
            return null;
        }

        if (preg_match('/Veteran\s*(\d+)/i', $ageGroup, $m)) {
            return 'V' . $m[1];
        }

        if (preg_match('/Under\s*(\d+)/i', $ageGroup, $m)) {
            return 'U' . $m[1];
        }

        if (stripos($ageGroup, 'senior') !== false) {
            return 'SEN';
        }

        return $ageGroup;
    }

    /**
     * Grid rows carry the day and month only ("31 Jan"); the year comes from
     * the surrounding block.
     */
    private function parseGridDate(string $dayMonth, int $year): ?string
    {
        $timestamp = strtotime(trim($dayMonth) . ' ' . $year);

        return $timestamp ? date('Y-m-d', $timestamp) : null;
    }

    private function parseTextDate(string $date): ?string
    {
        $timestamp = strtotime(trim($date));

        return $timestamp ? date('Y-m-d', $timestamp) : null;
    }

    /**
     * "24:01" => 1441.0, "2:57:14" => 10634.0, "16.6" => 16.6
     */
    public function parseTime(string $time): ?float
    {
        $time = trim($time);
        if ($time === '') {
            return null;
        }

        $parts = explode(':', $time);

        $seconds = match (count($parts)) {
            3 => ((int) $parts[0] * 3600) + ((int) $parts[1] * 60) + (float) $parts[2],
            2 => ((int) $parts[0] * 60) + (float) $parts[1],
            default => (float) $time,
        };

        return $seconds > 0 ? $seconds : null;
    }

    /**
     * Seconds to a display string. Times of an hour or more are rendered
     * h:mm:ss rather than the site's occasional "83:08" minutes style, so the
     * stored value is unambiguous.
     */
    public function formatSeconds(float $seconds): string
    {
        $hours = (int) floor($seconds / 3600);
        $minutes = (int) floor(fmod($seconds, 3600) / 60);
        $remainder = fmod($seconds, 60);

        // Drop the .00 that whole-second results would otherwise carry.
        $secondsPart = fmod($remainder, 1) < 0.005
            ? sprintf('%02d', round($remainder))
            : sprintf('%05.2f', $remainder);

        if ($hours > 0) {
            return sprintf('%d:%02d:%s', $hours, $minutes, $secondsPart);
        }

        return sprintf('%d:%s', $minutes, $secondsPart);
    }
}
