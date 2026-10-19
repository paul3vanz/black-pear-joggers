<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\SessionSeries;

/**
 * "Runs I follow" (D117): GET/PUT /follows, the bulk write with Undo, members not yet migrated,
 * and the endpoints older app versions still call (notification settings, days I run).
 */
class AppFollowsTest extends AppGroupsBase
{
    private $mon;
    private $thu1;
    private $thu2;

    protected function setUp(): void
    {
        parent::setUp();

        $this->mon = $this->series('Monday club run', 1, '19:00');
        $this->thu1 = $this->series('The Mug Run', 4, '18:30');
        $this->thu2 = $this->series('Thursday Perdiswell', 4, '19:00');
    }

    private function series(string $title, int $weekday, string $hm, string $mode = 'paced'): SessionSeries
    {
        return SessionSeries::create([
            'club_id' => 1, 'title' => $title, 'weekday' => $weekday, 'start_time' => $hm, 'duration_min' => 60,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => $mode,
        ]);
    }

    /** series id => mode from GET /follows */
    private function modes(string $sub): array
    {
        [, $body] = $this->api('GET', '/follows', $sub);

        return array_column($body['series'], 'mode', 'seriesId');
    }

    public function testEverySeriesStartsOnAutoInWeekOrder()
    {
        [$status, $body] = $this->api('GET', '/follows', 'plain');

        $this->assertSame(200, $status);
        $this->assertSame(['Monday club run', 'The Mug Run', 'Thursday Perdiswell'], array_column($body['series'], 'title'));
        $this->assertSame([
            'seriesId' => $this->thu1->id, 'title' => 'The Mug Run', 'weekday' => 4, 'localStartTime' => '18:30',
            'groupMode' => 'paced', 'mode' => 'auto', 'usuallyComes' => false, 'followed' => false,
        ], $body['series'][1]);
        $this->assertSame(0, MemberSeriesPref::count());
    }

    public function testSetOneSeries()
    {
        [$status, $body] = $this->api('PUT', "/follows/{$this->thu2->id}", 'plain', ['mode' => 'hide']);
        $this->assertSame(200, $status);
        $this->assertSame([$this->thu2->id, 'hide', false], [$body['seriesId'], $body['mode'], $body['followed']]);

        [, $body] = $this->api('PUT', "/follows/{$this->thu1->id}", 'plain', ['mode' => 'follow']);
        $this->assertSame(['follow', true], [$body['mode'], $body['followed']]);

        $this->assertSame([$this->mon->id => 'auto', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $this->modes('plain'));
        $this->assertSame('auto', $this->modes('leaderA')[$this->thu2->id]); // per member

        // The same write again changes nothing (safe to retry).
        $before = MemberSeriesPref::orderBy('series_id')->get(['series_id', 'mode', 'updated_at'])->toArray();
        $this->tick();
        $this->api('PUT', "/follows/{$this->thu1->id}", 'plain', ['mode' => 'follow']);
        $this->assertSame($before, MemberSeriesPref::orderBy('series_id')->get(['series_id', 'mode', 'updated_at'])->toArray());
    }

    public function testSetOneValidates()
    {
        [$status, $body] = $this->api('PUT', "/follows/{$this->mon->id}", 'plain', ['mode' => 'always']);
        $this->assertSame(422, $status);
        $this->assertSame('validation_failed', $body['error']);
        [$status] = $this->api('PUT', "/follows/{$this->mon->id}", 'plain', []);
        $this->assertSame(422, $status);

        [$status, $body] = $this->api('PUT', '/follows/00000000-0000-4000-8000-000000000000', 'plain', ['mode' => 'follow']);
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);

        // A deleted series is not found either.
        $this->mon->delete();
        [$status] = $this->api('PUT', "/follows/{$this->mon->id}", 'plain', ['mode' => 'follow']);
        $this->assertSame(404, $status);
        $this->assertSame(0, MemberSeriesPref::count());
    }

    public function testFollowAllReturnsThePreviousModesAndUndoRestoresThem()
    {
        $this->api('PUT', "/follows/{$this->thu2->id}", 'plain', ['mode' => 'hide']);
        $this->api('PUT', "/follows/{$this->mon->id}", 'plain', ['mode' => 'follow']);

        // Follow all on Thursday: only Thursday's series.
        [$status, $body] = $this->api('PUT', '/follows', 'plain', ['seriesIds' => [$this->thu1->id, $this->thu2->id], 'mode' => 'follow']);
        $this->assertSame(200, $status);
        $this->assertEquals([$this->thu1->id => 'auto', $this->thu2->id => 'hide'], $body['previous']);
        $this->assertSame(['follow', 'follow', 'follow'], array_column($body['series'], 'mode'));

        // Follow everything, then Undo with the previous modes.
        $this->api('PUT', "/follows/{$this->thu2->id}", 'plain', ['mode' => 'hide']);
        [, $body] = $this->api('PUT', '/follows', 'plain', ['seriesIds' => [$this->mon->id, $this->thu1->id, $this->thu2->id], 'mode' => 'follow']);
        $previous = $body['previous'];
        $this->assertEquals([$this->mon->id => 'follow', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $previous);

        [$status, $body] = $this->api('PUT', '/follows', 'plain', ['modes' => $previous]);
        $this->assertSame(200, $status);
        $this->assertSame([$this->mon->id => 'follow', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $this->modes('plain'));
    }

    public function testBulkWritesSaveNothingWhenAnyPartIsBad()
    {
        $other = $this->series('Gone', 2, '19:00');
        $other->delete();

        foreach ([
            ['seriesIds' => [$this->mon->id, $other->id], 'mode' => 'follow'],
            ['seriesIds' => [$this->mon->id], 'mode' => 'always'],
            ['seriesIds' => [$this->mon->id]],
            ['modes' => [$this->mon->id => 'follow', $this->thu1->id => 'nope']],
            ['modes' => 'follow'],
            [],
        ] as $body) {
            [$status, $res] = $this->api('PUT', '/follows', 'plain', $body);
            $this->assertSame(422, $status, json_encode($body));
            $this->assertSame('validation_failed', $res['error']);
        }
        $this->assertSame(0, MemberSeriesPref::count());

        // An empty list is fine and changes nothing.
        [$status, $res] = $this->api('PUT', '/follows', 'plain', ['seriesIds' => [], 'mode' => 'follow']);
        $this->assertSame(200, $status);
        $this->assertEquals([], (array) $res['previous']);
    }

    public function testUsuallyComesDrivesAuto()
    {
        $last = $this->session(['date' => '2026-10-05', 'series_id' => $this->mon->id]);
        $this->attend($last, $this->plain, 'going');
        $this->attend($last, $this->leaderA, 'maybe'); // maybe is not "came"

        [, $body] = $this->api('GET', '/follows', 'plain');
        $this->assertSame([true, true], [$body['series'][0]['usuallyComes'], $body['series'][0]['followed']]);
        [, $body] = $this->api('GET', '/follows', 'leaderA');
        $this->assertSame([false, false], [$body['series'][0]['usuallyComes'], $body['series'][0]['followed']]);

        // Hide wins over history.
        [, $row] = $this->api('PUT', "/follows/{$this->mon->id}", 'plain', ['mode' => 'hide']);
        $this->assertSame([true, false], [$row['usuallyComes'], $row['followed']]);
    }

    public function testEventsHaveNoUsuallyComes()
    {
        $parkrun = $this->series('parkrun tourism', 6, '09:00', 'events');
        $last = $this->session(['date' => '2026-10-10', 'series_id' => $parkrun->id, 'group_mode' => 'events']);
        $this->attend($last, $this->plain, 'going');

        [, $body] = $this->api('GET', '/follows', 'plain');
        $row = collect($body['series'])->firstWhere('seriesId', $parkrun->id);
        $this->assertSame(['events', false, false], [$row['groupMode'], $row['usuallyComes'], $row['followed']]);
    }

    public function testAMemberNotYetMigratedIsReadThroughTheMappingAndMigratedOnTheirFirstWrite()
    {
        // Old data: Never on Perdiswell, Thursday chosen as a run day, Monday not.
        MemberSeriesPref::create(['club_id' => 1, 'member_id' => $this->plain->id, 'series_id' => $this->thu2->id, 'reminders' => 'off']);
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'pace_unit' => 'mi', 'run_days' => '4']);

        $this->assertSame([$this->mon->id => 'auto', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $this->modes('plain'));
        $this->assertNull(MemberPreference::first()->follows_migrated_at);

        $this->api('PUT', "/follows/{$this->mon->id}", 'plain', ['mode' => 'follow']);

        $this->assertNotNull(MemberPreference::first()->follows_migrated_at);
        $this->assertSame([$this->mon->id => 'follow', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $this->modes('plain'));
        $this->assertSame('off', MemberSeriesPref::where('series_id', $this->thu2->id)->first()->reminders); // old value kept
        $this->assertSame('4', MemberPreference::first()->run_days);
    }

    // ---- older app versions ----------------------------------------------------------------

    public function testOldNotificationSettingsReadAndWriteTheModes()
    {
        $this->api('PUT', "/follows/{$this->thu1->id}", 'plain', ['mode' => 'follow']);
        $this->api('PUT', "/follows/{$this->thu2->id}", 'plain', ['mode' => 'hide']);

        [, $body] = $this->api('GET', '/notification-settings', 'plain');
        $this->assertSame(['auto', 'on', 'off'], array_column($body['series'], 'reminders'));

        $this->api('PUT', '/notification-settings', 'plain', ['series' => [$this->mon->id => 'off', $this->thu2->id => 'auto']]);
        $this->assertSame([$this->mon->id => 'hide', $this->thu1->id => 'follow', $this->thu2->id => 'auto'], $this->modes('plain'));
    }

    public function testOldDaysIRunFollowsTheAutoSeriesOnThoseDays()
    {
        $this->api('PUT', "/follows/{$this->thu2->id}", 'plain', ['mode' => 'hide']);

        [$status, $body] = $this->api('PUT', '/preferences', 'plain', ['runDays' => [4]]);
        $this->assertSame(200, $status);
        $this->assertSame([4], $body['runDays']); // still stored for the old app's own filter

        // Thursday's auto series is followed, the hidden one stays hidden, Monday is untouched.
        $this->assertSame([$this->mon->id => 'auto', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $this->modes('plain'));

        // Show every day (null) writes no modes.
        $this->api('PUT', '/preferences', 'plain', ['runDays' => null]);
        $this->assertSame([$this->mon->id => 'auto', $this->thu1->id => 'follow', $this->thu2->id => 'hide'], $this->modes('plain'));
    }
}
