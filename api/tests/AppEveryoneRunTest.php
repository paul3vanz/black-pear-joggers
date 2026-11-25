<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\SessionAttendee;
use App\Models\SessionGroup;

/**
 * The `everyone` run mode (no leaders or pace groups), the routes switch and the
 * group chat's members list.
 */
class AppEveryoneRunTest extends AppGroupsBase
{
    public function testGoingOnAnEveryoneRunJoinsTheOneSharedGroup()
    {
        $s = $this->session(['group_mode' => 'everyone']);

        [, $a] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going']);
        [, $b] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'leaderA', ['status' => 'maybe']);

        $this->assertNotNull($a['groupId']);
        $this->assertSame($a['groupId'], $b['groupId']);
        $this->assertSame(1, SessionGroup::where('session_id', $s->id)->count());

        // Not going leaves the group; the group chat then closes to them.
        [, $out] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'not_going']);
        $this->assertNull($out['groupId']);
    }

    public function testChatMembersListsEveryoneInTheThreadAsShortNames()
    {
        $s = $this->session(['group_mode' => 'everyone']);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going']);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'leaderA', ['status' => 'going']);
        $groupId = SessionGroup::where('session_id', $s->id)->first()->id;

        [$status, $body] = $this->api('GET', "/groups/{$groupId}/members", 'plain');
        $this->assertSame(200, $status);
        // The two going, plus the run's coordinator.
        $this->assertGreaterThanOrEqual(2, count($body['items']));
        $this->assertStringNotContainsString('Last20', json_encode($body));

        // Someone who is not in the thread cannot see who is.
        [$status] = $this->api('GET', "/groups/{$groupId}/members", 'leaderB');
        $this->assertSame(403, $status);
    }

    public function testUsesRoutesDefaultsToTrueAndCanBeSwitchedOffOnASeries()
    {
        [$status, $series] = $this->api('POST', '/series', 'admin', [
            'title' => 'Mug Run', 'weekday' => 4, 'startTime' => '19:00', 'groupMode' => 'open', 'usesRoutes' => false,
        ]);
        $this->assertSame(201, $status);
        $this->assertFalse($series['usesRoutes']);

        [, $sessions] = $this->api('GET', '/sessions', 'plain');
        $mine = array_values(array_filter($sessions['items'], function ($i) use ($series) {
            return $i['seriesId'] === $series['id'];
        }));
        $this->assertNotEmpty($mine);
        $this->assertFalse($mine[0]['usesRoutes']);

        $s = $this->session();
        [, $all] = $this->api('GET', '/sessions', 'plain');
        $plainRun = array_values(array_filter($all['items'], function ($i) use ($s) {
            return $i['id'] === $s->id;
        }));
        $this->assertTrue($plainRun[0]['usesRoutes']);
    }
}
