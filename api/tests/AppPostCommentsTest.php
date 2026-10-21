<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Models\Notification;
use App\Models\Post;
use App\Models\PostComment;
use App\Models\PostThreadState;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Comments on a club update (D126): a Q&A thread under each post. Everyone the
 * update is for reads and writes it; the committee moderates, replies and can
 * close it.
 */
class AppPostCommentsTest extends AppApiTestCase
{
    private $committee;
    private $admin;
    private $abi;
    private $ben;
    private $leader;

    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
        $this->committee = $this->member('u|c', 3, ['committee'], 'active', 'Cass');
        $this->admin = $this->member('u|a', 4, ['admin'], 'active', 'Ada');
        $this->abi = $this->member('u|abi', 1, [], 'active', 'Abi');
        $this->ben = $this->member('u|ben', 2, [], 'active', 'Ben');
        $this->leader = $this->member('u|l', 6, ['leader'], 'active', 'Lee');
    }

    private function publish(array $overrides = []): string
    {
        [, $post] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', $overrides + ['title' => 'Track night', 'bodyMd' => 'Hello']);

        return $post['id'];
    }

    private function base(string $postId): string
    {
        return "/app/clubs/1/posts/$postId/comments";
    }

    private function say(string $sub, string $postId, string $body, ?string $id = null): array
    {
        return $this->call_('POST', $this->base($postId) . '/messages', $sub, ['body' => $body] + ($id ? ['id' => $id] : []));
    }

    private function read(string $sub, string $postId, string $query = ''): array
    {
        return $this->call_('GET', $this->base($postId) . '/messages' . $query, $sub);
    }

    private function inbox(string $sub, string $postId)
    {
        $member = [
            'u|c' => $this->committee, 'u|a' => $this->admin, 'u|abi' => $this->abi, 'u|ben' => $this->ben, 'u|l' => $this->leader,
        ][$sub];

        return Notification::where('member_id', $member->id)->where('dedupe_key', 'post_comment:' . $postId)->get();
    }

    // ---- who can see and write ---------------------------------------------------------

    public function testAnyoneTheUpdateIsForCanReadAndComment()
    {
        $id = $this->publish();

        [$status, $m] = $this->say('u|abi', $id, 'What time does the track open?');

        $this->assertSame(201, $status);
        $this->assertSame('post:' . $id, $m['groupId']);
        $this->assertSame('member', $m['authorRole']);
        $this->assertSame('Abi L.', $m['authorName']);

        // Another member reads the whole thread.
        [, $body] = $this->read('u|ben', $id);
        $this->assertSame(['What time does the track open?'], array_column($body['items'], 'body'));
        $this->assertFalse($body['closed']);
        $this->assertFalse($body['muted']);
    }

    public function testCommitteeRepliesCarryTheCommitteeRole()
    {
        $id = $this->publish();
        $this->say('u|abi', $id, 'Question?');

        [, $reply] = $this->say('u|c', $id, 'Seven o clock');

        $this->assertSame('committee', $reply['authorRole']);
        [, $body] = $this->read('u|abi', $id);
        $this->assertSame(['member', 'committee'], array_column($body['items'], 'authorRole'));
    }

    public function testAnUpdateForLeadersIsHiddenFromOtherMembers()
    {
        $id = $this->publish(['audience' => 'leaders']);

        $this->assertSame(404, $this->read('u|abi', $id)[0]);
        $this->assertSame(404, $this->say('u|abi', $id, 'hi')[0]);
        $this->assertSame(200, $this->read('u|l', $id)[0]);
        $this->assertSame(201, $this->say('u|l', $id, 'hi')[0]);
    }

    public function testUnknownDeletedAndOtherClubsPostsAre404()
    {
        $this->assertSame(404, $this->read('u|abi', '00000000-0000-4000-8000-000000000000')[0]);

        $id = $this->publish();
        $this->call_('DELETE', "/app/clubs/1/posts/$id", 'u|c');
        $this->assertSame(404, $this->read('u|abi', $id)[0]);
        $this->assertSame(401, $this->call_('GET', $this->base($id) . '/messages', null)[0]);
    }

    public function testValidationReplayAndConflict()
    {
        $id = $this->publish();

        $this->assertSame(422, $this->say('u|abi', $id, '')[0]);
        $this->assertSame(422, $this->say('u|abi', $id, str_repeat('x', 1001))[0]);

        $cid = (string) \Illuminate\Support\Str::uuid();
        $this->assertSame(201, $this->say('u|abi', $id, 'hello', $cid)[0]);
        $this->assertSame(200, $this->say('u|abi', $id, 'hello', $cid)[0]);
        $this->assertSame(409, $this->say('u|ben', $id, 'hello', $cid)[0]);
        $this->assertSame(1, PostComment::count());
    }

    // ---- closing ----------------------------------------------------------------------

    public function testTheCommitteeCanCloseAndReopenComments()
    {
        $id = $this->publish();
        $this->say('u|abi', $id, 'Before');

        [$status] = $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|abi', ['commentsClosed' => true]);
        $this->assertSame(403, $status); // members can't

        $this->assertSame(200, $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|c', ['commentsClosed' => true])[0]);

        [$status, $body] = $this->say('u|abi', $id, 'After');
        $this->assertSame(409, $status);
        $this->assertSame('comments_closed', $body['error']);
        [, $read] = $this->read('u|abi', $id);
        $this->assertTrue($read['closed']);
        // The committee can still reply.
        $this->assertSame(201, $this->say('u|c', $id, 'Closing this now')[0]);
        $this->assertTrue($this->read('u|c', $id)[1]['closed']); // the flag is the same for all

        $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|c', ['commentsClosed' => false]);
        $this->assertSame(201, $this->say('u|abi', $id, 'Reopened')[0]);
        $this->assertNull(Post::find($id)->comments_closed_at);
    }

    public function testEditingAPostLeavesCommentsClosedAlone()
    {
        $id = $this->publish();
        $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|c', ['commentsClosed' => true]);
        $closedAt = Post::find($id)->comments_closed_at;

        $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|c', ['title' => 'Renamed']);
        $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|c', ['commentsClosed' => true]);

        $this->assertSame($closedAt->toIso8601String(), Post::find($id)->comments_closed_at->toIso8601String());
    }

    // ---- delete ------------------------------------------------------------------------

    public function testDeleteIsForTheAuthorOrTheCommitteeAndLeavesATombstone()
    {
        $id = $this->publish();
        [, $m] = $this->say('u|abi', $id, 'oops');
        $before = Carbon::now()->subSecond()->toIso8601String();

        $this->assertSame(403, $this->call_('DELETE', $this->base($id) . '/messages/' . $m['id'], 'u|ben')[0]);
        $this->assertSame(404, $this->call_('DELETE', $this->base($id) . '/messages/00000000-0000-4000-8000-000000000000', 'u|c')[0]);

        Carbon::setTestNow(Carbon::now()->addMinute());
        $this->assertSame(204, $this->call_('DELETE', $this->base($id) . '/messages/' . $m['id'], 'u|c')[0]);
        $this->assertSame(204, $this->call_('DELETE', $this->base($id) . '/messages/' . $m['id'], 'u|abi')[0]);

        [, $body] = $this->read('u|ben', $id, '?since=' . urlencode($before));
        $this->assertNotNull($body['items'][0]['deletedAt']);
        $this->assertSame('', $body['items'][0]['body']);
        $this->assertSame([], $this->read('u|ben', $id)[1]['items']);
        Carbon::setTestNow();
    }

    // ---- who hears about it -------------------------------------------------------------

    public function testAQuestionNotifiesTheCommitteeOnly()
    {
        $id = $this->publish();
        $this->read('u|ben', $id); // reading alone doesn't make Ben a participant

        $this->say('u|abi', $id, 'Is it open to non-members?');

        $this->assertCount(1, $this->inbox('u|c', $id));
        $this->assertCount(1, $this->inbox('u|a', $id));
        $this->assertCount(0, $this->inbox('u|abi', $id)); // not the author
        $this->assertCount(0, $this->inbox('u|ben', $id));
        $n = $this->inbox('u|c', $id)->first();
        $this->assertSame('club_updates', $n->category);
        $this->assertSame('/updates/' . $id . '/comments', $n->data['route']);
        $this->assertStringContainsString('Track night', $n->title);
    }

    public function testAReplyNotifiesWhoAskedAndWhoOpenedTheThread()
    {
        $id = $this->publish();
        $this->say('u|abi', $id, 'Question?');
        $this->call_('POST', $this->base($id) . '/messages/read', 'u|ben'); // Ben opened the thread
        $this->call_('POST', $this->base($id) . '/messages/read', 'u|l'); // so did Lee, then muted it
        $this->call_('PUT', $this->base($id) . '/thread', 'u|l', ['muted' => true]);

        $this->say('u|c', $id, 'Yes, all welcome');

        $this->assertCount(1, $this->inbox('u|abi', $id));
        $this->assertCount(1, $this->inbox('u|ben', $id));
        $this->assertCount(0, $this->inbox('u|l', $id)); // muted
        $this->assertCount(0, $this->inbox('u|c', $id) ->where('title', 'like', 'Cass%')); // not the author
        $this->assertStringContainsString('(committee)', $this->inbox('u|abi', $id)->first()->title);
    }

    // ---- read state and the list -----------------------------------------------------------

    public function testMarkReadClearsTheInboxRowAndTheUnreadCount()
    {
        $id = $this->publish();
        $this->say('u|abi', $id, 'one');
        $this->say('u|abi', $id, 'two');

        $unread = function (string $sub) use ($id) {
            [, $body] = $this->call_('GET', '/app/clubs/1/threads', $sub);

            return collect($body['items'])->firstWhere('groupId', 'post:' . $id)['unreadCount'] ?? null;
        };

        $this->assertSame(2, $unread('u|c'));
        $this->assertCount(1, $this->inbox('u|c', $id)->whereNull('read_at'));

        $this->assertSame(204, $this->call_('POST', $this->base($id) . '/messages/read', 'u|c')[0]);

        $this->assertSame(0, $unread('u|c'));
        $this->assertCount(0, $this->inbox('u|c', $id)->whereNull('read_at'));
        $this->assertSame(0, $unread('u|abi')); // their own comments don't count
    }

    public function testTheThreadsListHasUpdateThreadsForTheCommitteeAndParticipants()
    {
        $id = $this->publish(['title' => 'Summer social']);
        $this->say('u|abi', $id, 'Can I bring a friend?');

        [, $committee] = $this->call_('GET', '/app/clubs/1/threads', 'u|c');
        $item = collect($committee['items'])->firstWhere('kind', 'post');
        $this->assertSame('post:' . $id, $item['groupId']);
        $this->assertSame('Summer social', $item['label']);
        $this->assertSame('Can I bring a friend?', $item['lastMessage']['body']);
        $this->assertFalse($item['closed']);

        // The asker has it; someone who never wrote or opened it doesn't.
        $this->assertNotNull(collect($this->call_('GET', '/app/clubs/1/threads', 'u|abi')[1]['items'])->firstWhere('kind', 'post'));
        $this->assertNull(collect($this->call_('GET', '/app/clubs/1/threads', 'u|ben')[1]['items'])->firstWhere('kind', 'post'));

        // Opening it brings it into Ben's list.
        $this->call_('POST', $this->base($id) . '/messages/read', 'u|ben');
        $this->assertNotNull(collect($this->call_('GET', '/app/clubs/1/threads', 'u|ben')[1]['items'])->firstWhere('kind', 'post'));
        $this->assertSame(1, PostThreadState::where('member_id', $this->ben->id)->count());
    }

    public function testClosedShowsInTheListForEveryone()
    {
        $id = $this->publish();
        $this->say('u|abi', $id, 'q');
        $this->call_('PATCH', "/app/clubs/1/posts/$id", 'u|c', ['commentsClosed' => true]);

        $abi = collect($this->call_('GET', '/app/clubs/1/threads', 'u|abi')[1]['items'])->firstWhere('kind', 'post');
        $cass = collect($this->call_('GET', '/app/clubs/1/threads', 'u|c')[1]['items'])->firstWhere('kind', 'post');

        $this->assertTrue($abi['closed']);
        $this->assertTrue($cass['closed']);
    }

    public function testMuteReturnsTheState()
    {
        $id = $this->publish();

        [$status, $body] = $this->call_('PUT', $this->base($id) . '/thread', 'u|abi', ['muted' => true]);

        $this->assertSame(200, $status);
        $this->assertTrue($body['muted']);
        $this->assertTrue($this->read('u|abi', $id)[1]['muted']);
        $this->assertSame(422, $this->call_('PUT', $this->base($id) . '/thread', 'u|abi', [])[0]);
    }
}
