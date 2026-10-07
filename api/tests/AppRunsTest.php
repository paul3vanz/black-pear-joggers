<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\SessionSeries;
use App\Models\Venue;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Phase 3: club runs (venues, series, sessions) and the session generator.
 * "Today" is pinned for the generator with an explicit Carbon argument and, for
 * the endpoints, with Carbon::setTestNow.
 */
class AppRunsTest extends AppApiTestCase
{
    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    protected function series(array $overrides = []): SessionSeries
    {
        return SessionSeries::create($overrides + [
            'club_id' => 1,
            'title' => 'Monday club run',
            'weekday' => 1,
            'start_time' => '19:00',
            'duration_min' => 90,
            'interval_weeks' => 1,
            'valid_from' => '2026-01-01',
            'valid_until' => null,
            'group_mode' => 'paced',
        ]);
    }

    protected function generator(): SessionGenerator
    {
        return new SessionGenerator();
    }

    protected function london(string $when): Carbon
    {
        return Carbon::parse($when, 'Europe/London');
    }

    /** Local dates (Y-m-d) of the series' live sessions, sorted. */
    protected function dates(SessionSeries $series): array
    {
        return ClubSession::where('series_id', $series->id)->orderBy('local_date')->pluck('local_date')
            ->map(function ($d) {
                return substr($d, 0, 10);
            })->all();
    }

    protected function utc($value): string
    {
        return Carbon::parse($value)->utc()->format('Y-m-d\TH:i:s\Z');
    }

    // ---- generator -------------------------------------------------------

    public function testGeneratesWeeklySessionsWithinEightWeeks()
    {
        $series = $this->series();

        // Monday 2026-10-05 is today: Mondays 5 Oct .. 30 Nov (today + 56 days) inclusive.
        $stats = $this->generator()->generateForSeries($series, $this->london('2026-10-05 12:00'));

        $this->assertSame(9, $stats['created']);
        $this->assertSame([
            '2026-10-05', '2026-10-12', '2026-10-19', '2026-10-26', '2026-11-02',
            '2026-11-09', '2026-11-16', '2026-11-23', '2026-11-30',
        ], $this->dates($series));

        $first = ClubSession::where('series_id', $series->id)->orderBy('local_date')->first();
        $this->assertSame('Monday club run', $first->title);
        $this->assertSame('19:00', $first->local_start_time);
        $this->assertSame('20:30', $first->local_end_time);
        $this->assertSame('paced', $first->group_mode);
        $this->assertSame('scheduled', $first->status);
        $this->assertFalse($first->is_detached);
    }

    public function testTimesAreDstSafe()
    {
        $series = $this->series();
        $this->generator()->generateForSeries($series, $this->london('2026-10-19 12:00'));

        $byDate = ClubSession::where('series_id', $series->id)->get()->keyBy(function ($s) {
            return substr($s->local_date, 0, 10);
        });

        // Clocks go back on Sunday 2026-10-25: BST (UTC+1) before, GMT after.
        $this->assertSame('2026-10-19T18:00:00Z', $this->utc($byDate['2026-10-19']->starts_at));
        $this->assertSame('2026-10-19T19:30:00Z', $this->utc($byDate['2026-10-19']->ends_at));
        $this->assertSame('2026-10-26T19:00:00Z', $this->utc($byDate['2026-10-26']->starts_at));
        $this->assertSame('19:00', $byDate['2026-10-26']->local_start_time);
        $this->assertSame('20:30', $byDate['2026-10-26']->local_end_time);
    }

    public function testTodayIsClubLocalNotUtc()
    {
        $series = $this->series(['weekday' => 2]); // Tuesday

        // 23:30Z on Monday 2026-06-01 is 00:30 Tuesday in London (BST): today is already Tuesday.
        $this->generator()->generateForSeries($series, Carbon::parse('2026-06-01 23:30', 'UTC'));

        $this->assertSame('2026-06-02', $this->dates($series)[0]);
    }

    public function testIntervalWeeksCountsFromTheWeekOfValidFrom()
    {
        // valid_from is a Wednesday (2026-09-30); its week starts Monday 2026-09-28.
        $series = $this->series(['interval_weeks' => 2, 'valid_from' => '2026-09-30']);

        $this->generator()->generateForSeries($series, $this->london('2026-10-01 12:00'));

        // Mondays in weeks 0, 2, 4...: 28 Sep is before valid_from, so 12 Oct, 26 Oct, 9 Nov, 23 Nov.
        $this->assertSame(['2026-10-12', '2026-10-26', '2026-11-09', '2026-11-23'], $this->dates($series));
    }

    public function testRespectsValidFromAndValidUntil()
    {
        $series = $this->series(['valid_from' => '2026-10-12', 'valid_until' => '2026-11-02']);

        $this->generator()->generateForSeries($series, $this->london('2026-10-05 12:00'));

        $this->assertSame(['2026-10-12', '2026-10-19', '2026-10-26', '2026-11-02'], $this->dates($series));
    }

    public function testRerunIsIdempotentAndDoesNotTouchUpdatedAt()
    {
        $series = $this->series();
        $today = $this->london('2026-10-05 12:00');
        $this->generator()->generateForSeries($series, $today);

        ClubSession::query()->update(['updated_at' => '2026-01-01 00:00:00']);
        $stats = $this->generator()->generateForSeries($series, $today);

        $this->assertSame(['created' => 0, 'updated' => 0, 'restored' => 0, 'deleted' => 0], $stats);
        $this->assertSame(9, ClubSession::count());
        $this->assertSame(0, ClubSession::where('updated_at', '>', '2026-01-02')->count());
    }

    public function testSeriesChangesUpdateNonDetachedSessionsButKeepNotesAndCoordinator()
    {
        $series = $this->series();
        $today = $this->london('2026-10-05 12:00');
        $this->generator()->generateForSeries($series, $today);

        $member = $this->member('u|1', 1, [], 'active', 'Jo');
        $session = ClubSession::where('series_id', $series->id)->where('local_date', '2026-10-12')->first();
        $session->update(['notes' => 'Bring a torch', 'coordinator_member_id' => $member->id]);

        $venue = Venue::create(['club_id' => 1, 'name' => 'Pitchcroft']);
        $series->update(['title' => 'Monday run', 'start_time' => '18:30', 'venue_id' => $venue->id, 'group_mode' => 'open']);
        $stats = $this->generator()->generateForSeries($series->fresh(), $today);

        $this->assertSame(9, $stats['updated']);
        $session = $session->fresh();
        $this->assertSame('Monday run', $session->title);
        $this->assertSame('18:30', $session->local_start_time);
        $this->assertSame('20:00', $session->local_end_time);
        $this->assertSame($venue->id, $session->venue_id);
        $this->assertSame('open', $session->group_mode);
        $this->assertSame('Bring a torch', $session->notes);
        $this->assertSame($member->id, $session->coordinator_member_id);
    }

    public function testDetachedAndCancelledSessionsAreNeverTouched()
    {
        $series = $this->series();
        $today = $this->london('2026-10-05 12:00');
        $this->generator()->generateForSeries($series, $today);

        $moved = ClubSession::where('series_id', $series->id)->where('local_date', '2026-10-12')->first();
        $moved->update(['is_detached' => true, 'local_start_time' => '18:00', 'title' => 'Early start']);
        $cancelled = ClubSession::where('series_id', $series->id)->where('local_date', '2026-10-19')->first();
        $cancelled->update(['is_detached' => true, 'status' => 'cancelled', 'cancel_reason' => 'Bank holiday']);

        // Move the series to Tuesdays: every non-detached future Monday goes, detached ones stay.
        $series->update(['weekday' => 2, 'title' => 'Tuesday run']);
        $this->generator()->generateForSeries($series->fresh(), $today);

        $this->assertSame('Early start', $moved->fresh()->title);
        $this->assertSame('18:00', $moved->fresh()->local_start_time);
        $this->assertSame('cancelled', $cancelled->fresh()->status);
        $this->assertNull($cancelled->fresh()->deleted_at);

        $dates = $this->dates($series);
        $mondays = array_values(array_filter($dates, function ($d) {
            return Carbon::parse($d)->dayOfWeekIso === 1;
        }));
        $tuesdays = array_filter($dates, function ($d) {
            return Carbon::parse($d)->dayOfWeekIso === 2;
        });

        $this->assertSame(['2026-10-12', '2026-10-19'], $mondays);
        $this->assertSame('2026-10-06', $dates[0]);
        $this->assertCount(8, $tuesdays);
    }

    public function testRematchingDateRestoresTheSoftDeletedRowInsteadOfInserting()
    {
        $series = $this->series();
        $today = $this->london('2026-10-05 12:00');
        $this->generator()->generateForSeries($series, $today);
        $id = ClubSession::where('series_id', $series->id)->where('local_date', '2026-11-30')->value('id');

        $series->update(['valid_until' => '2026-11-29']);
        $stats = $this->generator()->generateForSeries($series->fresh(), $today);
        $this->assertSame(1, $stats['deleted']);
        $this->assertNull(ClubSession::find($id));

        $series->update(['valid_until' => null]);
        $stats = $this->generator()->generateForSeries($series->fresh(), $today);

        $this->assertSame(1, $stats['restored']);
        $this->assertSame(0, $stats['created']);
        $this->assertNotNull(ClubSession::find($id));
        $this->assertSame(9, ClubSession::withTrashed()->count());
    }

    public function testPastSessionsAreNeverChanged()
    {
        $series = $this->series();
        $this->generator()->generateForSeries($series, $this->london('2026-10-05 12:00'));
        $past = ClubSession::where('series_id', $series->id)->where('local_date', '2026-10-05')->first();

        // A fortnight later the 5 Oct run is past; renaming the series must not touch it.
        $series->update(['title' => 'Renamed']);
        $this->generator()->generateForSeries($series->fresh(), $this->london('2026-10-19 12:00'));
        $this->assertSame('Monday club run', $past->fresh()->title);

        // Deleting the series leaves past runs alone and removes only today-onwards ones.
        $series->delete();
        $this->generator()->generateForSeries($series->fresh(), $this->london('2026-10-19 12:00'));
        $this->assertNull($past->fresh()->deleted_at);
        $this->assertNull(ClubSession::where('local_date', '2026-10-12')->first()->deleted_at);
        $this->assertNull(ClubSession::where('local_date', '2026-10-19')->first());
    }

    public function testSoftDeletedSeriesRemovesFutureNonDetachedSessionsOnly()
    {
        $series = $this->series();
        $today = $this->london('2026-10-05 12:00');
        $this->generator()->generateForSeries($series, $today);
        $kept = ClubSession::where('series_id', $series->id)->where('local_date', '2026-10-12')->first();
        $kept->update(['is_detached' => true]);

        $series->delete();
        $stats = $this->generator()->generateAll($today);

        $this->assertSame(8, $stats['deleted']);
        $this->assertSame([$kept->id], ClubSession::pluck('id')->all());
    }

    // ---- endpoints -------------------------------------------------------

    protected const V1 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    protected const S1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    protected const X1 = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

    protected function setUpClubUsers(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-10-05 12:00:00', 'UTC')); // Monday, 13:00 in London
        $this->member('u|committee', 1, ['committee'], 'active', 'Cath');
        $this->member('u|member', 2, [], 'active', 'Mo');
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

    public function testMembersCanReadButNotWrite()
    {
        $this->setUpClubUsers();

        [$status, $body] = $this->call_('GET', '/app/clubs/1/venues', 'u|member');
        $this->assertSame(200, $status);
        $this->assertSame([], $body['items']);
        $this->assertArrayHasKey('serverTime', $body);
        $this->assertSame(200, $this->call_('GET', '/app/clubs/1/series', 'u|member')[0]);
        $this->assertSame(200, $this->call_('GET', '/app/clubs/1/sessions', 'u|member')[0]);

        $writes = [
            ['POST', '/app/clubs/1/venues', ['name' => 'X']],
            ['POST', '/app/clubs/1/series', $this->seriesBody()],
            ['POST', '/app/clubs/1/sessions', $this->adHocBody()],
        ];

        foreach ($writes as [$method, $uri, $data]) {
            [$status, $body] = $this->call_($method, $uri, 'u|member', $data);
            $this->assertSame(403, $status, $uri);
            $this->assertSame('forbidden', $body['error']);
        }

        $this->assertSame(401, $this->call_('GET', '/app/clubs/1/venues', null)[0]);
    }

    public function testVenueCreateIsIdempotentPatchAndDelete()
    {
        $this->setUpClubUsers();
        $data = ['id' => self::V1, 'name' => 'Pitchcroft', 'address' => 'Worcester', 'lat' => 52.19, 'lng' => -2.22];

        [$status, $body] = $this->call_('POST', '/app/clubs/1/venues', 'u|committee', $data);
        $this->assertSame(201, $status);
        $this->assertSame(self::V1, $body['id']);
        $this->assertSame(52.19, $body['lat']);
        $this->assertNull($body['notes']);
        $this->assertNull($body['deletedAt']);

        [$status] = $this->call_('POST', '/app/clubs/1/venues', 'u|committee', $data);
        $this->assertSame(200, $status);
        $this->assertSame(1, Venue::count());

        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/venues/' . self::V1, 'u|committee', ['notes' => 'Car park', 'lat' => null]);
        $this->assertSame(200, $status);
        $this->assertSame('Car park', $body['notes']);
        $this->assertNull($body['lat']);
        $this->assertSame('Pitchcroft', $body['name']);

        $this->assertSame(422, $this->call_('POST', '/app/clubs/1/venues', 'u|committee', ['name' => ''])[0]);
        $this->assertSame(404, $this->call_('PATCH', '/app/clubs/1/venues/' . self::X1, 'u|committee', ['name' => 'N'])[0]);
        $this->assertSame(403, $this->call_('PATCH', '/app/clubs/1/venues/' . self::V1, 'u|member', ['name' => 'N'])[0]);

        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/venues/' . self::V1, 'u|committee')[0]);
        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/venues/' . self::V1, 'u|committee')[0]);
        $this->assertSame(404, $this->call_('DELETE', '/app/clubs/1/venues/' . self::X1, 'u|committee')[0]);
        $this->assertSame([], $this->call_('GET', '/app/clubs/1/venues', 'u|member')[1]['items']);
    }

    public function testVenueInUseCannotBeDeleted()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/venues', 'u|committee', ['id' => self::V1, 'name' => 'Pitchcroft']);

        // Used by an active series.
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody(['venueId' => self::V1]));
        [$status, $body] = $this->call_('DELETE', '/app/clubs/1/venues/' . self::V1, 'u|committee');
        $this->assertSame(409, $status);
        $this->assertSame('in_use', $body['error']);

        // Series gone, but a future ad-hoc session still uses it.
        $this->call_('DELETE', '/app/clubs/1/series/' . self::S1, 'u|committee');
        $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['venueId' => self::V1]));
        $this->assertSame(409, $this->call_('DELETE', '/app/clubs/1/venues/' . self::V1, 'u|committee')[0]);

        $this->call_('DELETE', '/app/clubs/1/sessions/' . self::X1, 'u|committee');
        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/venues/' . self::V1, 'u|committee')[0]);
    }

    public function testSeriesCreateGeneratesSessionsAndIsIdempotent()
    {
        $this->setUpClubUsers();

        [$status, $body] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->assertSame(201, $status);
        $this->assertSame(1, $body['weekday']);
        $this->assertSame('19:00', $body['startTime']);
        $this->assertSame(1, $body['intervalWeeks']);
        $this->assertSame('2026-01-01', $body['validFrom']);
        $this->assertNull($body['validUntil']);
        $this->assertSame(9, ClubSession::count());

        [$status] = $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->assertSame(200, $status);
        $this->assertSame(9, ClubSession::count());
        $this->assertSame(1, SessionSeries::count());

        [, $body] = $this->call_('GET', '/app/clubs/1/sessions', 'u|member');
        $this->assertCount(9, $body['items']);
        $first = $body['items'][0];
        $this->assertSame('2026-10-05', $first['localDate']);
        $this->assertSame('2026-10-05T18:00:00Z', $first['startsAt']);
        $this->assertSame('2026-10-05T19:30:00Z', $first['endsAt']);
        $this->assertSame('20:30', $first['localEndTime']);
        $this->assertSame(self::S1, $first['seriesId']);
        $this->assertSame('2026-10-05', $first['occurrenceDate']);
        $this->assertNull($first['original']);
        $this->assertNull($first['coordinatorName']);
    }

    public function testSeriesValidation()
    {
        $this->setUpClubUsers();

        $bads = [
            ['weekday' => 8], ['weekday' => 0], ['startTime' => '7pm'], ['durationMin' => 10],
            ['durationMin' => 601], ['intervalWeeks' => 9], ['groupMode' => 'fast'],
            ['validFrom' => '2026-10-01', 'validUntil' => '2026-09-01'], ['venueId' => self::V1],
        ];

        foreach ($bads as $bad) {
            $this->assertSame(422, $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody($bad))[0], json_encode($bad));
        }

        $this->assertSame(0, SessionSeries::count());
    }

    public function testSeriesPatchRegeneratesAndDeleteRemovesFutureSessions()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());

        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['startTime' => '18:30', 'title' => 'Early run']);
        $this->assertSame(200, $status);
        $this->assertSame('18:30', $body['startTime']);
        $this->assertSame(9, ClubSession::count());
        $this->assertSame(9, ClubSession::where('local_start_time', '18:30')->where('title', 'Early run')->count());

        // Weekday change: Monday sessions replaced by Wednesday ones (2026-10-07 .. 2026-11-25).
        $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['weekday' => 3]);
        $this->assertSame(8, ClubSession::count());
        $this->assertSame(0, ClubSession::where('local_date', '2026-10-05')->count());

        $this->assertSame(422, $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['validUntil' => '2025-01-01'])[0]);
        $this->assertSame(403, $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|member', ['title' => 'x'])[0]);
        $this->assertSame(404, $this->call_('PATCH', '/app/clubs/1/series/' . self::X1, 'u|committee', ['title' => 'x'])[0]);

        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/series/' . self::S1, 'u|committee')[0]);
        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/series/' . self::S1, 'u|committee')[0]);
        $this->assertSame(0, ClubSession::count());
        $this->assertSame([], $this->call_('GET', '/app/clubs/1/series', 'u|member')[1]['items']);

        // With since the deleted series comes back as a tombstone.
        [, $body] = $this->call_('GET', '/app/clubs/1/series?since=2026-01-01T00:00:00Z', 'u|member');
        $this->assertCount(1, $body['items']);
        $this->assertNotNull($body['items'][0]['deletedAt']);
    }

    public function testPatchingASeriesSessionDetachesItAndFillsOriginal()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->call_('POST', '/app/clubs/1/venues', 'u|committee', ['id' => self::V1, 'name' => 'Pitchcroft']);
        $session = ClubSession::where('local_date', '2026-10-26')->first();

        // 2026-10-26 is after the clocks go back: 19:00 local is 19:00Z.
        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . $session->id, 'u|committee', [
            'startTime' => '18:00', 'venueId' => self::V1, 'title' => 'Bank holiday run', 'durationMin' => 60,
        ]);

        $this->assertSame(200, $status);
        $this->assertTrue($body['isDetached']);
        $this->assertSame('18:00', $body['localStartTime']);
        $this->assertSame('19:00', $body['localEndTime']);
        $this->assertSame('2026-10-26T18:00:00Z', $body['startsAt']);
        $this->assertSame('2026-10-26', $body['localDate']);
        $this->assertSame(self::V1, $body['venueId']);
        $this->assertSame(
            ['localStartTime' => '19:00', 'venueId' => null, 'title' => 'Monday club run'],
            $body['original']
        );

        // A series change leaves the detached run alone but moves the others.
        $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['startTime' => '20:00']);
        $this->assertSame('18:00', ClubSession::find($session->id)->local_start_time);
        $this->assertSame(8, ClubSession::where('local_start_time', '20:00')->count());

        // A series occurrence keeps its date.
        $this->assertSame(422, $this->call_('PATCH', '/app/clubs/1/sessions/' . $session->id, 'u|committee', ['localDate' => '2026-10-27'])[0]);
        $this->assertSame(404, $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['title' => 'x'])[0]);
        $this->assertSame(403, $this->call_('PATCH', '/app/clubs/1/sessions/' . $session->id, 'u|member', ['title' => 'x'])[0]);
    }

    public function testNotesAndCoordinatorEditsDoNotDetach()
    {
        $this->setUpClubUsers();
        $mo = ClubMember::where("athlete_id", 2)->first();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $session = ClubSession::where('local_date', '2026-10-12')->first();

        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . $session->id, 'u|committee', [
            'notes' => 'Hi-vis please', 'coordinatorMemberId' => $mo->id,
        ]);

        $this->assertSame(200, $status);
        $this->assertFalse($body['isDetached']);
        $this->assertNull($body['original']);
        $this->assertSame('Hi-vis please', $body['notes']);
        $this->assertSame($mo->id, $body['coordinatorMemberId']);
        $this->assertSame($mo->display_name, $body['coordinatorName']);

        $this->assertSame(422, $this->call_('PATCH', '/app/clubs/1/sessions/' . $session->id, 'u|committee', ['coordinatorMemberId' => self::X1])[0]);
    }

    public function testCancelAndRestoreDetachTheSession()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $session = ClubSession::where('local_date', '2026-10-12')->first();
        $uri = '/app/clubs/1/sessions/' . $session->id;

        [$status, $body] = $this->call_('POST', $uri . '/cancel', 'u|committee', ['reason' => 'Bank holiday']);
        $this->assertSame(200, $status);
        $this->assertSame('cancelled', $body['status']);
        $this->assertSame('Bank holiday', $body['cancelReason']);
        $this->assertTrue($body['isDetached']);

        $this->assertSame(403, $this->call_('POST', $uri . '/cancel', 'u|member', ['reason' => 'x'])[0]);
        $this->assertSame(404, $this->call_('POST', '/app/clubs/1/sessions/' . self::X1 . '/cancel', 'u|committee')[0]);

        // The generator leaves the cancelled run alone.
        $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['title' => 'Renamed']);
        $this->assertSame('cancelled', ClubSession::find($session->id)->status);
        $this->assertSame('Monday club run', ClubSession::find($session->id)->title);

        [$status, $body] = $this->call_('POST', $uri . '/restore', 'u|committee');
        $this->assertSame(200, $status);
        $this->assertSame('scheduled', $body['status']);
        $this->assertNull($body['cancelReason']);
        $this->assertTrue($body['isDetached']);
    }

    public function testAdHocSessionCreatePatchAndDelete()
    {
        $this->setUpClubUsers();

        [$status, $body] = $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody());
        $this->assertSame(201, $status);
        $this->assertNull($body['seriesId']);
        $this->assertNull($body['occurrenceDate']);
        $this->assertFalse($body['isDetached']);
        $this->assertNull($body['original']);
        // 2026-12-20 is GMT.
        $this->assertSame('2026-12-20T12:00:00Z', $body['startsAt']);
        $this->assertSame('13:00', $body['localEndTime']);

        $this->assertSame(200, $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody())[0]);
        $this->assertSame(1, ClubSession::count());

        // Ad-hoc runs can change date; the UTC instants follow (BST on 2027-04-04).
        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/sessions/' . self::X1, 'u|committee', ['localDate' => '2027-04-04', 'startTime' => '10:00']);
        $this->assertSame(200, $status);
        $this->assertSame('2027-04-04', $body['localDate']);
        $this->assertSame('2027-04-04T09:00:00Z', $body['startsAt']);
        $this->assertSame('11:00', $body['localEndTime']);
        $this->assertFalse($body['isDetached']);

        $this->assertSame(422, $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['id' => self::V1, 'groupMode' => 'x']))[0]);
        $this->assertSame(422, $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['id' => self::V1, 'localDate' => 'tomorrow']))[0]);

        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/sessions/' . self::X1, 'u|committee')[0]);
        $this->assertSame(204, $this->call_('DELETE', '/app/clubs/1/sessions/' . self::X1, 'u|committee')[0]);
        $this->assertSame(404, $this->call_('DELETE', '/app/clubs/1/sessions/' . self::V1, 'u|committee')[0]);
        $this->assertSame(403, $this->call_('DELETE', '/app/clubs/1/sessions/' . self::X1, 'u|member')[0]);
    }

    public function testSeriesSessionCannotBeDeleted()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $session = ClubSession::first();

        [$status, $body] = $this->call_('DELETE', '/app/clubs/1/sessions/' . $session->id, 'u|committee');

        $this->assertSame(409, $status);
        $this->assertSame('series_session', $body['error']);
        $this->assertNull(ClubSession::find($session->id)->deleted_at);
    }

    public function testSessionsFromToFilterAndDefaults()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['localDate' => '2026-10-14']));

        [, $body] = $this->call_('GET', '/app/clubs/1/sessions?from=2026-10-12&to=2026-10-19', 'u|member');
        $this->assertSame(['2026-10-12', '2026-10-14', '2026-10-19'], array_column($body['items'], 'localDate'));

        // Default window: today (2026-10-05) .. +60 days (2026-12-04) covers all nine Mondays plus the ad-hoc run.
        [, $body] = $this->call_('GET', '/app/clubs/1/sessions', 'u|member');
        $this->assertCount(10, $body['items']);

        $this->assertSame(422, $this->call_('GET', '/app/clubs/1/sessions?from=nope', 'u|member')[0]);
        $this->assertSame(422, $this->call_('GET', '/app/clubs/1/sessions?since=nope', 'u|member')[0]);
    }

    public function testSessionsSinceReturnsChangesAndTombstonesForAnyDate()
    {
        $this->setUpClubUsers();
        $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody());
        $this->call_('POST', '/app/clubs/1/sessions', 'u|committee', $this->adHocBody(['localDate' => '2027-01-01']));
        ClubSession::query()->update(['updated_at' => '2026-10-01 00:00:00']);

        Carbon::setTestNow(Carbon::parse('2026-10-05 12:30:00', 'UTC'));
        $this->call_('DELETE', '/app/clubs/1/sessions/' . self::X1, 'u|committee');
        $this->call_('POST', '/app/clubs/1/sessions/' . ClubSession::where('local_date', '2026-10-12')->value('id') . '/cancel', 'u|committee', ['reason' => 'Wet']);

        [$status, $body] = $this->call_('GET', '/app/clubs/1/sessions?from=2030-01-01&to=2030-01-02&since=2026-10-05T12:00:00Z', 'u|member');

        $this->assertSame(200, $status);
        $byId = [];
        foreach ($body['items'] as $item) {
            $byId[$item['id']] = $item;
        }
        $this->assertCount(2, $byId);
        $this->assertNotNull($byId[self::X1]['deletedAt']);
        $cancelled = array_values(array_filter($byId, function ($i) {
            return $i['status'] === 'cancelled';
        }));
        $this->assertCount(1, $cancelled);
        $this->assertSame('2026-10-12', $cancelled[0]['localDate']);
        $this->assertSame('2026-10-05T12:30:00.000Z', $body['serverTime']);

        // Without since the deleted ad-hoc run is not listed.
        [, $body] = $this->call_('GET', '/app/clubs/1/sessions?from=2026-12-31&to=2027-01-02', 'u|member');
        $this->assertSame([], $body['items']);
    }

    public function testRunsAreScopedToTheClub()
    {
        $this->setUpClubUsers();
        DB::table('clubs')->insert([
            'id' => 2, 'name' => 'Other', 'slug' => 'other', 'timezone' => 'Europe/London',
            'created_at' => Carbon::now(), 'updated_at' => Carbon::now(),
        ]);
        SessionSeries::create([
            'id' => self::S1, 'club_id' => 2, 'title' => 'Other run', 'weekday' => 2, 'start_time' => '18:00',
            'duration_min' => 60, 'valid_from' => '2026-01-01', 'group_mode' => 'open',
        ]);

        $this->assertSame(404, $this->call_('PATCH', '/app/clubs/1/series/' . self::S1, 'u|committee', ['title' => 'x'])[0]);
        $this->assertSame(404, $this->call_('DELETE', '/app/clubs/1/series/' . self::S1, 'u|committee')[0]);
        $this->assertSame(409, $this->call_('POST', '/app/clubs/1/series', 'u|committee', $this->seriesBody())[0]);
        $this->assertSame([], $this->call_('GET', '/app/clubs/1/series', 'u|member')[1]['items']);
    }

    public function testSeedMigrationCreatesBpjRunsOnceAndTheyGenerate()
    {
        $this->runMigrations(['2026_10_08_090300_seed_bpj_runs.php']);
        $this->runMigrations(['2026_10_08_090300_seed_bpj_runs.php']);

        $this->assertSame(5, Venue::count());
        $this->assertSame(6, SessionSeries::count());
        $this->assertNull(SessionSeries::where('title', 'Sunday long run')->first()->venue_id);

        $mug = SessionSeries::where('title', 'The Mug Run')->first();
        $this->assertSame(4, $mug->weekday);
        $this->assertSame('18:30', $mug->startHm());
        $this->assertSame('2027-04-01', $mug->validFromYmd());
        $this->assertSame('2027-09-30', $mug->validUntilYmd());

        // On 2026-10-08 only the always-on and winter series have runs in the window.
        $stats = $this->generator()->generateAll($this->london('2026-10-08 12:00'));
        $this->assertSame(['Monday club run', 'Sunday long run', 'Thursday winter run', 'Track night', 'Tuesday Riverside Run'],
            ClubSession::orderBy('title')->get()->pluck('title')->unique()->values()->all());
        $this->assertSame(8 + 8 + 8 + 9 + 8, $stats['created']);
    }
}
