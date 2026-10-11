<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Models\ClubSession;
use App\Models\SessionSeries;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;

/**
 * 2026-10-13 tweaks: optional run length (has_end) and series images.
 * "Now" is Monday 2026-10-05 12:00Z (13:00 London).
 */
class AppRunsTweaksTest extends AppApiTestCase
{
    protected const S1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    protected const S2 = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    protected const X1 = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow(Carbon::parse('2026-10-05 12:00:00', 'UTC'));
        $this->member('u|committee', 1, ['committee'], 'active', 'Cath');
        $this->member('u|member', 2, [], 'active', 'Mo');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    protected function seriesBody(array $overrides = []): array
    {
        return $overrides + [
            'id' => self::S1,
            'title' => 'Monday club run',
            'weekday' => 1,
            'startTime' => '19:00',
            'durationMin' => 90,
            'validFrom' => '2026-01-01',
            'groupMode' => 'paced',
        ];
    }

    protected function adHocBody(array $overrides = []): array
    {
        return $overrides + [
            'id' => self::X1,
            'title' => 'Christmas social',
            'localDate' => '2026-12-20',
            'startTime' => '12:00',
            'durationMin' => 60,
            'groupMode' => 'open',
        ];
    }

    protected function without(array $body, string $key): array
    {
        unset($body[$key]);

        return $body;
    }

    protected function sessionOn(string $date): ClubSession
    {
        return ClubSession::where('local_date', $date)->firstOrFail();
    }

    protected function clearRuns(): void
    {
        ClubSession::withTrashed()->forceDelete();
        SessionSeries::withTrashed()->forceDelete();
    }

    protected function z($value): string
    {
        return Carbon::parse($value)->utc()->format('Y-m-d\TH:i:s\Z');
    }

    // ---- optional duration -----------------------------------------------

    public function testTimesHelperWithoutDurationUsesThreeHoursAndFlagsNoEnd()
    {
        $t = SessionGenerator::times('2026-10-12', '19:00', null, 'Europe/London');
        $this->assertFalse($t['has_end']);
        $this->assertSame('2026-10-12T21:00:00Z', $this->z($t['ends_at']));
        $this->assertSame('22:00', $t['local_end_time']);

        $t = SessionGenerator::times('2026-10-12', '19:00', 90, 'Europe/London');
        $this->assertTrue($t['has_end']);
        $this->assertSame('20:30', $t['local_end_time']);
    }

    public function testSeriesWithoutDurationCreatesSessionsWithoutAnEnd()
    {
        $variants = [$this->without($this->seriesBody(), 'durationMin'), $this->seriesBody(['durationMin' => null])];

        foreach ($variants as $i => $body) {
            $this->clearRuns();

            [$status, $series] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $body);
            $this->assertSame(201, $status, "variant $i");
            $this->assertNull($series['durationMin']);
            $this->assertSame(9, ClubSession::count());

            $row = $this->sessionOn('2026-10-12');
            $this->assertFalse($row->has_end);
            $this->assertSame('2026-10-12T21:00:00Z', $this->z($row->ends_at));

            [, $list] = $this->call_('GET', '/app/clubs/1/sessions?from=2026-10-12&to=2026-10-12', 'u|member');
            $this->assertNull($list['items'][0]['endsAt']);
            $this->assertNull($list['items'][0]['localEndTime']);
            $this->assertSame('19:00', $list['items'][0]['localStartTime']);
            $this->assertSame('2026-10-12T18:00:00Z', $list['items'][0]['startsAt']);
        }
    }

    public function testDurationStillValidatedWhenGiven()
    {
        foreach ([10, 601, 'abc'] as $bad) {
            $this->assertSame(422, $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['durationMin' => $bad]))[0], (string) $bad);
        }
        $this->assertSame(0, SessionSeries::count());

        $this->assertSame(422, $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['durationMin' => 14]))[0]);
        $this->assertSame(422, $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['durationMin' => 601]))[0]);
        $this->assertSame(0, ClubSession::count());
    }

    public function testChangingSeriesDurationRegeneratesBothWays()
    {
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->assertTrue($this->sessionOn('2026-10-12')->has_end);
        $this->assertSame('20:30', $this->sessionOn('2026-10-12')->local_end_time);

        // Remove the end: future non-detached runs lose it, still ending after 3 h internally.
        [$status, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['durationMin' => null]);
        $this->assertSame(200, $status);
        $this->assertNull($series['durationMin']);

        $row = $this->sessionOn('2026-10-12');
        $this->assertFalse($row->has_end);
        $this->assertSame('22:00', $row->local_end_time);
        $this->assertFalse((bool) $row->is_detached);

        // Give it one again.
        [, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['durationMin' => 60]);
        $this->assertSame(60, $series['durationMin']);
        $row = $this->sessionOn('2026-10-12');
        $this->assertTrue($row->has_end);
        $this->assertSame('20:00', $row->local_end_time);

        // Leaving durationMin out of a PATCH keeps it.
        [, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['title' => 'Renamed']);
        $this->assertSame(60, $series['durationMin']);
    }

    public function testSeriesDurationChangeSkipsDetachedSessions()
    {
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->sessionOn('2026-10-12')->update(['is_detached' => true]);

        $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['durationMin' => null]);

        $this->assertTrue($this->sessionOn('2026-10-12')->has_end);
        $this->assertFalse($this->sessionOn('2026-10-19')->has_end);
    }

    public function testAdHocSessionWithoutDurationAndPatchClearsOrKeeps()
    {
        [$status, $body] = $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->without($this->adHocBody(), 'durationMin'));
        $this->assertSame(201, $status);
        $this->assertNull($body['endsAt']);
        $this->assertNull($body['localEndTime']);
        $this->assertSame('12:00', $body['localStartTime']);
        $this->assertNull($body['imageUrl']);

        // Give it a length, keep it when the key is absent, then clear it with null.
        [, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['durationMin' => 45]);
        $this->assertSame('2026-12-20T12:45:00Z', $body['endsAt']);
        $this->assertSame('12:45', $body['localEndTime']);

        [, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['notes' => 'Bring a hat']);
        $this->assertSame('12:45', $body['localEndTime']);

        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['durationMin' => null]);
        $this->assertSame(200, $status);
        $this->assertNull($body['endsAt']);
        $this->assertNull($body['localEndTime']);
        $this->assertFalse(ClubSession::find(self::X1)->has_end);

        // Changing only the start time of a no-end run keeps it without an end.
        [, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['startTime' => '13:00']);
        $this->assertNull($body['endsAt']);
        $this->assertSame('13:00', $body['localStartTime']);
        $this->assertSame('2026-12-20T16:00:00Z', $this->z(ClubSession::find(self::X1)->ends_at));

        $this->assertSame(422, $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['durationMin' => 5])[0]);
    }

    public function testAdHocCreatedWithDurationHasAnEnd()
    {
        [, $body] = $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody());
        $this->assertSame('2026-12-20T13:00:00Z', $body['endsAt']);
        $this->assertSame('13:00', $body['localEndTime']);
        $this->assertTrue(ClubSession::find(self::X1)->has_end);
    }

    public function testPatchingEndOfASeriesRunDetachesItAndOriginalStaysSane()
    {
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $id = $this->sessionOn('2026-10-12')->id;

        // Clearing the end of a run whose series has one is a change the series controls: detach.
        [, $body] = $this->call_('PATCH', "/app/clubs/1/sessions/$id", 'u|committee', ['durationMin' => null]);
        $this->assertTrue($body['isDetached']);
        $this->assertNull($body['endsAt']);
        $this->assertNull($body['original']); // original lists start, venue and title only

        // A no-end series run edited with a note is not detached.
        $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['durationMin' => null]);
        $other = $this->sessionOn('2026-10-19')->id;
        [, $body] = $this->call_('PATCH', "/app/clubs/1/sessions/$other", 'u|committee', ['notes' => 'x']);
        $this->assertFalse($body['isDetached']);
        $this->assertNull($body['endsAt']);

        // Giving a no-end series run a length detaches it.
        [, $body] = $this->call_('PATCH', "/app/clubs/1/sessions/$other", 'u|committee', ['durationMin' => 60]);
        $this->assertTrue($body['isDetached']);
        $this->assertSame('20:00', $body['localEndTime']);
    }

    public function testNoEndRunIsNotPastUntilThreeHoursAfterStart()
    {
        $this->member('u|runner', 3, [], 'active', 'Rae');
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['durationMin' => null]));
        $id = $this->sessionOn('2026-10-12')->id;

        // 19:00 London is 18:00Z. 20:30Z (2.5 h after the start) is not past; a 90-minute run would be.
        Carbon::setTestNow(Carbon::parse('2026-10-12 20:30:00', 'UTC'));
        [$status] = $this->call_('POST', "/app/clubs/1/sessions/$id/groups", 'u|runner', ['lead' => true, 'label' => 'Walk']);
        $this->assertSame(201, $status);
        $this->assertFalse(ClubSession::find($id)->hasEnded());

        // 21:01Z is just over 3 h after the start: past.
        Carbon::setTestNow(Carbon::parse('2026-10-12 21:01:00', 'UTC'));
        [$status, $body] = $this->call_('POST', "/app/clubs/1/sessions/$id/groups", 'u|runner', ['lead' => true, 'label' => 'Walk']);
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);
        $this->assertTrue(ClubSession::find($id)->hasEnded());
    }

    // ---- series image ----------------------------------------------------

    public function testSeriesImageUrlValidation()
    {
        $good = ['http://example.com/a.jpg', 'https://example.com/a.jpg', 'https://' . str_repeat('a', 480) . '.com/x.png', null];

        foreach ($good as $i => $url) {
            $this->clearRuns();
            $this->assertSame(201, $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['imageUrl' => $url]))[0], "good $i");
        }

        $this->clearRuns();

        $bad = ['ftp://example.com/a.jpg', 'example.com/a.jpg', 'javascript:alert(1)', '/images/a.jpg', 'https://' . str_repeat('a', 500), 42];

        foreach ($bad as $i => $url) {
            [$status, $body] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['imageUrl' => $url]));
            $this->assertSame(422, $status, "bad $i");
            $this->assertSame('validation_failed', $body['error']);
            $this->assertArrayHasKey('imageUrl', $body['errors']);
        }
        $this->assertSame(0, SessionSeries::count());

        // PATCH validates the same way.
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['imageUrl' => 'ftp://x']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('imageUrl', $body['errors']);
    }

    public function testEmptyImageUrlIsStoredAsNull()
    {
        [, $series] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['imageUrl' => 'https://a.example/x.jpg']));
        $this->assertSame('https://a.example/x.jpg', $series['imageUrl']);

        [$status, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['imageUrl' => '']);
        $this->assertSame(200, $status);
        $this->assertNull($series['imageUrl']);
    }

    public function testImageUrlInSeriesAndSessionPayloadsAndPatchClears()
    {
        [, $series] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['imageUrl' => 'https://bpj.org.uk/img/monday.jpg']));
        $this->assertSame('https://bpj.org.uk/img/monday.jpg', $series['imageUrl']);

        [, $list] = $this->call_('GET', '/app/clubs/1/series', 'u|member');
        $this->assertSame('https://bpj.org.uk/img/monday.jpg', $list['items'][0]['imageUrl']);

        [, $list] = $this->call_('GET', '/app/clubs/1/sessions', 'u|member');
        $this->assertSame('https://bpj.org.uk/img/monday.jpg', $list['items'][0]['imageUrl']);

        // Ad-hoc runs have none.
        [, $adHoc] = $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody());
        $this->assertArrayHasKey('imageUrl', $adHoc);
        $this->assertNull($adHoc['imageUrl']);

        // Keep it when the key is absent, replace it, clear it.
        [, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['title' => 'Renamed']);
        $this->assertSame('https://bpj.org.uk/img/monday.jpg', $series['imageUrl']);

        [, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['imageUrl' => 'http://bpj.org.uk/img/new.jpg']);
        $this->assertSame('http://bpj.org.uk/img/new.jpg', $series['imageUrl']);

        [, $series] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['imageUrl' => null]);
        $this->assertNull($series['imageUrl']);
        [, $list] = $this->call_('GET', '/app/clubs/1/sessions?from=2026-10-12&to=2026-10-12', 'u|member');
        $this->assertNull($list['items'][0]['imageUrl']);

        // No imageUrl at all on creation: null.
        $this->clearRuns();
        [, $series] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->assertNull($series['imageUrl']);
    }

    public function testSessionsSinceAlsoReturnsRunsOfASeriesEditedSinceThen()
    {
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['id' => self::S2, 'title' => 'Tuesday', 'weekday' => 2]));
        $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody());
        $old = '2026-10-01 00:00:00';
        ClubSession::query()->update(['updated_at' => $old]);
        SessionSeries::query()->update(['updated_at' => $old]);
        $this->assertSame(9, ClubSession::where('series_id', self::S1)->count());

        // Edit only the Monday series' image straight in the database, as the committee will.
        Carbon::setTestNow(Carbon::parse('2026-10-05 12:30:00', 'UTC'));
        SessionSeries::where('id', self::S1)->update(['image_url' => 'https://bpj.org.uk/m.jpg', 'updated_at' => Carbon::now()]);
        // One of its runs also changed by itself (cancelled): it must appear once, not twice.
        $this->call_('POST', '/app/clubs/1/sessions/' . $this->sessionOn('2026-10-12')->id . '/cancel', 'u|committee', ['reason' => 'Wet']);
        // A deleted ad-hoc run is still a tombstone.
        $this->call_('DELETE', '/app/clubs/1/sessions/' . self::X1, 'u|committee');

        [$status, $body] = $this->call_('GET', '/app/clubs/1/sessions?since=2026-10-05T12:00:00Z', 'u|member');
        $this->assertSame(200, $status);
        $ids = array_column($body['items'], 'id');
        $this->assertSame(count($ids), count(array_unique($ids)));
        $this->assertCount(10, $ids); // nine Monday runs + the tombstone; no Tuesday run
        $this->assertContains(self::X1, $ids);

        foreach ($body['items'] as $item) {
            if ($item['seriesId'] === self::S1) {
                $this->assertSame('https://bpj.org.uk/m.jpg', $item['imageUrl']);
            }
            $this->assertNotSame('Tuesday', $item['title']);
        }

        // Ordered by the run's own updated_at, then id: untouched runs (old) come before the changed ones.
        $updated = array_column($body['items'], 'updatedAt');
        $sorted = $updated;
        sort($sorted);
        $this->assertSame($sorted, $updated);

        // A `since` after the edit returns nothing for the series.
        [, $body] = $this->call_('GET', '/app/clubs/1/sessions?since=2026-10-05T12:31:00Z', 'u|member');
        $this->assertSame([], $body['items']);
    }
}
