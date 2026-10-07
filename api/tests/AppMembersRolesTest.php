<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubMember;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionSeries;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Phase 4: members search, role management, and the generator never deleting
 * runs that have sign-ups.
 */
class AppMembersRolesTest extends AppGroupsBase
{
    // ---- members search --------------------------------------------------

    public function testMembersListIsCommitteeAndAdminOnly()
    {
        foreach (['plain' => 403, 'leaderB' => 403, 'coord' => 403, 'committee' => 200, 'admin' => 200] as $sub => $code) {
            [$status, $body] = $this->api('GET', '/members', $sub);
            $this->assertSame($code, $status, $sub);

            if ($code === 403) {
                $this->assertSame('forbidden', $body['error']);
            }
        }
    }

    public function testMembersSearchByNameOrderedAndWithoutPersonalData()
    {
        [$status, $body] = $this->api('GET', '/members', 'committee');

        $this->assertSame(200, $status);
        $names = array_column($body['items'], 'displayName');
        $sorted = $names;
        sort($sorted);
        $this->assertSame($sorted, $names);
        $this->assertCount(6, $names);
        $this->assertSame(['memberId', 'displayName', 'status', 'roles'], array_keys($body['items'][0]));
        $this->assertStringNotContainsString('urn', json_encode($body));
        $this->assertStringNotContainsString('dob', json_encode($body));
        $this->assertStringNotContainsString('1980', json_encode($body));

        [, $body] = $this->api('GET', '/members?q=' . urlencode('lou'), 'committee');
        $this->assertSame(['Lou Last203'], array_column($body['items'], 'displayName'));
        $this->assertSame(['leader'], $body['items'][0]['roles']);

        [, $body] = $this->api('GET', '/members?q=' . urlencode('%'), 'committee');
        $this->assertSame([], $body['items']); // a literal percent, not a wildcard

        [, $body] = $this->api('GET', '/members?limit=2', 'committee');
        $this->assertCount(2, $body['items']);
    }

    public function testMembersListIsCappedAtFiftyAndScopedToTheClub()
    {
        for ($i = 0; $i < 60; $i++) {
            ClubMember::create(['club_id' => 1, 'athlete_id' => 900 + $i, 'display_name' => sprintf('Zed %02d', $i)]);
        }

        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other club', 'slug' => 'other', 'timezone' => 'Europe/London']);
        ClubMember::create(['club_id' => 2, 'athlete_id' => 999, 'display_name' => 'Zed Foreign']);

        [, $body] = $this->api('GET', '/members?limit=500&q=Zed', 'committee');
        $this->assertCount(50, $body['items']);
        $this->assertNotContains('Zed Foreign', array_column($body['items'], 'displayName'));

        [, $body] = $this->api('GET', '/members?q=Foreign', 'committee');
        $this->assertSame([], $body['items']);
    }

    // ---- roles -----------------------------------------------------------

    public function testCommitteeAndAdminGrantAndRemoveLeader()
    {
        foreach (['committee', 'admin'] as $sub) {
            [$status, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", $sub, ['roles' => ['leader']]);
            $this->assertSame(200, $status, $sub);
            $this->assertSame(['leader'], $body['roles']);
            $this->assertSame($this->plain->id, $body['memberId']);
            $this->assertSame(['leader'], ClubMember::find($this->plain->id)->roles);

            [, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", $sub, ['roles' => []]);
            $this->assertSame([], $body['roles']);
        }
    }

    public function testOnlyAnAdminManagesCommitteeAndAdmin()
    {
        [$status, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", 'committee', ['roles' => ['committee']]);
        $this->assertSame(403, $status);
        $this->assertSame('forbidden', $body['error']);
        $this->assertSame([], ClubMember::find($this->plain->id)->roles);

        [$status] = $this->api('PATCH', "/members/{$this->plain->id}/roles", 'committee', ['roles' => ['leader', 'admin']]);
        $this->assertSame(403, $status);

        // A committee member cannot strip another committee member either.
        [$status] = $this->api('PATCH', "/members/{$this->committee->id}/roles", 'committee', ['roles' => []]);
        $this->assertSame(403, $status);
        $this->assertSame(['committee'], ClubMember::find($this->committee->id)->roles);

        [$status, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", 'admin', ['roles' => ['committee', 'leader']]);
        $this->assertSame(200, $status);
        $this->assertSame(['leader', 'committee'], $body['roles']);

        [$status, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", 'admin', ['roles' => ['admin']]);
        $this->assertSame(200, $status);
        $this->assertSame(['admin'], $body['roles']);
    }

    public function testCommitteeKeepingExistingCommitteeRoleWhileChangingLeaderIsFine()
    {
        [$status, $body] = $this->api('PATCH', "/members/{$this->committee->id}/roles", 'committee', ['roles' => ['committee', 'leader']]);

        $this->assertSame(200, $status);
        $this->assertSame(['leader', 'committee'], $body['roles']);
    }

    public function testRolesRejectedForPlainMembersLeadersAndCoordinators()
    {
        foreach (['plain', 'leaderB', 'coord'] as $sub) {
            [$status, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", $sub, ['roles' => ['leader']]);
            $this->assertSame(403, $status, $sub);
            $this->assertSame('forbidden', $body['error']);
        }

        $this->assertSame([], ClubMember::find($this->plain->id)->roles);
    }

    public function testUnknownRolesAndBadBodiesAre422()
    {
        foreach ([['roles' => ['captain']], ['roles' => ['leader', 'superuser']], ['roles' => 'leader'], []] as $data) {
            [$status, $body] = $this->api('PATCH', "/members/{$this->plain->id}/roles", 'admin', $data);
            $this->assertSame(422, $status, json_encode($data));
            $this->assertSame('validation_failed', $body['error']);
        }

        $this->assertSame([], ClubMember::find($this->plain->id)->roles);
    }

    public function testRolesOnlyForMembersOfThisClub()
    {
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other club', 'slug' => 'other', 'timezone' => 'Europe/London']);
        $foreign = ClubMember::create(['club_id' => 2, 'athlete_id' => 999, 'display_name' => 'Far Away']);

        [$status, $body] = $this->api('PATCH', "/members/{$foreign->id}/roles", 'admin', ['roles' => ['leader']]);
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);
        $this->assertSame([], ClubMember::find($foreign->id)->roles);

        [$status] = $this->api('PATCH', '/members/99999999-9999-4999-8999-999999999999/roles', 'admin', ['roles' => ['leader']]);
        $this->assertSame(404, $status);
    }

    public function testGrantedLeaderRoleShowsUpInTheList()
    {
        $this->api('PATCH', "/members/{$this->plain->id}/roles", 'committee', ['roles' => ['leader']]);

        [, $body] = $this->api('GET', '/members?q=Pat', 'committee');
        $this->assertSame(['leader'], $body['items'][0]['roles']);
    }

    // ---- generator keeps runs that have sign-ups --------------------------

    private function series(): SessionSeries
    {
        return SessionSeries::create([
            'club_id' => 1, 'title' => 'Monday club run', 'weekday' => 1, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
    }

    /** @return array{0: SessionSeries, 1: \App\Models\ClubSession} the series and its 2026-10-19 run */
    private function generated(): array
    {
        $series = $this->series();
        (new SessionGenerator())->generateForSeries($series, Carbon::parse('2026-10-12 09:00', 'Europe/London'));

        return [$series, \App\Models\ClubSession::where('series_id', $series->id)->where('occurrence_date', '2026-10-19')->first()];
    }

    private function regenerateAfterWeekdayChange(SessionSeries $series): array
    {
        $series->weekday = 3;
        $series->save();

        return (new SessionGenerator())->generateForSeries($series->fresh(), Carbon::parse('2026-10-12 09:00', 'Europe/London'));
    }

    public function testASessionWithAGroupIsKeptAndDetachedWhenTheSeriesMovesOn()
    {
        [$series, $run] = $this->generated();
        $this->group($run, [$this->leaderA]);
        $untouched = \App\Models\ClubSession::where('series_id', $series->id)->where('occurrence_date', '2026-10-26')->first();

        $this->regenerateAfterWeekdayChange($series);

        $kept = \App\Models\ClubSession::withTrashed()->find($run->id);
        $this->assertNull($kept->deleted_at);
        $this->assertTrue((bool) $kept->is_detached);
        $this->assertSame(1, SessionGroup::where('session_id', $run->id)->count());
        // A run with nothing on it is still removed.
        $this->assertNotNull(\App\Models\ClubSession::withTrashed()->find($untouched->id)->deleted_at);
    }

    /** @dataProvider keptStatuses */
    public function testGoingOrMaybeAttendanceKeepsTheRun(string $status)
    {
        [$series, $run] = $this->generated();
        $this->attend($run, $this->plain, $status);

        $this->regenerateAfterWeekdayChange($series);

        $kept = \App\Models\ClubSession::withTrashed()->find($run->id);
        $this->assertNull($kept->deleted_at);
        $this->assertTrue((bool) $kept->is_detached);
    }

    public function keptStatuses(): array
    {
        return ['going' => ['going'], 'maybe' => ['maybe']];
    }

    public function testNotGoingAttendanceDoesNotKeepTheRun()
    {
        [$series, $run] = $this->generated();
        $this->attend($run, $this->plain, 'not_going');

        $this->regenerateAfterWeekdayChange($series);

        $this->assertNotNull(\App\Models\ClubSession::withTrashed()->find($run->id)->deleted_at);
    }

    public function testADeletedGroupDoesNotProtectTheRun()
    {
        [$series, $run] = $this->generated();
        $this->group($run, [$this->leaderA])->delete();

        $this->regenerateAfterWeekdayChange($series);

        $this->assertNotNull(\App\Models\ClubSession::withTrashed()->find($run->id)->deleted_at);
    }

    public function testDeletingTheSeriesKeepsRunsWithSignUps()
    {
        [$series, $run] = $this->generated();
        $this->attend($run, $this->plain, 'going');

        $series->delete();
        (new SessionGenerator())->generateForSeries($series->fresh(), Carbon::parse('2026-10-12 09:00', 'Europe/London'));

        $kept = \App\Models\ClubSession::find($run->id);
        $this->assertNotNull($kept);
        $this->assertTrue((bool) $kept->is_detached);
        $this->assertSame(1, \App\Models\ClubSession::where('series_id', $series->id)->count());

        // A later run no longer touches it (it is detached now).
        $stats = (new SessionGenerator())->generateForSeries($series->fresh(), Carbon::parse('2026-10-12 10:00', 'Europe/London'));
        $this->assertSame(0, $stats['deleted']);
    }
}
