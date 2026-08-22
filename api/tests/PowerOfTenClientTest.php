<?php

use App\Services\PowerOfTenClient;
use PHPUnit\Framework\TestCase as BaseTestCase;

/**
 * Parsing tests for the Power of 10 scraper, run against a saved copy of a real
 * athlete page (tests/fixtures/po10-athlete.html.gz).
 *
 * The parsing is the fragile part: it reads JavaScript literals out of a page
 * we do not control. If Power of 10 change their markup again these tests are
 * what should fail first, rather than the nightly cron quietly writing nothing.
 *
 * Expected values below were cross checked against what the site itself renders
 * for this athlete (best known performances tables and the handicap chart).
 */
class PowerOfTenClientTest extends BaseTestCase
{
    private static string $html;

    /**
     * A second real athlete, kept because their charts are riddled with the
     * holes that mark a year without racing, and because the grid and the
     * charts disagree about one of their races.
     */
    private static string $sparseHtml;

    private PowerOfTenClient $client;

    public static function setUpBeforeClass(): void
    {
        $path = __DIR__ . '/fixtures/po10-athlete.html.gz';
        self::$html = gzdecode(file_get_contents($path));

        $sparse = __DIR__ . '/fixtures/po10-athlete-sparse.html.gz';
        self::$sparseHtml = gzdecode(file_get_contents($sparse));
    }

    protected function setUp(): void
    {
        $this->client = new PowerOfTenClient();
    }

    public function testParsesProfileIncludingLegacyAthleteId()
    {
        $profile = $this->client->parseProfile(self::$html);

        // Athletes with a photo expose their old integer id as the image name,
        // which is what our athletes.athlete_id column holds.
        $this->assertSame(450606, $profile['legacyAthleteId']);
        $this->assertSame('Black Pear Joggers', $profile['club']);
        $this->assertSame('V40', $profile['ageGroup']);
    }

    public function testGridDataIsEmbeddedInThePageAndNotBlockedByRecaptcha()
    {
        $grid = $this->client->parseGridData(self::$html);

        // The whole approach rests on this: the payload the reCAPTCHA gated
        // endpoint would return is already in the page, marked OK.
        $this->assertNotNull($grid);
        $this->assertSame('OK', $grid['status']);
        $this->assertArrayHasKey('Full', $grid['perfs']['dictpgs']);
    }

    public function testParsesFullHistoryAcrossEveryYear()
    {
        $performances = $this->client->parsePerformances(self::$html);

        $this->assertCount(471, $performances);

        // Sorted oldest first, spanning the athlete's whole career.
        $this->assertSame('2012-05-19', $performances[0]['date']);
        $this->assertSame('2026-01-31', end($performances)['date']);
    }

    public function testParsesAKnownPerformanceCorrectly()
    {
        $performances = $this->client->parsePerformances(self::$html);

        $latest = end($performances);

        $this->assertSame('parkrun', $latest['event']);
        $this->assertSame('24:01', $latest['time']);
        $this->assertSame(1441.0, $latest['timeParsed']);
        $this->assertSame('Worcester parkrun # 695', $latest['meeting']);
        // Grid rows carry the meeting GUID; chart-only rows do not.
        $this->assertSame('40b2522e-08a7-4023-b815-46b409331dd4', $latest['po10MeetingId']);
    }

    public function testPrefersTheChipTimeForEachYearsFastestRun()
    {
        $performances = $this->client->parsePerformances(self::$html);

        $alcester = $this->performanceOn($performances, '2018-10-07', '10K');

        // The progression chart publishes 38:25, the gun time. The site itself
        // shows 38:23 with the gun time in brackets after it.
        $this->assertSame('38:23', $alcester['time']);
        $this->assertSame(2303.0, $alcester['timeParsed']);
        $this->assertSame('38:25', $alcester['gunTime']);
    }

    public function testOnlyCorrectsRunsTheYearlyChartsPublishAChipTimeFor()
    {
        $performances = $this->client->parsePerformances(self::$html);

        $corrected = array_filter($performances, fn($p) => isset($p['gunTimeParsed']));

        // One per event per year that the athlete raced, and no more: the
        // yearly charts only publish a chip time for each year's best run.
        $this->assertCount(17, $corrected);

        foreach ($corrected as $performance) {
            // A chip time can never be slower than the gun time for the run.
            $this->assertLessThan($performance['gunTimeParsed'], $performance['timeParsed']);
            // And it must have been the same race, which the venue proves.
            $this->assertNotNull($performance['venue']);
        }
    }

    public function testCorrectingChipTimesDoesNotDuplicateOrLosePerformances()
    {
        $performances = $this->client->parsePerformances(self::$html);

        $this->assertCount(471, $performances);

        // Rewriting a time changes the key the row is stored under, so this
        // guards against a corrected run reappearing alongside its old self.
        $slots = [];
        foreach ($performances as $performance) {
            $slots[$performance['event'] . '|' . $performance['date']][] = $performance['time'];
        }

        $shared = array_filter($slots, fn($times) => count($times) > 1);

        // New Year's Day 2020, two different parkruns. Nothing else doubles up.
        $this->assertSame(['parkrun|2020-01-01'], array_keys($shared));
    }

    private function performanceOn(array $performances, string $date, string $event): array
    {
        foreach ($performances as $performance) {
            if ($performance['date'] === $date && $performance['event'] === $event) {
                return $performance;
            }
        }

        $this->fail(sprintf('no %s performance on %s', $event, $date));
    }

    public function testCrossCountryComesFromTheGridBecauseItIsNotCharted()
    {
        $events = array_column($this->client->parsePerformances(self::$html), 'event');

        // The progression charts omit cross country and race walks, so these
        // can only arrive via the embedded grid payload.
        $this->assertContains('10KXC', $events);
        $this->assertContains('2000W', $events);
    }

    public function testMapsEventNamesOntoOurExistingEventAliases()
    {
        $events = array_column($this->client->parsePerformances(self::$html), 'event');

        // The personal best query joins events.alias, so "Half Marathon" from
        // the site has to become "HM" the way the old scraper stored it.
        $this->assertContains('HM', $events);
        $this->assertContains('Mar', $events);
        $this->assertContains('1M', $events);
        $this->assertNotContains('Half Marathon', $events);
    }

    public function testDoesNotStoreFieldEventsAsTimes()
    {
        // A 12.13m triple jump read as a time would poison the PB calculation.
        foreach ($this->client->parsePerformances(self::$html) as $performance) {
            $this->assertGreaterThan(
                0,
                $performance['timeParsed'],
                'every stored performance must be a time'
            );
        }
    }

    public function testParsesTheHandicapHistoryThatReplacesRunBritain()
    {
        $rankings = $this->client->parseRankings(self::$html);

        $this->assertCount(179, $rankings);

        // Pages are pushed newest block first, so the parser has to pair them
        // per page and re-sort. This asserts that ordering is right.
        $this->assertSame('2013-05-12', $rankings[0]['date']);
        $this->assertSame('2026-08-15', end($rankings)['date']);
        $this->assertSame(16.3, end($rankings)['ranking']);
    }

    /**
     * @dataProvider timeProvider
     */
    public function testParsesTimes(string $input, ?float $expected)
    {
        $this->assertSame($expected, $this->client->parseTime($input));
    }

    public static function timeProvider(): array
    {
        return [
            'minutes and seconds' => ['24:01', 1441.0],
            'hours minutes seconds' => ['2:57:14', 10634.0],
            'seconds only' => ['16.6', 16.6],
            'hundredths' => ['81.87', 81.87],
            'empty' => ['', null],
        ];
    }

    /**
     * @dataProvider formatProvider
     */
    public function testFormatsSeconds(float $input, string $expected)
    {
        $this->assertSame($expected, $this->client->formatSeconds($input));
    }

    public static function formatProvider(): array
    {
        return [
            'under an hour' => [1441.0, '24:01'],
            'over an hour' => [10634.0, '2:57:14'],
            'keeps hundredths' => [160.30, '2:40.30'],
        ];
    }

    public function testKeepsChartYearsAlignedAcrossYearsWithoutRacing()
    {
        $performances = $this->client->parsePerformances(self::$sparseHtml);

        // Their 5K yearly chart reads [115600,,117500,114500] against the
        // labels 2023 to 2026: a hole for 2024, then 19:35 in 2025 and 19:05
        // in 2026. Collapse the hole and every later year shifts back one, so
        // 2026's chip time lands on the 2025 race instead.
        $race = $this->performanceOn($performances, '2026-05-22', '5K');

        $this->assertSame('19:05', $race['time']);
        $this->assertSame('20:08', $race['gunTime']);
    }

    public function testTheGridReplacesTheChartRowForARaceRatherThanAddingOne()
    {
        $performances = $this->client->parsePerformances(self::$sparseHtml);

        // The charts publish 20:08 for this race and the grid 19:05. Storing
        // both is what put the same run on the club standards table twice.
        $matches = array_filter(
            $performances,
            fn($row) => $row['event'] === '5K' && $row['date'] === '2026-05-22'
        );

        $this->assertCount(1, $matches);
    }

    public function testNoRaceIsHeldAtTwoDifferentTimesAtOnce()
    {
        foreach ([self::$html, self::$sparseHtml] as $html) {
            $sources = [];

            foreach ($this->client->parsePerformances($html) as $row) {
                $slot = $row['event'] . '|' . $row['date'] . '|' . $row['venue'];
                $sources[$slot][] = $row['source'];
            }

            foreach ($sources as $slot => $found) {
                // Two runs can share an event, a day and a venue, but they
                // cannot come one from each source: that is the same run read
                // twice, once at the chip time and once at the gun time.
                $this->assertLessThan(
                    2,
                    count(array_unique($found)),
                    "{$slot} was read from both the charts and the grid"
                );
            }
        }
    }

    public function testGridTimesAreWrittenTheSameWayAsChartTimes()
    {
        $performances = $this->client->parsePerformances(self::$sparseHtml);

        foreach ($performances as $row) {
            if ($row['timeParsed'] < 3600) {
                continue;
            }

            // The grid runs the minutes past an hour, so a 1:24:42 half
            // marathon arrives as "84:42" and would sort and read wrongly
            // alongside everything the charts supply.
            $this->assertMatchesRegularExpression(
                '/^\d+:[0-5]\d:[0-5]\d(\.\d\d)?$/',
                $row['time'],
                "{$row['event']} on {$row['date']}"
            );
        }
    }

    public function testTheGridDoesNotWipeTheAgeGroupTheChartsSupply()
    {
        $performances = $this->client->parsePerformances(self::$sparseHtml);

        // The grid records no age group. Letting its blank win costs us the
        // category for every member whose date of birth we do not hold.
        $race = $this->performanceOn($performances, '2026-05-22', '5K');

        $this->assertSame('V60', $race['ageGroup']);
    }

    public function testNormalisesEventNames()
    {
        $this->assertSame('HM', $this->client->normaliseEvent('Half Marathon'));
        $this->assertSame('HM', $this->client->normaliseEvent('Half_Marathon'));
        $this->assertSame('Mar', $this->client->normaliseEvent('Marathon'));
        $this->assertSame('parkrun', $this->client->normaliseEvent('parkrun'));
        // Unknown events pass through so nothing is silently dropped.
        $this->assertSame('10KXC', $this->client->normaliseEvent('10KXC'));
    }
}
