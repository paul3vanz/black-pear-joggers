<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Facades\Queue;

/**
 * D108: a leader leads one group per run (409 already_leading) and a group has one `leader`
 * (409 leader_exists), in group create and in POST /groups/{id}/leaders.
 */
class AppLeaderRulesTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function create(string $sub, $session, array $data = []): array
    {
        return $this->api('POST', "/sessions/{$session->id}/groups", $sub, $data + ['lead' => true, 'label' => 'Group']);
    }

    // ---- already_leading ---------------------------------------------------------------

    public function testCreatingASecondLedGroupInTheSameRunIsRefused()
    {
        $s = $this->session();
        [$status, $first] = $this->create('plain', $s, ['label' => 'First']);
        $this->assertSame(201, $status);

        [$status, $body] = $this->create('plain', $s, ['label' => 'Second']);

        $this->assertSame(409, $status);
        $this->assertSame('already_leading', $body['error']);
        $this->assertSame($first['id'], $body['groupId']);
        $this->assertSame(1, SessionGroup::where('session_id', $s->id)->count());
    }

    public function testJoiningAnotherGroupAsAnyRoleWhileLeadingIsRefused()
    {
        $s = $this->session();
        $mine = $this->group($s, [$this->leaderA]);
        $other = $this->group($s, [$this->leaderB]);

        foreach ([null, 'leader', 'co_leader', 'backmarker'] as $role) {
            [$status, $body] = $this->api('POST', "/groups/{$other->id}/leaders", 'leaderA', $role ? ['role' => $role] : []);
            $this->assertSame(409, $status, (string) $role);
            $this->assertSame('already_leading', $body['error']);
            $this->assertSame($mine->id, $body['groupId']);
        }

        $this->assertFalse(SessionGroupLeader::where('group_id', $other->id)->where('member_id', $this->leaderA->id)->exists());
    }

    public function testJoiningTheSameGroupAgainIsIdempotent()
    {
        $s = $this->session();
        $mine = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('POST', "/groups/{$mine->id}/leaders", 'leaderA');
        $this->assertSame(200, $status);
        $this->assertSame($mine->id, $body['id']);
        [$status] = $this->api('POST', "/groups/{$mine->id}/leaders", 'leaderA', ['role' => 'leader']);
        $this->assertSame(200, $status);

        $this->assertSame(1, SessionGroupLeader::where('group_id', $mine->id)->where('member_id', $this->leaderA->id)->count());
    }

    public function testReplayingACreateWithTheSameIdReturnsTheGroupNotAnError()
    {
        $s = $this->session();
        $id = '11111111-1111-4111-8111-111111111111';

        [$status] = $this->create('plain', $s, ['id' => $id]);
        $this->assertSame(201, $status);
        [$status, $body] = $this->create('plain', $s, ['id' => $id]);

        $this->assertSame(200, $status);
        $this->assertSame($id, $body['id']);
    }

    public function testOtherRunsAndEndedLeadershipDoNotCount()
    {
        $s = $this->session();
        $next = $this->session(['date' => '2026-10-19']);
        [, $first] = $this->create('plain', $s, ['label' => 'First']);

        // Leading on another run is fine.
        [$status] = $this->create('plain', $next);
        $this->assertSame(201, $status);

        // So is leading after stepping down from the group (a withdrawn row never blocks).
        $other = $this->group($s, [$this->leaderB]);
        $this->api('DELETE', "/groups/{$first['id']}/leaders/me", 'plain');
        [$status, $body] = $this->api('POST', "/groups/{$other->id}/leaders", 'plain', ['role' => 'co_leader']);
        $this->assertSame(200, $status);
        $this->assertSame($other->id, $body['id']);

        // A deleted group no longer counts either.
        $s2 = $this->session(['date' => '2026-10-20']);
        [, $doomed] = $this->create('leaderA', $s2);
        $this->api('DELETE', "/groups/{$doomed['id']}", 'leaderA');
        [$status] = $this->create('leaderA', $s2, ['label' => 'Fresh']);
        $this->assertSame(201, $status);
    }

    public function testLeaderlessGroupsFromTheCommitteeAreUnaffected()
    {
        $s = $this->session();
        [$status] = $this->create('committee', $s, ['label' => 'Committee leads']);
        $this->assertSame(201, $status);

        // lead:false adds a leaderless group even to someone who leads another.
        [$status, $body] = $this->create('committee', $s, ['lead' => false, 'label' => 'Needs a leader']);
        $this->assertSame(201, $status);
        $this->assertSame('needs_leader', $body['status']);
        $this->assertSame([], $body['leaders']);

        // A group that has no leader yet takes its first one (anyone not leading elsewhere).
        [$status] = $this->api('POST', "/groups/{$body['id']}/leaders", 'leaderA');
        $this->assertSame(200, $status);
        // ...but the committee member, already leading, cannot also lead it.
        [$status, $refused] = $this->api('POST', "/groups/{$body['id']}/leaders", 'committee', ['role' => 'backmarker']);
        $this->assertSame(409, $status);
        $this->assertSame('already_leading', $refused['error']);
    }

    public function testEventGroupsAreUnaffected()
    {
        $s = $this->session(['group_mode' => 'events']);

        [$status] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['label' => 'Bromsgrove parkrun']);
        $this->assertSame(201, $status);
        [$status] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['label' => 'Cheltenham parkrun']);
        $this->assertSame(201, $status);
        $this->assertSame(2, SessionGroup::where('session_id', $s->id)->count());
    }

    // ---- leader_exists -----------------------------------------------------------------

    public function testTheLeaderRoleIsRefusedWhenTheGroupHasOne()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        foreach ([[], ['role' => 'leader']] as $body) {
            [$status, $out] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB', $body);
            $this->assertSame(409, $status);
            $this->assertSame('leader_exists', $out['error']);
            $this->assertSame('This group already has a leader. Join as co-leader or backmarker.', $out['message']);
        }

        $this->assertSame(1, SessionGroupLeader::where('group_id', $g->id)->count());
    }

    public function testCoLeaderAndBackmarkerAreNotLimited()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB', ['role' => 'co_leader']);
        $this->assertSame(200, $status);
        [$status] = $this->api('POST', "/groups/{$g->id}/leaders", 'coord', ['role' => 'backmarker']);
        $this->assertSame(200, $status);
        [$status] = $this->api('POST', "/groups/{$g->id}/leaders", 'committee', ['role' => 'co_leader']);
        $this->assertSame(200, $status);

        $roles = array_column($body['leaders'], 'role', 'memberId');
        $this->assertSame('co_leader', $roles[$this->leaderB->id]);
        $this->assertSame(4, SessionGroupLeader::where('group_id', $g->id)->where('status', 'confirmed')->count());
    }

    public function testOnlyAConfirmedLeaderRoleBlocksTheLeaderRole()
    {
        $s = $this->session();

        // Only a co-leader so far: the `leader` seat is free.
        $g = $this->group($s, []);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $g->id, 'member_id' => $this->leaderA->id, 'role' => 'co_leader']);
        [$status] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB', ['role' => 'leader']);
        $this->assertSame(200, $status);

        // A withdrawn leader does not block it.
        $g2 = $this->group($s, []);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $g2->id, 'member_id' => $this->plain->id, 'role' => 'leader', 'status' => 'withdrawn']);
        [$status] = $this->api('POST', "/groups/{$g2->id}/leaders", 'coord', ['role' => 'leader']);
        $this->assertSame(200, $status);

        // A group with no leaders at all.
        $g3 = $this->group($s, []);
        [$status] = $this->api('POST', "/groups/{$g3->id}/leaders", 'committee');
        $this->assertSame(200, $status);
    }

    public function testTheCurrentLeaderCanRejoinButAnotherMemberCannotTakeOverTheRole()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $g->id, 'member_id' => $this->leaderB->id, 'role' => 'co_leader']);

        // The leader re-joining as leader is idempotent.
        [$status] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderA', ['role' => 'leader']);
        $this->assertSame(200, $status);

        // The co-leader cannot become a second leader.
        [$status, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB', ['role' => 'leader']);
        $this->assertSame(409, $status);
        $this->assertSame('leader_exists', $body['error']);
        $this->assertSame('co_leader', SessionGroupLeader::where('group_id', $g->id)->where('member_id', $this->leaderB->id)->first()->role);

        // The leader may switch to co-leader themselves.
        [$status] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderA', ['role' => 'co_leader']);
        $this->assertSame(200, $status);
    }

    public function testCheckOrderValidationThenClosedRunThenTheNewRules()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB', ['role' => 'captain']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('role', $body['errors']);

        $past = $this->pastSession();
        $pg = $this->group($past, [$this->leaderA]);
        [$status, $body] = $this->api('POST', "/groups/{$pg->id}/leaders", 'leaderB');
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);
    }

    public function testAttendanceIsUnchangedWhenAJoinIsRefused()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);
        $this->attend($s, $this->leaderB, 'maybe');

        $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB');

        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->leaderB->id)->first();
        $this->assertSame('maybe', $row->status);
        $this->assertNull($row->group_id);
    }
}
