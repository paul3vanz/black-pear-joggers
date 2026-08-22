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

        // The progression charts publish gun times. The yearly best charts
        // publish the chip time for the same race, so correct each year's
        // fastest run before merging; the grid still wins for the current year
        // because it carries real chip times for every race, not just the best.
        $performances = $this->applyChipTimes($performances, $this->parseYearlyBests($html));

        foreach ($this->parseGridPerformances($html, $formats) as $row) {
            $performances = $this->mergeGridRow($performances, $row);
        }

        $performances = array_values($performances);
        usort($performances, fn($a, $b) => strcmp($a['date'], $b['date']));

        return $performances;
    }

    /**
     * Best per event per year, from the yearly progression charts.
     *
     * These carry the chip time where the per-race charts carry the gun time,
     * which is what the site itself shows as the personal best. Each entry
     * names the venue, which is what lets us be sure we are correcting the
     * right race.
     *
     * @return array<string, array<string, array{seconds: float, venue: ?string}>>
     */
    private function parseYearlyBests(string $html): array
    {
        $bests = [];

        foreach ($this->chartEventKeys($html) as $index => $eventKey) {
            $format = 'MinSec';
            if (preg_match('/var dataFormatToUse' . $index . " = '(.*?)';/", $html, $m)) {
                $format = $m[1];
            }

            if (in_array($format, self::DISTANCE_FORMATS, true)) {
                continue; // field event, cannot be stored as a time
            }

            $years = $this->jsStringArray($html, 'dataLabels' . $index);
            $values = $this->jsNumberArray($html, 'dataValues' . $index);
            $venues = $this->jsStringArray($html, 'dataLocations' . $index);

            $event = $this->normaliseEvent($eventKey);

            foreach ($years as $i => $year) {
                // Years the athlete did not race leave a hole in the values
                // array rather than a zero, so a missing index is expected.
                if (!preg_match('/^\d{4}$/', (string) $year) || !isset($values[$i])) {
                    continue;
                }

                $seconds = $this->decodeChartValue($values[$i], $format);
                if ($seconds === null) {
                    continue;
                }

                $bests[$event][(string) $year] = [
                    'seconds' => $seconds,
                    'venue' => $venues[$i] ?? null,
                ];
            }
        }

        return $bests;
    }

    /**
     * Replace a year's fastest gun time with the chip time for the same race.
     *
     * Only the fastest run of each event and year can be corrected, because
     * that is the only one the yearly charts publish a chip time for. Every
     * lifetime personal best is by definition also a yearly best, so records
     * and awards are covered; ordinary runs keep the gun time. Chip times for
     * the rest are only behind the reCAPTCHA gated endpoint.
     */
    private function applyChipTimes(array $performances, array $bests): array
    {
        if (!$bests) {
            return $performances;
        }

        $byYear = [];
        foreach ($performances as $key => $row) {
            $byYear[$row['event'] . '|' . substr($row['date'], 0, 4)][] = $key;
        }

        foreach ($bests as $event => $years) {
            foreach ($years as $year => $best) {
                $key = $this->runForYearlyBest(
                    $performances,
                    $byYear[$event . '|' . $year] ?? [],
                    $best
                );

                if ($key === null) {
                    continue;
                }

                $row = $performances[$key];
                $row['gunTime'] = $row['time'];
                $row['gunTimeParsed'] = $row['timeParsed'];
                $row['timeParsed'] = $best['seconds'];
                $row['time'] = $this->formatSeconds($best['seconds']);

                unset($performances[$key]);
                $performances[$this->performanceKey($row)] = $row;
            }
        }

        return $performances;
    }

    /**
     * Fold one grid row into the set the charts produced.
     *
     * The grid publishes the chip time where the charts publish the gun time
     * for the same run, so the two rarely agree and the race would otherwise
     * be stored twice: once at each time. Retire the chart row the grid row
     * supersedes and keep the gun time on the survivor.
     */
    private function mergeGridRow(array $performances, array $row): array
    {
        $key = $this->performanceKey($row);

        // Identical times are the common case away from chip timed road races,
        // and settle the question outright. Deal with them first so a track
        // meeting's heats and final are never mistaken for one another below.
        if (isset($performances[$key])) {
            $performances[$key] = $this->mergeRows($performances[$key], $row);

            return $performances;
        }

        $supersedes = $this->chartRowForSameRace($performances, $row);

        if ($supersedes !== null) {
            $row['gunTime'] = $performances[$supersedes]['time'];
            $row['gunTimeParsed'] = $performances[$supersedes]['timeParsed'];
            $performances[$key] = $this->mergeRows($performances[$supersedes], $row);
            unset($performances[$supersedes]);

            return $performances;
        }

        $performances[$key] = $this->mergeRows($performances[$key] ?? [], $row);

        return $performances;
    }

    /**
     * The chart row this grid row is a better copy of, or null.
     *
     * Same event, same day, same venue, and slower, because a chip time can
     * never be slower than the gun time for the same run. Where a meeting held
     * more than one round the closest match keeps each round paired with its
     * own row.
     */
    private function chartRowForSameRace(array $performances, array $row): ?string
    {
        $match = null;
        $closest = null;

        foreach ($performances as $key => $candidate) {
            if (($candidate['source'] ?? null) !== 'chart'
                || $candidate['event'] !== $row['event']
                || $candidate['date'] !== $row['date']
                || !$this->sameVenue($candidate['venue'], $row['venue'])) {
                continue;
            }

            $gap = $candidate['timeParsed'] - $row['timeParsed'];
            if ($gap <= 0) {
                continue;
            }

            if ($closest === null || $gap < $closest) {
                $closest = $gap;
                $match = $key;
            }
        }

        return $match;
    }

    /**
     * Overlay one row on another, leaving fields the newcomer has nothing for.
     *
     * The grid records no age group, so a plain array_merge would wipe the one
     * the charts supply and cost us the category for members whose date of
     * birth we do not hold.
     */
    private function mergeRows(array $existing, array $incoming): array
    {
        foreach ($incoming as $field => $value) {
            if ($value === null && array_key_exists($field, $existing)) {
                continue;
            }

            $existing[$field] = $value;
        }

        return $existing;
    }

    /**
     * The run a yearly best belongs to, or null.
     *
     * The venue names the race, and is the check that stops a year whose best
     * is missing from the per race charts having its time written onto some
     * other race. Do not assume the year's fastest run is the one to correct:
     * the yearly charts rank by chip time and the per race charts by gun time,
     * so a big city race with a long wait on the start line can be the year's
     * best while another run looks faster here. Take the closest run at that
     * venue which the chip time would speed up, since a chip time is never
     * slower than the gun time for the same run.
     */
    private function runForYearlyBest(array $performances, array $keys, array $best): ?string
    {
        $match = null;
        $closest = null;

        foreach ($keys as $key) {
            $row = $performances[$key];

            if (!$this->sameVenue($best['venue'], $row['venue'])) {
                continue;
            }

            $gap = $row['timeParsed'] - $best['seconds'];

            // The per race charts already hold a run at this time, so the year
            // was not chip timed at all and there is nothing here to correct.
            // Without this an athlete who raced the same venue twice would
            // have the year's best written onto their slower run as well.
            if (abs($gap) < 0.005) {
                return null;
            }

            if ($gap < 0) {
                continue;
            }

            if ($closest === null || $gap < $closest) {
                $closest = $gap;
                $match = $key;
            }
        }

        return $match;
    }

    private function sameVenue(?string $a, ?string $b): bool
    {
        if ($a === null || $b === null) {
            return false;
        }

        return strcasecmp(trim($a), trim($b)) === 0;
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
                    // Reformat rather than store it as written, because the
                    // grid runs the minutes past an hour ("84:42") where the
                    // charts roll them over ("1:24:42").
                    $mark = $result['perfchip'] ?: ($result['perf'] ?? '');
                    $seconds = $this->parseTime($mark);
                    if ($seconds === null) {
                        continue;
                    }

                    $rows[] = [
                        'event' => $event,
                        'rawEvent' => $result['evnt'] ?? null,
                        'date' => $date,
                        'timeParsed' => $seconds,
                        'time' => $this->formatSeconds($seconds),
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
     *
     * @return array<int, ?string> null where the array has a hole
     */
    private function jsStringArray(string $html, string $name): array
    {
        $body = $this->jsArrayBody($html, $name);
        if ($body === null) {
            return [];
        }

        $values = [];

        foreach ($this->jsArrayElements($body) as $i => $element) {
            $values[$i] = preg_match("/^'((?:[^'\\\\]|\\\\.)*)'$/s", $element, $m)
                ? stripslashes($m[1])
                : null;
        }

        return $values;
    }

    /**
     * @return array<int, ?float> null where the array has a hole
     */
    private function jsNumberArray(string $html, string $name): array
    {
        $body = $this->jsArrayBody($html, $name);
        if ($body === null) {
            return [];
        }

        $values = [];

        foreach ($this->jsArrayElements($body) as $i => $element) {
            $values[$i] = is_numeric($element) ? (float) $element : null;
        }

        return $values;
    }

    private function jsArrayBody(string $html, string $name): ?string
    {
        if (!preg_match('/(?:var|let)\s+' . preg_quote($name, '/') . '\s*=\s*\[(.*?)\];/s', $html, $m)) {
            return null;
        }

        return $m[1];
    }

    /**
     * Split a JavaScript array body into its elements, holes included.
     *
     * The yearly charts leave a hole for each year the athlete did not race,
     * as in "[115600,,117500]". Drop the hole and every later value shifts
     * onto the wrong year. Meeting names carry commas of their own
     * ("'Worcester, Worcs'"), so walk the body tracking whether we are inside
     * a quoted string rather than splitting on every comma.
     *
     * @return array<int, string> element source text, empty string for a hole
     */
    private function jsArrayElements(string $body): array
    {
        $elements = [];
        $current = '';
        $inString = false;
        $length = strlen($body);

        for ($i = 0; $i < $length; $i++) {
            $char = $body[$i];

            if ($inString) {
                $current .= $char;

                if ($char === '\\' && $i + 1 < $length) {
                    $current .= $body[++$i];
                } elseif ($char === "'") {
                    $inString = false;
                }

                continue;
            }

            if ($char === "'") {
                $inString = true;
                $current .= $char;
                continue;
            }

            if ($char === ',') {
                $elements[] = trim($current);
                $current = '';
                continue;
            }

            $current .= $char;
        }

        $elements[] = trim($current);

        // JavaScript reads a trailing comma as punctuation rather than a hole,
        // so "[1,2,]" holds two values and not three.
        if (end($elements) === '') {
            array_pop($elements);
        }

        return $elements;
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
