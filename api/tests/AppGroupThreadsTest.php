<?php

require_once __DIR__ . '/AppMessagesBase.php';

use App\Models\GroupThreadState;
use App\Models\MemberPreference;
use Illuminate\Support\Carbon;

/**
 * Phase 6a: GET /threads, the caller's chat list.
 */
class AppGroupThreadsTest extends AppMessagesBase
{
    private function threads(string $sub): array
    {
        [$status, $body] = $this->api('GET', '/threads', $sub);
        $this->assertSame(200, $status);

        return $body;
    }

    public function testListsTheCallersThreadsNewestMessageFirstWithTheRunDetails()
    {
        $other = $this->session(['date' => '2026-10-13', 'title' => 'Tuesday trail']);
        $h = $this->group($other, [$this->leaderA], ['label' => 'Trail', 'pace_unit' => 'mi', 'pace_from_s' => 600]);

        $this->msg($this->going, $this->g, 'older', Carbon::now()->subHours(3));
        $this->msg($this->going, $this->g, 'g latest', Carbon::now()->subHours(2));
        $this->msg($this->leaderB, $h, 'h newest', Carbon::now()->subHours(1)); // leaderA leads h, may read it

        $body = $this->threads('leaderA');

        $this->assertSame('2026-10-12T09:00:00.000Z', $body['serverTime']);
        $this->assertCount(2, $body['items']);
        $this->assertSame($h->id, $body['items'][0]['groupId']);
        $this->assertSame($this->g->id, $body['items'][1]['groupId']);

        $this->assertSame([
            'groupId' => $this->g->id,
            'sessionId' => $this->sess->id,
            'label' => '9:00-9:30/mi',
            'sessionTitle' => 'Monday club run',
            'localDate' => '2026-10-12',
            'localStartTime' => '19:00',
            'lastMessage' => ['authorName' => 'Gwen L.', 'body' => 'g latest', 'createdAt' => '2026-10-12T07:00:00.000Z'],
            'unreadCount' => 2,
            'muted' => false,
            'closed' => false,
        ], $body['items'][1]);
        $this->assertSame('Trail 10:00/mi', $body['items'][0]['label']);
        $this->assertSame('Lou L.', $body['items'][0]['lastMessage']['authorName']);
        $this->assertSame('Tuesday trail', $body['items'][0]['sessionTitle']);
        $this->assertSame('2026-10-13', $body['items'][0]['localDate']);
    }

    public function testLabelUsesTheCallersUnitsAndFallsBackToGroup()
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->leaderA->id, 'pace_unit' => 'km']);
        $h = $this->group($this->sess, [$this->leaderA]); // no label, no pace
        $this->msg($this->going, $this->g, 'a', Carbon::now()->subHours(2));
        $this->msg($this->going, $h, 'b', Carbon::now()->subHours(1));

        $body = $this->threads('leaderA');

        $this->assertSame('Group', $body['items'][0]['label']);
        $this->assertSame(\App\Services\PaceMatcher::format('mi', 540, 570, 'km'), $body['items'][1]['label']);
    }

    public function testOnlyThreadsTheCallerIsInAreListed()
    {
        $h = $this->group($this->sess, [$this->leaderB]);
        $this->msg($this->leaderB, $h, 'only for h');
        $this->msg($this->going, $this->g, 'for g');

        $this->assertSame([$this->g->id], array_column($this->threads('going')['items'], 'groupId'));
        $this->assertSame([$h->id], array_column($this->threads('leaderB')['items'], 'groupId'));
        $this->assertSame([], $this->threads('plain')['items']);
    }

    public function testCoordinatorAndCommitteeSeeEveryThreadOfTheirScope()
    {
        $h = $this->group($this->sess, [$this->leaderB]);
        $this->msg($this->leaderB, $h, 'in h', Carbon::now()->subHours(1));
        $this->msg($this->going, $this->g, 'in g', Carbon::now()->subHours(2));

        $this->assertCount(2, $this->threads('coord')['items']);
        $this->assertCount(2, $this->threads('committee')['items']);
        $this->assertCount(2, $this->threads('admin')['items']);

        $elsewhere = $this->session(['date' => '2026-10-13', 'coordinator_member_id' => $this->leaderB->id]);
        $k = $this->group($elsewhere, [$this->leaderB]);
        $this->msg($this->leaderB, $k, 'in k');
        $this->assertCount(2, $this->threads('coord')['items']); // coord does not coordinate k's run
        $this->assertCount(3, $this->threads('committee')['items']);
    }

    public function testThreadsOfLeftGroupsAndNotGoingDisappear()
    {
        $this->msg($this->leaderA, $this->g, 'hi');
        $this->assertCount(1, $this->threads('going')['items']);

        $this->api('PUT', "/sessions/{$this->sess->id}/attendance", 'going', ['status' => 'not_going']);

        $this->assertSame([], $this->threads('going')['items']);
    }

    public function testFourteenDayWindow()
    {
        $old = $this->session(['date' => '2026-09-20']);
        $oldGroup = $this->group($old, [$this->leaderA]);
        $edge = $this->session(['date' => '2026-09-30']);
        $edgeGroup = $this->group($edge, [$this->leaderA]);
        $this->msg($this->going, $oldGroup, 'too old', Carbon::now()->subDays(15));
        $this->msg($this->going, $edgeGroup, 'just in', Carbon::now()->subDays(13));

        $body = $this->threads('leaderA');

        $this->assertSame([$edgeGroup->id], array_column($body['items'], 'groupId'));
        $this->assertTrue($body['items'][0]['closed']); // that run ended long ago, but it can still be read
    }

    public function testUnreadCountIgnoresOwnAndDeletedMessagesAndFollowsTheReadMarker()
    {
        $this->msg($this->going, $this->g, 'a', Carbon::now()->subMinutes(30));
        $deleted = $this->msg($this->going, $this->g, 'b', Carbon::now()->subMinutes(20));
        $deleted->delete();
        $this->msg($this->leaderA, $this->g, 'mine', Carbon::now()->subMinutes(10));
        $this->msg($this->going, $this->g, 'c', Carbon::now()->subMinutes(5));

        $this->assertSame(2, $this->threads('leaderA')['items'][0]['unreadCount']);
        $this->assertSame(1, $this->threads('going')['items'][0]['unreadCount']); // only leaderA's message

        GroupThreadState::create([
            'club_id' => 1, 'group_id' => $this->g->id, 'member_id' => $this->leaderA->id,
            'last_read_at' => Carbon::now()->subMinutes(15),
        ]);

        $this->assertSame(1, $this->threads('leaderA')['items'][0]['unreadCount']);
    }

    public function testDeletedMessagesNeverShowAsTheLastMessage()
    {
        $this->msg($this->going, $this->g, 'kept', Carbon::now()->subMinutes(30));
        $this->msg($this->going, $this->g, 'removed', Carbon::now()->subMinutes(5))->delete();

        $item = $this->threads('leaderA')['items'][0];

        $this->assertSame('kept', $item['lastMessage']['body']);
        $this->assertSame(1, $item['unreadCount']);
    }

    public function testAThreadWithOnlyDeletedMessagesIsNotListed()
    {
        $this->msg($this->going, $this->g, 'removed')->delete();

        $this->assertSame([], $this->threads('leaderA')['items']);
    }

    public function testMutedAndClosedFlags()
    {
        $this->msg($this->going, $this->g, 'hi');
        $this->api('PUT', "/groups/{$this->g->id}/thread", 'leaderA', ['muted' => true]);

        $item = $this->threads('leaderA')['items'][0];
        $this->assertTrue($item['muted']);
        $this->assertFalse($item['closed']);

        $this->api('POST', "/sessions/{$this->sess->id}/cancel", 'committee');
        $this->assertTrue($this->threads('leaderA')['items'][0]['closed']);
    }

    public function testDeletedRunsAndGroupsAreNotListed()
    {
        $this->msg($this->going, $this->g, 'hi');
        $this->api('DELETE', "/groups/{$this->g->id}", 'committee');

        $this->assertSame([], $this->threads('leaderA')['items']);
    }

    public function testOtherClubsThreadsAreNeverListed()
    {
        $this->otherClub();
        $foreign = \App\Models\ClubMember::create(['club_id' => 2, 'athlete_id' => 999, 'display_name' => 'Far', 'roles' => ['admin']]);
        \App\Models\MemberLogin::create(['club_id' => 2, 'member_id' => $foreign->id, 'user_id' => 'foreign', 'linked_at' => Carbon::now()]);
        $this->msg($this->going, $this->g, 'hi');

        [$status, $body] = $this->call_('GET', '/app/clubs/2/threads', 'foreign');

        $this->assertSame(200, $status);
        $this->assertSame([], $body['items']);
    }
}
