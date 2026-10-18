<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\Notification;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Facades\Queue;

/**
 * D109 (supersedes D30's "withdraw keeps attendance"): DELETE /groups/{id}/leaders/me removes the
 * caller from the group, deletes a group the caller made when nobody else is in it, and otherwise
 * runs the Phase 5 needs_leader flow. Optional body {notGoing: bool}.
 */
class AppStepDownTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function row($session, $member): ?SessionAttendee
    {
        return SessionAttendee::where('session_id', $session->id)->where('member_id', $member->id)->first();
    }

    /** A group 'plain' created through the API (so plain is its creator and leader). */
    private function createdByPlain($session): array
    {
        [$status, $group] = $this->api('POST', "/sessions/{$session->id}/groups", 'plain', [
            'lead' => true, 'label' => 'Steady', 'paceUnit' => 'mi', 'paceFromS' => 570, 'paceToS' => 600,
        ]);
        $this->assertSame(201, $status);

        return $group;
    }

    public function testTheCreatorStandingDownFromAnUnusedGroupDeletesIt()
    {
        $s = $this->session();
        $group = $this->createdByPlain($s);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $group['id'], 'paceUnit' => 'mi', 'paceFromS' => 560]);
        // leaderB (a never-led leader) would be asked if the group were kept; the deleted case must ask nobody.
        $before = $this->sessionUpdatedAt($s);
        $this->tick(60);

        [$status, $body] = $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain');

        $this->assertSame(200, $status);
        $this->assertSame($group['id'], $body['id']);
        $this->assertNotNull($body['deletedAt']);
        $this->assertSame(0, $body['goingCount']);
        $this->assertNotNull(SessionGroup::withTrashed()->find($group['id'])->deleted_at);
        $this->assertNull(SessionGroup::find($group['id']));
        $this->assertSame(0, Notification::count());
        $this->assertGreaterThan($before, $this->sessionUpdatedAt($s));

        // Still going, no group, pace override kept.
        $mine = $this->row($s, $this->plain);
        $this->assertSame('going', $mine->status);
        $this->assertNull($mine->group_id);
        $this->assertSame(560, (int) $mine->pace_from_s);

        // The run's feed has no group and the caller's summary shows it.
        [, $feed] = $this->api('GET', '/sessions', 'plain');
        $this->assertSame([], $feed['items'][0]['groups']);
        $this->assertNull($feed['items'][0]['summary']['myGroupId']);
        $this->assertSame('going', $feed['items'][0]['summary']['myStatus']);
        $this->assertFalse($feed['items'][0]['summary']['myLeading']);
        $this->assertSame(0, $feed['items'][0]['summary']['groupCount']);
    }

    public function testTheCreatorWithAnotherAttendeeKeepsTheGroupAndItNeedsALeader()
    {
        $s = $this->session();
        $group = $this->createdByPlain($s);
        $this->attend($s, $this->coord, 'going', SessionGroup::find($group['id']));
        $this->attend($s, $this->committee, 'maybe', SessionGroup::find($group['id']));
        // leaderB has the leader role and has never led: asked to lead.
        $this->tick(60);

        [$status, $body] = $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain');

        $this->assertSame(200, $status);
        $this->assertNull($body['deletedAt']);
        $this->assertSame('needs_leader', $body['status']);
        $this->assertSame([], $body['leaders']);
        $this->assertSame(1, $body['goingCount']); // the caller is gone from it
        $this->assertSame(1, $body['maybeCount']);

        $this->assertNull($this->row($s, $this->plain)->group_id);
        $this->assertSame('going', $this->row($s, $this->plain)->status);

        $this->assertSame(1, Notification::where('member_id', $this->coord->id)->where('category', 'my_group_changes')->count());
        $this->assertSame(1, Notification::where('member_id', $this->committee->id)->where('category', 'my_group_changes')->count());
        $this->assertSame(1, Notification::where('member_id', $this->leaderB->id)->where('category', 'leaders_needed')->count());
        $this->assertSame(0, Notification::where('member_id', $this->plain->id)->count());
    }

    public function testTheCreatorWithACoLeaderLeavesTheGroupActive()
    {
        $s = $this->session();
        $group = $this->createdByPlain($s);
        [$status] = $this->api('POST', "/groups/{$group['id']}/leaders", 'leaderA', ['role' => 'co_leader']);
        $this->assertSame(200, $status);

        [$status, $body] = $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain');

        $this->assertSame(200, $status);
        $this->assertNull($body['deletedAt']);
        $this->assertSame('active', $body['status']);
        $this->assertSame([$this->leaderA->id], array_column($body['leaders'], 'memberId'));
        $this->assertSame(1, $body['goingCount']); // the co-leader
        $this->assertSame(0, Notification::count());
        $this->assertNull($this->row($s, $this->plain)->group_id);
    }

    public function testASoleLeaderWhoDidNotCreateTheGroupLeavesItNeedingALeaderEvenWhenEmpty()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['created_by_member_id' => $this->committee->id, 'label' => 'Steady']);
        $this->attend($s, $this->leaderA, 'going', $g);

        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');

        $this->assertSame(200, $status);
        $this->assertNull($body['deletedAt']);
        $this->assertSame('needs_leader', $body['status']);
        $this->assertSame(0, $body['goingCount']);
        $this->assertNull(SessionGroup::find($g->id)->deleted_at);
        $this->assertNull($this->row($s, $this->leaderA)->group_id);
        $this->assertSame('going', $this->row($s, $this->leaderA)->status);
        // The group-level "leaders needed" ask still goes out (leaderB, never led).
        $this->assertSame(1, Notification::where('member_id', $this->leaderB->id)->where('category', 'leaders_needed')->count());
    }

    public function testNotGoingMarksTheCallerNotGoingAndRemovesThemFromTheGroup()
    {
        $s = $this->session();
        $group = $this->createdByPlain($s);
        [$status, $body] = $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain', ['notGoing' => true]);

        $this->assertSame(200, $status);
        $this->assertNotNull($body['deletedAt']);
        $mine = $this->row($s, $this->plain);
        $this->assertSame('not_going', $mine->status);
        $this->assertNull($mine->group_id);
        $this->assertSame(1, SessionAttendee::where('session_id', $s->id)->where('member_id', $this->plain->id)->count());

        // With people in the group it is kept, and the leaving leader is still not going.
        $s2 = $this->session(['date' => '2026-10-19']);
        $g2 = $this->createdByPlain($s2);
        $this->attend($s2, $this->coord, 'going', SessionGroup::find($g2['id']));
        [, $body] = $this->api('DELETE', "/groups/{$g2['id']}/leaders/me", 'plain', ['notGoing' => true]);
        $this->assertNull($body['deletedAt']);
        $this->assertSame('not_going', $this->row($s2, $this->plain)->status);
        $this->assertNull($this->row($s2, $this->plain)->group_id);
    }

    public function testNotGoingFalseOrOmittedKeepsTheStatus()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['created_by_member_id' => $this->committee->id]);
        $this->attend($s, $this->leaderA, 'maybe', $g);

        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA', ['notGoing' => false]);

        $this->assertSame('maybe', $this->row($s, $this->leaderA)->status);
        $this->assertNull($this->row($s, $this->leaderA)->group_id);
    }

    public function testNonBooleanNotGoingIsA422AndChangesNothing()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);
        $this->attend($s, $this->leaderA, 'going', $g);

        foreach (['yes', 'true', 1, 0, null, [], ['a' => 1]] as $value) {
            [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA', ['notGoing' => $value]);
            $this->assertSame(422, $status, json_encode($value));
            $this->assertSame('validation_failed', $body['error']);
            $this->assertArrayHasKey('notGoing', $body['errors']);
        }

        $this->assertTrue(SessionGroupLeader::where('group_id', $g->id)->where('member_id', $this->leaderA->id)->first()->status === 'confirmed');
        $this->assertSame($g->id, $this->row($s, $this->leaderA)->group_id);
    }

    public function testRepeatingTheCallReturnsTheGroupWithoutChangingAnything()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['created_by_member_id' => $this->committee->id]);
        $this->attend($s, $this->coord, 'going', $g);
        $this->attend($s, $this->leaderA, 'going', $g);

        [, $first] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame('needs_leader', $first['status']);
        $notifications = Notification::count();

        // Replay: same payload, no error, no new notifications. A replay with notGoing does not rewrite it.
        [$status, $again] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA', ['notGoing' => true]);
        $this->assertSame(200, $status);
        $this->assertSame($first['id'], $again['id']);
        $this->assertSame('needs_leader', $again['status']);
        $this->assertSame($notifications, Notification::count());
        $this->assertSame('going', $this->row($s, $this->leaderA)->status);

        // A member who never led is told nothing and loses nothing.
        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'coord');
        $this->assertSame(200, $status);
        $this->assertSame($g->id, $body['id']);
        $this->assertSame($g->id, $this->row($s, $this->coord)->group_id);
    }

    public function testRepeatingTheCallAfterTheGroupWasDeletedStillSucceeds()
    {
        $s = $this->session();
        $group = $this->createdByPlain($s);

        $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain');
        [$status, $body] = $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain');

        $this->assertSame(200, $status);
        $this->assertSame($group['id'], $body['id']);
        $this->assertNotNull($body['deletedAt']);
        $this->assertSame(0, Notification::count());
    }

    public function testAnotherAttendeeInTheGroupIsMovedNowhere()
    {
        $s = $this->session();
        $group = $this->createdByPlain($s);
        [$status] = $this->api('POST', "/groups/{$group['id']}/leaders", 'leaderA', ['role' => 'backmarker']);
        $this->assertSame(200, $status);

        $this->api('DELETE', "/groups/{$group['id']}/leaders/me", 'plain');

        // The backmarker is still in the group and still a leader of it.
        $this->assertSame($group['id'], $this->row($s, $this->leaderA)->group_id);
        $this->assertSame('confirmed', SessionGroupLeader::where('group_id', $group['id'])->where('member_id', $this->leaderA->id)->first()->status);
    }

    public function testClosedRunsAndUnknownGroupsKeepTheirErrors()
    {
        $past = $this->pastSession();
        $g = $this->group($past, [$this->leaderA]);
        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);

        [$status] = $this->api('DELETE', '/groups/99999999-9999-4999-8999-999999999999/leaders/me', 'leaderA');
        $this->assertSame(404, $status);
    }
}
