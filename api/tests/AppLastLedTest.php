<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubSession;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Services\SessionGenerator;

/**
 * D127: the group a member last led, for the lead form on a phone with no local history.
 */
class AppLastLedTest extends AppGroupsBase
{
    /** @var SessionSeries */
    private $monday;
    /** @var SessionSeries */
    private $thursday;

    protected function setUp(): void
    {
        parent::setUp();

        $series = fn (string $title, int $weekday) => SessionSeries::create([
            'club_id' => 1, 'title' => $title, 'weekday' => $weekday, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
        $this->monday = $series('Monday club run', 1);
        $this->thursday = $series('Thursday run', 4);
    }

    private function led(?SessionSeries $series, string $date, int $from, ?int $to, string $label, string $status = 'confirmed', string $kind = 'run'): void
    {
        $session = $this->session(['date' => $date, 'series_id' => $series ? $series->id : null, 'occurrence_date' => $series ? $date : null, 'title' => $series ? $series->title : 'Ad hoc']
            + SessionGenerator::times($date, '19:00', 90, 'Europe/London'));
        $group = $this->group($session, [], [
            'label' => $label, 'kind' => $kind, 'status' => 'active', 'description' => 'Hills',
            'pace_unit' => 'mi', 'pace_from_s' => $from, 'pace_to_s' => $to, 'distance_value' => 6, 'distance_unit' => 'mi',
        ]);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $group->id, 'member_id' => $this->leaderA->id, 'status' => $status]);
    }

    private function lastLed(?string $query = '', string $sub = 'leaderA'): array
    {
        return $this->api('GET', '/members/me/last-led' . $query, $sub);
    }

    public function testNothingWhenTheMemberNeverLed()
    {
        [$status, $body] = $this->lastLed();

        $this->assertSame(200, $status);
        $this->assertSame(['group' => null], $body);
        $this->assertSame(401, $this->api('GET', '/members/me/last-led', null)[0]);
    }

    public function testTheLatestGroupWithItsPaceAndDistance()
    {
        $this->led($this->monday, '2026-09-21', 600, null, 'Old');
        $this->led($this->monday, '2026-10-05', 555, 570, 'Steady nines');

        [, $body] = $this->lastLed();

        $this->assertSame([
            'kind' => 'run', 'label' => 'Steady nines', 'description' => 'Hills',
            'paceUnit' => 'mi', 'paceFromS' => 555, 'paceToS' => 570, 'distanceValue' => 6, 'distanceUnit' => 'mi',
            'sessionTitle' => 'Monday club run', 'ledOn' => '2026-10-05', 'sameSeries' => false,
        ], $body['group']);
    }

    public function testASeriesIsPreferredAndOtherwiseAnyRunWillDo()
    {
        $this->led($this->thursday, '2026-09-24', 630, null, 'Thursday tens');
        $this->led($this->monday, '2026-10-05', 555, null, 'Monday nines');

        $thursday = $this->lastLed('?seriesId=' . $this->thursday->id)[1]['group'];
        $this->assertSame('Thursday tens', $thursday['label']);
        $this->assertTrue($thursday['sameSeries']);

        // Never led the Mug Run: fall back to the latest anywhere, and say it is another series.
        $mug = SessionSeries::create([
            'club_id' => 1, 'title' => 'Mug Run', 'weekday' => 4, 'start_time' => '19:00', 'duration_min' => 60,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
        $other = $this->lastLed('?seriesId=' . $mug->id)[1]['group'];
        $this->assertSame('Monday nines', $other['label']);
        $this->assertFalse($other['sameSeries']);
    }

    public function testWithdrawnSignUpsAndOtherMembersGroupsDoNotCount()
    {
        $this->led($this->monday, '2026-10-05', 555, null, 'Withdrew', 'withdrawn');
        $this->assertNull($this->lastLed()[1]['group']);

        $this->led($this->monday, '2026-09-28', 570, null, 'Led it');
        $this->assertSame('Led it', $this->lastLed()[1]['group']['label']);

        $this->assertNull($this->lastLed('', 'leaderB')[1]['group']);
    }

    public function testAGroupThatWasSinceDeletedStillTellsTheirPace()
    {
        $this->led($this->monday, '2026-10-05', 555, null, 'Gone');
        \App\Models\SessionGroup::query()->first()->delete();

        $this->assertSame(555, $this->lastLed()[1]['group']['paceFromS']);
    }
}
