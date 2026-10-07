<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Facades\DB;

/**
 * Phase 4: edit/delete permissions, joining and withdrawing as a leader,
 * needs_leader transitions, and the sessions payload (groups, summary, sync).
 */
class AppGroupsLeadersTest extends AppGroupsBase
{
    // ---- patch / delete permission matrix --------------------------------

    public function testPatchPermissionMatrix()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['label' => 'Original']);

        $expected = [
            'plain' => 403,
            'leaderB' => 403, // another group's leader
            'leaderA' => 200, // a leader of this group
            'coord' => 200,
            'committee' => 200,
            'admin' => 200,
        ];

        foreach ($expected as $sub => $code) {
            [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", $sub, ['label' => "Edited by $sub"]);
            $this->assertSame($code, $status, $sub);

            if ($code === 200) {
                $this->assertSame("Edited by $sub", $body['label']);
            } else {
                $this->assertSame('forbidden', $body['error']);
            }
        }
    }

    public function testPatchClearsNullFieldsAndValidatesTheMergedValues()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], [
            'label' => 'Steady', 'pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600,
            'distance_value' => 3, 'distance_unit' => 'mi',
        ]);

        // Slower than the existing upper end: invalid once merged.
        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['paceFromS' => 700]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('paceToS', $body['errors']);

        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', [
            'label' => null, 'paceFromS' => null, 'paceToS' => null, 'distanceValue' => null,
        ]);
        $this->assertSame(200, $status);
        $this->assertNull($body['label']);
        $this->assertNull($body['paceFromS']);
        $this->assertNull($body['paceFromSPerKm']);
        $this->assertNull($body['distanceM']);
        $this->assertSame('run', $body['kind']);
    }

    public function testPatchOnClosedSessionsAndUnknownGroup()
    {
        $past = $this->pastSession();
        $g = $this->group($past, [$this->leaderA]);
        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['label' => 'x']);
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);

        $cancelled = $this->session(['status' => 'cancelled', 'date' => '2026-10-19']);
        $g2 = $this->group($cancelled, [$this->leaderA]);
        [$status, $body] = $this->api('PATCH', "/groups/{$g2->id}", 'committee', ['label' => 'x']);
        $this->assertSame(409, $status);
        $this->assertSame('session_cancelled', $body['error']);

        [$status] = $this->api('PATCH', '/groups/33333333-3333-4333-8333-333333333333', 'committee', ['label' => 'x']);
        $this->assertSame(404, $status);
    }

    public function testDeletePermissionMatrixAndAttendeesBecomeUnassigned()
    {
        $s = $this->session();

        foreach (['plain' => 403, 'leaderB' => 403, 'leaderA' => 204, 'coord' => 204, 'committee' => 204, 'admin' => 204] as $sub => $code) {
            $g = $this->group($s, [$this->leaderA]);
            $this->attend($s, $this->plain, 'going', $g)->delete();
            $row = $this->attend($s, $this->plain, 'going', $g);

            [$status] = $this->api('DELETE', "/groups/{$g->id}", $sub);
            $this->assertSame($code, $status, $sub);

            if ($code === 204) {
                $this->assertNotNull(SessionGroup::withTrashed()->find($g->id)->deleted_at, $sub);
                $this->assertNull($row->fresh()->group_id, $sub);
            } else {
                $this->assertNull(SessionGroup::find($g->id)->deleted_at, $sub);
                $this->assertSame($g->id, $row->fresh()->group_id, $sub);
            }

            $row->delete();
        }
    }

    public function testDeleteIsIdempotentAndUnknownIs404()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$first] = $this->api('DELETE', "/groups/{$g->id}", 'leaderA');
        [$second] = $this->api('DELETE', "/groups/{$g->id}", 'leaderA');
        [$unknown] = $this->api('DELETE', '/groups/44444444-4444-4444-8444-444444444444', 'leaderA');

        $this->assertSame(204, $first);
        $this->assertSame(204, $second);
        $this->assertSame(404, $unknown);
    }

    // ---- join / withdraw -------------------------------------------------

    public function testAnyLinkedMemberCanJoinAsLeaderWithARole()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'plain', ['role' => 'co_leader']);

        $this->assertSame(200, $status);
        $this->assertCount(2, $body['leaders']);
        $mine = array_values(array_filter($body['leaders'], function ($l) {
            return $l['memberId'] === $this->plain->id;
        }))[0];
        $this->assertSame('co_leader', $mine['role']);
        $this->assertSame('Pat Last201', $mine['displayName']);

        [$status, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB', ['role' => 'captain']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('role', $body['errors']);

        // Joining twice is harmless.
        $this->api('POST', "/groups/{$g->id}/leaders", 'plain', []);
        $this->assertSame(2, SessionGroupLeader::where('group_id', $g->id)->count());
    }

    public function testJoiningFlipsNeedsLeaderBackToActive()
    {
        $s = $this->session();
        $g = $this->group($s, [], ['status' => 'needs_leader']);

        [, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'plain');

        $this->assertSame('active', $body['status']);
        $this->assertSame('active', SessionGroup::find($g->id)->status);
    }

    public function testJoinOnPastCancelledAndUnknownGroups()
    {
        $past = $this->group($this->pastSession(), [$this->leaderA]);
        [$status, $body] = $this->api('POST', "/groups/{$past->id}/leaders", 'plain');
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);

        $cancelled = $this->group($this->session(['status' => 'cancelled', 'date' => '2026-10-19']), [$this->leaderA]);
        [$status, $body] = $this->api('POST', "/groups/{$cancelled->id}/leaders", 'plain');
        $this->assertSame(409, $status);
        $this->assertSame('session_cancelled', $body['error']);

        [$status] = $this->api('POST', '/groups/55555555-5555-4555-8555-555555555555/leaders', 'plain');
        $this->assertSame(404, $status);
    }

    public function testLastLeaderWithdrawingMakesAPacedGroupNeedALeader()
    {
        $s = $this->session(); // paced
        $g = $this->group($s, [$this->leaderA, $this->leaderB]);

        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(200, $status);
        $this->assertSame('active', $body['status']);
        $this->assertCount(1, $body['leaders']);
        $this->assertSame($this->leaderB->id, $body['leaders'][0]['memberId']);

        [, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderB');
        $this->assertSame('needs_leader', $body['status']);
        $this->assertSame([], $body['leaders']);

        // The withdrawn row is kept, and the leader can come back.
        $this->assertSame(2, SessionGroupLeader::where('group_id', $g->id)->count());
        $this->assertNotNull(SessionGroupLeader::where('member_id', $this->leaderA->id)->first()->withdrawn_at);

        [, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderA');
        $this->assertSame('active', $body['status']);
        $this->assertCount(1, $body['leaders']);
        $this->assertSame(2, SessionGroupLeader::where('group_id', $g->id)->count());
    }

    public function testSingleModeNeedsALeaderButRoutesAndOpenStayActive()
    {
        foreach (['single' => 'needs_leader', 'routes' => 'active', 'open' => 'active'] as $mode => $expected) {
            $s = $this->session(['group_mode' => $mode, 'date' => $mode === 'single' ? '2026-10-13' : ($mode === 'routes' ? '2026-10-14' : '2026-10-15')]);
            $g = $this->group($s, [$this->leaderA]);

            [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');

            $this->assertSame(200, $status, $mode);
            $this->assertSame($expected, $body['status'], $mode);
            $this->assertSame([], $body['leaders'], $mode);
        }
    }

    public function testWithdrawingWhenNotALeaderChangesNothing()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'plain');

        $this->assertSame(200, $status);
        $this->assertSame('active', $body['status']);
        $this->assertCount(1, $body['leaders']);
    }

    // ---- sessions payload and sync ---------------------------------------

    public function testSessionsPayloadCarriesGroupsAndTheCallersSummary()
    {
        $s = $this->session();
        $g1 = $this->group($s, [$this->leaderA, $this->leaderB], ['label' => 'Fast', 'sort_order' => 0]);
        $g2 = $this->group($s, [], ['label' => 'Slow', 'sort_order' => 1]);
        $gone = $this->group($s, [$this->leaderA], ['label' => 'Gone']);
        $gone->delete();
        $this->attend($s, $this->plain, 'going', $g1);
        $this->attend($s, $this->coord, 'maybe', $g1);
        $this->attend($s, $this->committee, 'going');
        $this->attend($s, $this->admin, 'not_going');

        [$status, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
        $this->assertSame(200, $status);
        $item = $body['items'][0];

        $this->assertSame(['Fast', 'Slow'], array_column($item['groups'], 'label'));
        $this->assertSame(1, $item['groups'][0]['goingCount']);
        $this->assertSame(1, $item['groups'][0]['maybeCount']);
        $names = array_column($item['groups'][0]['leaders'], 'displayName');
        sort($names);
        $this->assertSame(['Lee Last202', 'Lou Last203'], $names);
        $this->assertSame('needs_leader', $item['groups'][1]['status']);
        $this->assertSame([
            'groupCount' => 2, 'leaderCount' => 2, 'goingCount' => 2, 'maybeCount' => 1,
            'myStatus' => 'going', 'myGroupId' => $g1->id, 'myLeading' => false,
        ], $item['summary']);

        // The summary is computed for whoever asks.
        [, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'leaderA');
        $summary = $body['items'][0]['summary'];
        $this->assertNull($summary['myStatus']);
        $this->assertNull($summary['myGroupId']);
        $this->assertTrue($summary['myLeading']);

        [, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'admin');
        $this->assertSame('not_going', $body['items'][0]['summary']['myStatus']);
    }

    public function testSessionWithoutGroupsHasAnEmptySummary()
    {
        $this->session();
        [, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');

        $this->assertSame([], $body['items'][0]['groups']);
        $this->assertSame([
            'groupCount' => 0, 'leaderCount' => 0, 'goingCount' => 0, 'maybeCount' => 0,
            'myStatus' => null, 'myGroupId' => null, 'myLeading' => false,
        ], $body['items'][0]['summary']);
    }

    public function testSessionQueryCountIsBoundedByTheSessionPage()
    {
        // Several sessions, each with groups, leaders and attendees.
        for ($i = 0; $i < 6; $i++) {
            $s = $this->session(['date' => '2026-10-' . (13 + $i)]);
            $g = $this->group($s, [$this->leaderA, $this->leaderB]);
            $this->group($s, [$this->committee]);
            $this->attend($s, $this->plain, 'going', $g);
            $this->attend($s, $this->coord, 'maybe');
        }

        DB::connection()->enableQueryLog();
        [$status, $body] = $this->api('GET', '/sessions?from=2026-10-13&to=2026-10-30', 'plain');
        $queries = count(DB::connection()->getQueryLog());
        DB::connection()->disableQueryLog();

        $this->assertSame(200, $status);
        $this->assertCount(6, $body['items']);
        $this->assertCount(2, $body['items'][5]['groups']);
        // Auth lookups + sessions + series + coordinators + groups + leaders + members + attendees: constant in N.
        $this->assertLessThanOrEqual(14, $queries, "Too many queries: $queries");
    }

    // ---- leaders attend their own group ----------------------------------

    public function testCreatingAGroupAsLeaderMarksTheLeaderAsGoingInIt()
    {
        $s = $this->session();
        [, $group] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['lead' => true, 'paceUnit' => 'mi', 'paceFromS' => 570]);

        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->plain->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertSame($group['id'], $row->group_id);

        [, $feed] = $this->api('GET', '/sessions', 'plain');
        $this->assertSame('going', $feed['items'][0]['summary']['myStatus']);
        $this->assertSame($group['id'], $feed['items'][0]['summary']['myGroupId']);
        $this->assertTrue($feed['items'][0]['summary']['myLeading']);
    }

    public function testJoiningAsLeaderMovesAndKeepsThePacePerRun()
    {
        $s = $this->session();
        $other = $this->group($s, [$this->leaderB]);
        $mine = $this->group($s, [$this->leaderB]);
        // Already coming to a different group, with a pace for this run.
        $this->attend($s, $this->leaderA, 'maybe', $other, ['pace_unit' => 'km', 'pace_from_s' => 330]);

        $this->api('POST', "/groups/{$mine->id}/leaders", 'leaderA');

        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->leaderA->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertSame($mine->id, $row->group_id);
        $this->assertSame('km', $row->pace_unit);
        $this->assertSame(330, (int) $row->pace_from_s);
        $this->assertSame(1, SessionAttendee::where('session_id', $s->id)->where('member_id', $this->leaderA->id)->count());
    }

    public function testNotGoingBecomesGoingWhenYouLead()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'not_going');

        $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['lead' => true]);

        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->plain->id)->first();
        $this->assertSame('going', $row->status);
    }

    public function testLeaderlessGroupsAndWithdrawingDoNotChangeAttendance()
    {
        $s = $this->session();
        $this->api('POST', "/sessions/{$s->id}/groups", 'committee', ['lead' => false]);
        $this->assertSame(0, SessionAttendee::where('session_id', $s->id)->count());

        [, $group] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', ['lead' => true]);
        $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'leaderA');

        // Stepping down as leader leaves them going in the group.
        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->leaderA->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertSame($group['id'], $row->group_id);
    }

    public function testGroupChangesBumpTheSessionAndSinceDeliversIt()
    {
        $s = $this->session();
        $s2 = $this->session(['date' => '2026-10-19']);
        $before = $this->sessionUpdatedAt($s);
        $since = Carbon\Carbon::now()->addSeconds(30)->utc()->format('Y-m-d\TH:i:s\Z');

        $this->tick(60);
        [, $group] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['lead' => true, 'label' => 'New']);
        $afterCreate = $this->sessionUpdatedAt($s);
        $this->assertGreaterThan($before, $afterCreate);

        [, $feed] = $this->api('GET', '/sessions?since=' . urlencode($since), 'plain');
        $this->assertSame([$s->id], array_column($feed['items'], 'id'));
        $this->assertSame('New', $feed['items'][0]['groups'][0]['label']);

        $this->tick(60);
        $this->api('PATCH', "/groups/{$group['id']}", 'plain', ['label' => 'Renamed']);
        $afterPatch = $this->sessionUpdatedAt($s);
        $this->assertGreaterThan($afterCreate, $afterPatch);

        $this->tick(60);
        $this->api('POST', "/groups/{$group['id']}/leaders", 'leaderA');
        $afterJoin = $this->sessionUpdatedAt($s);
        $this->assertGreaterThan($afterPatch, $afterJoin);

        $this->tick(60);
        $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'leaderA');
        $afterWithdraw = $this->sessionUpdatedAt($s);
        $this->assertGreaterThan($afterJoin, $afterWithdraw);

        $this->tick(60);
        $this->api('DELETE', "/groups/{$group['id']}", 'plain');
        $this->assertGreaterThan($afterWithdraw, $this->sessionUpdatedAt($s));

        // The other run was never touched.
        $this->assertSame($before, $this->sessionUpdatedAt($s2));
    }
}
