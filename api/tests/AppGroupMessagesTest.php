<?php

require_once __DIR__ . '/AppMessagesBase.php';

use App\Models\GroupMessage;
use App\Models\GroupThreadState;
use App\Models\Notification;
use App\Models\SessionGroup;
use Illuminate\Support\Carbon;

/**
 * Phase 6a: who may use a group thread, and GET / POST / DELETE / read / mute.
 */
class AppGroupMessagesTest extends AppMessagesBase
{
    // ---- who is in the thread ------------------------------------------------------

    public function testParticipantsMatrix()
    {
        $maybe = $this->member('maybe', 302);
        $this->attend($this->sess, $maybe, 'maybe', $this->g);
        $elsewhere = $this->member('elsewhere', 303);
        $h = $this->group($this->sess, [$this->leaderB]);
        $this->attend($this->sess, $elsewhere, 'going', $h);
        $out = $this->member('out', 304);
        $this->attend($this->sess, $out, 'not_going', $this->g); // a stale group id must not count
        $outsider = $this->member('outsider', 305);

        $allowed = ['leaderA', 'going', 'maybe', 'coord', 'committee', 'admin'];
        $denied = ['plain', 'leaderB', 'elsewhere', 'out', 'outsider'];

        foreach ($allowed as $sub) {
            [$status] = $this->messagesOf($sub, $this->g);
            $this->assertSame(200, $status, "$sub reads");
            [$status] = $this->postMsg($sub, $this->g, "hi from $sub");
            $this->assertSame(201, $status, "$sub posts");
            $this->tick(5);
        }

        foreach ($denied as $sub) {
            [$status, $body] = $this->messagesOf($sub, $this->g);
            $this->assertSame(403, $status, "$sub reads");
            $this->assertSame('not_in_group', $body['error']);
            [$status, $body] = $this->postMsg($sub, $this->g, 'let me in');
            $this->assertSame(403, $status, "$sub posts");
            $this->assertSame('not_in_group', $body['error']);
            [$status] = $this->api('POST', "/groups/{$this->g->id}/messages/read", $sub);
            $this->assertSame(403, $status, "$sub marks read");
            [$status] = $this->api('PUT', "/groups/{$this->g->id}/thread", $sub, ['muted' => true]);
            $this->assertSame(403, $status, "$sub mutes");
        }

        $this->assertSame(count($allowed), GroupMessage::count());
    }

    public function testAnotherClubsMemberGetsNotFoundAndUnlinkedGetsNoMembership()
    {
        $this->otherClub();
        $foreign = \App\Models\ClubMember::create(['club_id' => 2, 'athlete_id' => 999, 'display_name' => 'Far Away', 'roles' => ['admin']]);
        \App\Models\MemberLogin::create(['club_id' => 2, 'member_id' => $foreign->id, 'user_id' => 'foreign', 'linked_at' => Carbon::now()]);

        [$status, $body] = $this->call_('GET', "/app/clubs/2/groups/{$this->g->id}/messages", 'foreign');
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);

        [$status, $body] = $this->call_('GET', "/app/clubs/1/groups/{$this->g->id}/messages", 'foreign');
        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);

        [$status] = $this->messagesOf(null, $this->g);
        $this->assertSame(401, $status);
    }

    public function testUnknownGroupIsNotFound()
    {
        [$status, $body] = $this->api('GET', '/groups/' . $this->uuid() . '/messages', 'committee');
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);
    }

    public function testLeavingTheGroupOrSayingNotComingLosesAccessAtOnce()
    {
        [$status] = $this->messagesOf('going', $this->g);
        $this->assertSame(200, $status);

        $this->api('PUT', "/sessions/{$this->sess->id}/attendance", 'going', ['status' => 'going', 'groupId' => null]);
        [$status] = $this->messagesOf('going', $this->g);
        $this->assertSame(403, $status);

        $this->api('PUT', "/sessions/{$this->sess->id}/attendance", 'going', ['status' => 'going', 'groupId' => $this->g->id]);
        [$status] = $this->messagesOf('going', $this->g);
        $this->assertSame(200, $status);

        $this->api('PUT', "/sessions/{$this->sess->id}/attendance", 'going', ['status' => 'not_going']);
        [$status] = $this->messagesOf('going', $this->g);
        $this->assertSame(403, $status);
    }

    public function testAWithdrawnLeaderIsNoLongerInTheThread()
    {
        [$status] = $this->messagesOf('leaderA', $this->g);
        $this->assertSame(200, $status);

        $this->api('DELETE', "/groups/{$this->g->id}/leaders/me", 'leaderA');

        [$status] = $this->messagesOf('leaderA', $this->g);
        $this->assertSame(403, $status);
    }

    public function testADeletedGroupsThreadIsGone()
    {
        $this->msg($this->going, $this->g, 'before');
        $this->api('DELETE', "/groups/{$this->g->id}", 'committee');

        foreach (['committee', 'going', 'leaderA'] as $sub) {
            [$status, $body] = $this->messagesOf($sub, $this->g);
            $this->assertSame(404, $status, $sub);
            $this->assertSame('not_found', $body['error']);
        }

        [$status] = $this->postMsg('committee', $this->g, 'hello?');
        $this->assertSame(404, $status);
        [$status] = $this->api('POST', "/groups/{$this->g->id}/messages/read", 'committee');
        $this->assertSame(404, $status);
        [$status] = $this->api('PUT', "/groups/{$this->g->id}/thread", 'committee', ['muted' => true]);
        $this->assertSame(404, $status);

        [, $body] = $this->api('GET', '/threads', 'committee');
        $this->assertSame([], $body['items']);
    }

    // ---- GET -----------------------------------------------------------------------

    public function testGetWithoutSinceReturnsTheNewestHundredOldestFirstWithoutTombstones()
    {
        $start = Carbon::now()->subHours(2);

        for ($i = 1; $i <= 105; $i++) {
            $this->msg($this->going, $this->g, "m$i", $start->copy()->addSeconds($i));
        }

        $gone = $this->msg($this->going, $this->g, 'gone', $start->copy()->addSeconds(200));
        $gone->delete();

        [$status, $body] = $this->messagesOf('leaderA', $this->g);
        $this->assertSame(200, $status);
        $this->assertCount(100, $body['items']);
        $this->assertSame('m6', $body['items'][0]['body']);
        $this->assertSame('m105', $body['items'][99]['body']);
        $this->assertFalse($body['closed']);
        $this->assertFalse($body['muted']);
        $this->assertSame('2026-10-12T09:00:00.000Z', $body['serverTime']);
    }

    public function testMessageShape()
    {
        $m = $this->msg($this->going, $this->g, 'See you at the car park', Carbon::parse('2026-10-12 08:30:15', 'UTC'));

        [, $body] = $this->messagesOf('leaderA', $this->g);

        $this->assertSame([[
            'id' => $m->id,
            'groupId' => $this->g->id,
            'memberId' => $this->going->id,
            'authorName' => 'Gwen L.',
            'authorRole' => 'member',
            'body' => 'See you at the car park',
            'createdAt' => '2026-10-12T08:30:15.000Z',
            'deletedAt' => null,
        ]], $body['items']);
    }

    public function testAuthorNameFallsBackToMember()
    {
        $ghost = \App\Models\ClubMember::create(['club_id' => 1, 'athlete_id' => 987654, 'display_name' => 'Ghost']);
        $this->attend($this->sess, $ghost, 'going', $this->g);
        $this->msg($ghost, $this->g, 'boo');

        [, $body] = $this->messagesOf('leaderA', $this->g);

        $this->assertSame('Member', $body['items'][0]['authorName']);
    }

    public function testGetWithSinceReturnsChangesAndTombstonesOldestFirst()
    {
        $old = $this->msg($this->going, $this->g, 'old', Carbon::now()->subHours(3));
        $deleted = $this->msg($this->going, $this->g, 'will go', Carbon::now()->subHours(2));
        $kept = $this->msg($this->leaderA, $this->g, 'kept', Carbon::now()->subMinutes(10));
        $since = Carbon::now()->subMinutes(5);
        $this->tick(60);

        $this->api('DELETE', "/groups/{$this->g->id}/messages/{$deleted->id}", 'leaderA');
        $fresh = $this->msg($this->going, $this->g, 'fresh', Carbon::now());

        [$status, $body] = $this->messagesOf('going', $this->g, '?since=' . urlencode($since->toIso8601String()));

        $this->assertSame(200, $status);
        $this->assertSame([$deleted->id, $fresh->id], array_column($body['items'], 'id'));
        $this->assertSame('', $body['items'][0]['body']);
        $this->assertSame('2026-10-12T09:01:00.000Z', $body['items'][0]['deletedAt']);
        $this->assertSame('fresh', $body['items'][1]['body']);
        $this->assertSame('2026-10-12T09:01:00.000Z', $body['serverTime']);

        // since is inclusive and the whole history comes back when it is old enough.
        [, $all] = $this->messagesOf('going', $this->g, '?since=2020-01-01T00:00:00Z');
        $this->assertSame([$old->id, $deleted->id, $kept->id, $fresh->id], array_column($all['items'], 'id'));
    }

    public function testGetSinceIsCappedAtFiveHundred()
    {
        $start = Carbon::now()->subHours(1);

        for ($i = 0; $i < 505; $i++) {
            $this->msg($this->going, $this->g, "m$i", $start->copy()->addSeconds($i));
        }

        [, $body] = $this->messagesOf('going', $this->g, '?since=2020-01-01T00:00:00Z');

        $this->assertCount(500, $body['items']);
        $this->assertSame('m0', $body['items'][0]['body']);
    }

    public function testBadSinceIsA422()
    {
        [$status, $body] = $this->messagesOf('going', $this->g, '?since=not-a-date');

        $this->assertSame(422, $status);
        $this->assertSame('validation_failed', $body['error']);
        $this->assertArrayHasKey('since', $body['errors']);
    }

    public function testClosedFlagFollowsTheRunAndStaysReadable()
    {
        $this->msg($this->going, $this->g, 'hello');

        // The run ended at 19:30Z; 11h59m later it is still open, 12h01m later closed.
        Carbon::setTestNow(Carbon::parse('2026-10-13 07:29:00', 'UTC'));
        [, $body] = $this->messagesOf('going', $this->g);
        $this->assertFalse($body['closed']);

        Carbon::setTestNow(Carbon::parse('2026-10-13 07:31:00', 'UTC'));
        [$status, $body] = $this->messagesOf('going', $this->g);
        $this->assertSame(200, $status);
        $this->assertTrue($body['closed']);
        $this->assertCount(1, $body['items']);
    }

    public function testCancelledRunClosesTheThread()
    {
        $this->api('POST', "/sessions/{$this->sess->id}/cancel", 'committee');

        [, $body] = $this->messagesOf('going', $this->g);
        $this->assertTrue($body['closed']);
    }

    // ---- POST ----------------------------------------------------------------------

    public function testPostCreatesAMessageTrimmedAndWithAClientId()
    {
        $id = $this->uuid();

        [$status, $body] = $this->postMsg('going', $this->g, "  Running 5 minutes late \n", $id);

        $this->assertSame(201, $status);
        $this->assertSame($id, $body['id']);
        $this->assertSame('Running 5 minutes late', $body['body']);
        $this->assertSame($this->g->id, $body['groupId']);
        $this->assertSame($this->going->id, $body['memberId']);
        $this->assertSame('Gwen L.', $body['authorName']);
        $this->assertSame('member', $body['authorRole']);
        $this->assertSame('2026-10-12T09:00:00.000Z', $body['createdAt']);
        $this->assertNull($body['deletedAt']);
        $this->assertSame(1, GroupMessage::where('club_id', 1)->count());
    }

    public function testPostWithoutAnIdGeneratesOne()
    {
        [$status, $body] = $this->postMsg('going', $this->g, 'hi');

        $this->assertSame(201, $status);
        $this->assertTrue(\Illuminate\Support\Str::isUuid($body['id']));
    }

    public function testPostValidation()
    {
        $cases = [
            'empty' => [''],
            'whitespace' => ["   \n\t "],
            'too long' => [str_repeat('a', 1001)],
            'not a string' => [['x']],
        ];

        foreach ($cases as $name => [$value]) {
            [$status, $body] = $this->postMsg('going', $this->g, $value);
            $this->assertSame(422, $status, $name);
            $this->assertSame('validation_failed', $body['error'], $name);
            $this->assertArrayHasKey('body', $body['errors'], $name);
        }

        [$status, $body] = $this->api('POST', "/groups/{$this->g->id}/messages", 'going', []);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('body', $body['errors']);

        [$status, $body] = $this->postMsg('going', $this->g, 'fine', 'not-a-uuid');
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('id', $body['errors']);

        $this->assertSame(0, GroupMessage::count());
    }

    public function testExactlyOneThousandCharactersIsAllowed()
    {
        [$status] = $this->postMsg('going', $this->g, str_repeat('é', 1000));

        $this->assertSame(201, $status);
    }

    public function testReplayOfTheSameIdReturnsTheStoredMessageWithoutANewRow()
    {
        $id = $this->uuid();
        $this->postMsg('going', $this->g, 'first', $id);
        $this->tick(30);

        [$status, $body] = $this->postMsg('going', $this->g, 'a different body', $id);

        $this->assertSame(200, $status);
        $this->assertSame('first', $body['body']);
        $this->assertSame($id, $body['id']);
        $this->assertSame(1, GroupMessage::count());
    }

    public function testAnotherMembersIdIsAConflict()
    {
        $id = $this->uuid();
        $this->postMsg('going', $this->g, 'mine', $id);

        [$status, $body] = $this->postMsg('leaderA', $this->g, 'stolen', $id);

        $this->assertSame(409, $status);
        $this->assertSame('conflict', $body['error']);
        $this->assertSame(1, GroupMessage::count());
    }

    public function testTheSameIdInAnotherGroupIsAConflict()
    {
        $h = $this->group($this->sess, [$this->leaderB]);
        $id = $this->uuid();
        $this->postMsg('committee', $h, 'in h', $id);

        [$status, $body] = $this->postMsg('committee', $this->g, 'in g', $id);

        $this->assertSame(409, $status);
        $this->assertSame('conflict', $body['error']);
        $this->assertSame(1, GroupMessage::count());
    }

    public function testReplayStillWorksAfterTheThreadClosesButNewMessagesAreRefused()
    {
        $id = $this->uuid();
        $this->postMsg('going', $this->g, 'sent just before', $id);

        Carbon::setTestNow(Carbon::parse('2026-10-13 08:00:00', 'UTC')); // more than 12h after the run ended

        [$status, $body] = $this->postMsg('going', $this->g, 'sent just before', $id);
        $this->assertSame(200, $status);

        [$status, $body] = $this->postMsg('going', $this->g, 'too late');
        $this->assertSame(409, $status);
        $this->assertSame('thread_closed', $body['error']);
        $this->assertNotEmpty($body['message']);
        $this->assertSame(1, GroupMessage::count());
    }

    public function testPostingIsOpenJustBeforeTwelveHoursAfterTheRunEnds()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-13 07:29:00', 'UTC')); // run ended 19:30Z

        [$status] = $this->postMsg('going', $this->g, 'still open');
        $this->assertSame(201, $status);

        Carbon::setTestNow(Carbon::parse('2026-10-13 07:31:00', 'UTC'));
        [$status, $body] = $this->postMsg('going', $this->g, 'closed now');
        $this->assertSame(409, $status);
        $this->assertSame('thread_closed', $body['error']);
    }

    public function testPostingToACancelledRunIsRefused()
    {
        $this->api('POST', "/sessions/{$this->sess->id}/cancel", 'committee');

        [$status, $body] = $this->postMsg('going', $this->g, 'is it on?');

        $this->assertSame(409, $status);
        $this->assertSame('thread_closed', $body['error']);
        $this->assertStringContainsString('cancelled', $body['message']);

        $this->api('POST', "/sessions/{$this->sess->id}/restore", 'committee');
        [$status] = $this->postMsg('going', $this->g, 'is it on?');
        $this->assertSame(201, $status);
    }

    public function testValidationComesBeforeTheClosedCheck()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-14 08:00:00', 'UTC'));

        [$status] = $this->postMsg('going', $this->g, '');
        $this->assertSame(422, $status);
        [$status] = $this->postMsg('plain', $this->g, '');
        $this->assertSame(403, $status);
    }

    public function testRateLimitIsTwentyPerMinutePerMember()
    {
        for ($i = 1; $i <= 20; $i++) {
            [$status] = $this->postMsg('going', $this->g, "m$i");
            $this->assertSame(201, $status, "message $i");
        }

        [$status, $body] = $this->postMsg('going', $this->g, 'm21');
        $this->assertSame(429, $status);
        $this->assertSame('too_many_requests', $body['error']);
        $this->assertTrue($this->response->headers->has('Retry-After'));

        // Other members are not affected, and a replay is not a new message.
        [$status] = $this->postMsg('leaderA', $this->g, 'still fine');
        $this->assertSame(201, $status);
        $first = GroupMessage::where('member_id', $this->going->id)->first();
        [$status] = $this->postMsg('going', $this->g, 'm1', $first->id);
        $this->assertSame(200, $status);

        // Deleting does not free a slot; waiting does.
        $first->delete();
        [$status] = $this->postMsg('going', $this->g, 'm22');
        $this->assertSame(429, $status);

        $this->tick(61);
        [$status] = $this->postMsg('going', $this->g, 'm22');
        $this->assertSame(201, $status);
        $this->assertSame(21, GroupMessage::withTrashed()->where('member_id', $this->going->id)->count());
    }

    // ---- author role ---------------------------------------------------------------

    public function testAuthorRolePrecedence()
    {
        // coord leads the group too, committee coordinates, admin also attends.
        $this->attend($this->sess, $this->admin, 'going', $this->g);
        \App\Models\SessionGroupLeader::create(['club_id' => 1, 'group_id' => $this->g->id, 'member_id' => $this->coord->id]);
        $this->sess->forceFill(['coordinator_member_id' => $this->coord->id])->save();
        $ids = [];

        foreach (['coord', 'committee', 'admin', 'going', 'leaderA'] as $sub) {
            [, $body] = $this->postMsg($sub, $this->g, "from $sub");
            $ids[$sub] = $body['authorRole'];
            $this->tick(2);
        }

        $this->assertSame([
            'coord' => 'leader',      // leader of this group beats coordinator
            'committee' => 'committee',
            'admin' => 'committee',
            'going' => 'member',
            'leaderA' => 'leader',
        ], $ids);

        // Coordinator who is not leading, and committee who is also the coordinator.
        \App\Models\SessionGroupLeader::where('member_id', $this->coord->id)->delete();
        [, $body] = $this->messagesOf('committee', $this->g);
        $roles = array_column($body['items'], 'authorRole', 'memberId');
        $this->assertSame('coordinator', $roles[$this->coord->id]);

        $this->sess->forceFill(['coordinator_member_id' => $this->committee->id])->save();
        [, $body] = $this->messagesOf('committee', $this->g);
        $roles = array_column($body['items'], 'authorRole', 'memberId');
        $this->assertSame('coordinator', $roles[$this->committee->id]); // coordinator beats committee
        $this->assertSame('committee', $roles[$this->admin->id]);
        $this->assertSame('member', $roles[$this->coord->id]);
    }

    // ---- DELETE --------------------------------------------------------------------

    public function testDeletePermissions()
    {
        $this->attend($this->sess, $this->plain, 'going', $this->g);
        $byGoing = $this->msg($this->going, $this->g, 'x');

        // Another ordinary participant: forbidden. A non-participant: not_in_group.
        [$status, $body] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$byGoing->id}", 'plain');
        $this->assertSame(403, $status);
        $this->assertSame('forbidden', $body['error']);
        $this->assertNull(GroupMessage::find($byGoing->id)->deleted_at);

        [$status, $body] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$byGoing->id}", 'leaderB');
        $this->assertSame(403, $status);
        $this->assertSame('not_in_group', $body['error']);

        foreach (['going', 'leaderA', 'coord', 'committee', 'admin'] as $sub) {
            $m = $this->msg($this->going, $this->g, "by going for $sub");
            [$status] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$m->id}", $sub);
            $this->assertSame(204, $status, $sub);
            $this->assertNotNull(GroupMessage::withTrashed()->find($m->id)->deleted_at, $sub);
        }
    }

    public function testAuthorCanDeleteTheirOwnLeaderCanDeleteAnyoneAndTombstoneSyncs()
    {
        $m = $this->msg($this->leaderA, $this->g, 'leader says');
        $this->tick(60);

        [$status] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$m->id}", 'going');
        $this->assertSame(403, $status);

        [$status, $body] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$m->id}", 'leaderA');
        $this->assertSame(204, $status);
        $this->assertNull($body);

        [, $body] = $this->messagesOf('going', $this->g, '?since=' . urlencode(Carbon::now()->subSeconds(30)->toIso8601String()));
        $this->assertCount(1, $body['items']);
        $this->assertSame('', $body['items'][0]['body']);
        $this->assertNotNull($body['items'][0]['deletedAt']);
    }

    public function testDeleteReplayIsStillNoContentAndDoesNotMoveTheTombstone()
    {
        $m = $this->msg($this->going, $this->g, 'oops');

        $this->api('DELETE', "/groups/{$this->g->id}/messages/{$m->id}", 'going');
        $deletedAt = GroupMessage::withTrashed()->find($m->id)->getRawOriginal('deleted_at');
        $this->tick(120);

        [$status] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$m->id}", 'going');

        $this->assertSame(204, $status);
        $this->assertSame($deletedAt, GroupMessage::withTrashed()->find($m->id)->getRawOriginal('deleted_at'));
    }

    public function testDeleteUnknownMessageOrAnotherGroupsMessageIsNotFound()
    {
        $h = $this->group($this->sess, [$this->leaderB]);
        $other = $this->msg($this->leaderB, $h, 'in h');

        [$status, $body] = $this->api('DELETE', "/groups/{$this->g->id}/messages/" . $this->uuid(), 'leaderA');
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);

        [$status] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$other->id}", 'leaderA');
        $this->assertSame(404, $status);
        $this->assertNull(GroupMessage::find($other->id)->deleted_at);
    }

    public function testModerationStillWorksOnAClosedThread()
    {
        $m = $this->msg($this->going, $this->g, 'rude');
        Carbon::setTestNow(Carbon::parse('2026-10-14 08:00:00', 'UTC'));

        [$status] = $this->api('DELETE', "/groups/{$this->g->id}/messages/{$m->id}", 'leaderA');

        $this->assertSame(204, $status);
    }

    // ---- read marker and mute ------------------------------------------------------

    public function testReadMarkerSetsLastReadAtAndResetsTheUnreadCount()
    {
        $this->msg($this->going, $this->g, 'one', Carbon::now()->subMinutes(5));
        $this->msg($this->going, $this->g, 'two', Carbon::now()->subMinutes(4));
        $this->msg($this->leaderA, $this->g, 'mine', Carbon::now()->subMinutes(3));

        [, $body] = $this->api('GET', '/threads', 'leaderA');
        $this->assertSame(2, $body['items'][0]['unreadCount']);

        [$status] = $this->api('POST', "/groups/{$this->g->id}/messages/read", 'leaderA');
        $this->assertSame(204, $status);

        $state = GroupThreadState::where('member_id', $this->leaderA->id)->first();
        $this->assertSame('2026-10-12 09:00:00', $state->getRawOriginal('last_read_at'));
        $this->assertFalse($state->muted);

        [, $body] = $this->api('GET', '/threads', 'leaderA');
        $this->assertSame(0, $body['items'][0]['unreadCount']);

        $this->tick(60);
        $this->msg($this->going, $this->g, 'three');
        [, $body] = $this->api('GET', '/threads', 'leaderA');
        $this->assertSame(1, $body['items'][0]['unreadCount']);

        // Reading again keeps one state row.
        $this->api('POST', "/groups/{$this->g->id}/messages/read", 'leaderA');
        $this->assertSame(1, GroupThreadState::where('member_id', $this->leaderA->id)->count());
    }

    public function testReadingTheThreadMarksItsInboxRowRead()
    {
        // A message from someone else leaves leaderA one inbox row with the thread's key.
        $this->postMsg('going', $this->g, 'see you there');
        $mine = Notification::where('member_id', $this->leaderA->id)->where('dedupe_key', 'group_msg:' . $this->g->id)->first();
        $this->assertNotNull($mine);
        $this->assertNull($mine->read_at);

        $this->api('POST', "/groups/{$this->g->id}/messages/read", 'leaderA');

        $this->assertNotNull($mine->fresh()->read_at);
    }

    public function testReadingOnlyAffectsTheCaller()
    {
        $this->msg($this->going, $this->g, 'hi');
        $this->api('POST', "/groups/{$this->g->id}/messages/read", 'leaderA');

        $this->assertSame(0, GroupThreadState::where('member_id', $this->going->id)->count());
    }

    public function testMutingReturnsTheUnreadCountAndKeepsTheThreadReadable()
    {
        $this->msg($this->going, $this->g, 'one');
        $this->msg($this->going, $this->g, 'two');

        [$status, $body] = $this->api('PUT', "/groups/{$this->g->id}/thread", 'leaderA', ['muted' => true]);
        $this->assertSame(200, $status);
        $this->assertSame(['muted' => true, 'unreadCount' => 2], $body);

        [, $body] = $this->messagesOf('leaderA', $this->g);
        $this->assertTrue($body['muted']);
        $this->assertCount(2, $body['items']);

        [, $body] = $this->api('GET', '/threads', 'leaderA');
        $this->assertTrue($body['items'][0]['muted']);

        [, $body] = $this->api('PUT', "/groups/{$this->g->id}/thread", 'leaderA', ['muted' => false]);
        $this->assertSame(['muted' => false, 'unreadCount' => 2], $body);
        $this->assertFalse(GroupThreadState::where('member_id', $this->leaderA->id)->first()->muted);
    }

    public function testMuteNeedsABoolean()
    {
        foreach ([[], ['muted' => 'maybe'], ['muted' => null]] as $data) {
            [$status, $body] = $this->api('PUT', "/groups/{$this->g->id}/thread", 'leaderA', $data);
            $this->assertSame(422, $status);
            $this->assertSame('validation_failed', $body['error']);
        }
    }

    public function testMutingDoesNotLoseTheReadMarker()
    {
        $this->msg($this->going, $this->g, 'one', Carbon::now()->subMinutes(2));
        $this->api('POST', "/groups/{$this->g->id}/messages/read", 'leaderA');
        $this->api('PUT', "/groups/{$this->g->id}/thread", 'leaderA', ['muted' => true]);

        $state = GroupThreadState::where('member_id', $this->leaderA->id)->first();
        $this->assertNotNull($state->last_read_at);
        $this->assertTrue($state->muted);
    }
}
