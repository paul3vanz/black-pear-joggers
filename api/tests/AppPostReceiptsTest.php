<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Models\Notification;
use App\Models\PostReceipt;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Delivered / read receipts for club updates (D123): members report their own,
 * the committee reads them back.
 */
class AppPostReceiptsTest extends AppApiTestCase
{
    private $committee;
    private $a;
    private $b;
    private $leader;

    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
        $this->committee = $this->member('u|c', 3, ['committee'], 'active', 'Cass');
        $this->a = $this->member('u|a', 1, [], 'active', 'Abi');
        $this->b = $this->member('u|b', 2, [], 'active', 'Ben');
        $this->leader = $this->member('u|l', 6, ['leader'], 'active', 'Lee');
        $this->member('u|lapsed', 5, [], 'lapsed');
    }

    private function publish(array $overrides = []): string
    {
        [, $post] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', $overrides + [
            'title' => 'News', 'bodyMd' => 'Hello', 'notify' => true,
        ]);

        return $post['id'];
    }

    private function report(string $sub, array $items): array
    {
        return $this->call_('POST', '/app/clubs/1/posts/receipts', $sub, ['items' => $items]);
    }

    private function receipts(string $postId, string $sub = 'u|c'): array
    {
        return $this->call_('GET', "/app/clubs/1/posts/$postId/receipts", $sub);
    }

    private function state(array $body, string $name): string
    {
        foreach ($body['members'] as $m) {
            if ($m['displayName'] === $name) {
                return $m['state'];
            }
        }

        $this->fail("No $name in receipts");
    }

    public function testNobodyHasSeenItAtFirstAndTheAuthorAndLapsedAreNotCounted()
    {
        $id = $this->publish();

        [$status, $body] = $this->receipts($id);

        $this->assertSame(200, $status);
        $this->assertSame(3, $body['audienceCount']); // a, b, leader
        $this->assertSame(0, $body['deliveredCount']);
        $this->assertSame(0, $body['readCount']);
        $this->assertSame(['Abi Last1', 'Ben Last2', 'Lee Last6'], array_column($body['members'], 'displayName'));
        $this->assertSame('none', $this->state($body, 'Abi Last1'));
    }

    public function testDeliveredAndReadAreReportedByTheMember()
    {
        $id = $this->publish();

        [$status] = $this->report('u|a', [['postId' => $id, 'state' => 'delivered']]);
        $this->assertSame(204, $status);
        $this->report('u|b', [['postId' => $id, 'state' => 'read']]);

        [, $body] = $this->receipts($id);

        $this->assertSame('delivered', $this->state($body, 'Abi Last1'));
        // Read implies delivered.
        $this->assertSame('read', $this->state($body, 'Ben Last2'));
        $this->assertSame('none', $this->state($body, 'Lee Last6'));
        $this->assertSame(2, $body['deliveredCount']);
        $this->assertSame(1, $body['readCount']);
        $ben = collect($body['members'])->firstWhere('displayName', 'Ben Last2');
        $this->assertNotNull($ben['deliveredAt']);
        $this->assertNotNull($ben['readAt']);
    }

    public function testReportsAreIdempotentAndNeverGoBackwards()
    {
        $id = $this->publish();
        $early = Carbon::now()->subHour()->toIso8601String();

        $this->report('u|a', [['postId' => $id, 'state' => 'read', 'at' => $early]]);
        $this->report('u|a', [['postId' => $id, 'state' => 'delivered']]); // later, weaker
        $this->report('u|a', [['postId' => $id, 'state' => 'read']]); // a replay

        $this->assertSame(1, PostReceipt::count());
        $row = PostReceipt::first();
        $this->assertNotNull($row->read_at);
        $this->assertTrue($row->read_at->lessThan(Carbon::now()->subMinutes(30)));
        $this->assertTrue($row->delivered_at->lessThan(Carbon::now()->subMinutes(30)));
    }

    public function testATimeInTheFutureIsClampedToNow()
    {
        $id = $this->publish();

        $this->report('u|a', [['postId' => $id, 'state' => 'read', 'at' => Carbon::now()->addDay()->toIso8601String()]]);

        $this->assertTrue(PostReceipt::first()->read_at->lessThanOrEqualTo(Carbon::now()));
    }

    public function testAPushAcceptedByFirebaseCountsAsDelivered()
    {
        $id = $this->publish();
        Notification::where('member_id', $this->a->id)->update(['pushed_at' => Carbon::now()]);

        [, $body] = $this->receipts($id);

        $this->assertSame('delivered', $this->state($body, 'Abi Last1'));
        $this->assertSame('none', $this->state($body, 'Ben Last2'));
    }

    public function testOnlyMembersInTheAudienceAreCountedAndCanReport()
    {
        $id = $this->publish(['audience' => 'leaders']);

        // A plain member can't see a leaders post: ignored, nothing stored.
        [$status] = $this->report('u|a', [['postId' => $id, 'state' => 'read']]);
        $this->assertSame(204, $status);
        $this->assertSame(0, PostReceipt::count());

        $this->report('u|l', [['postId' => $id, 'state' => 'read']]);
        [, $body] = $this->receipts($id);
        $this->assertSame(1, $body['audienceCount']);
        $this->assertSame('read', $this->state($body, 'Lee Last6'));
    }

    public function testTheAuthorAndOtherClubsPostsAreIgnored()
    {
        $id = $this->publish();

        $this->report('u|c', [['postId' => $id, 'state' => 'read']]);
        $this->report('u|a', [['postId' => '00000000-0000-4000-8000-000000000000', 'state' => 'read']]);

        $this->assertSame(0, PostReceipt::count());
    }

    public function testOnlyTheCommitteeCanReadReceipts()
    {
        $id = $this->publish();

        [$status] = $this->receipts($id, 'u|a');
        $this->assertSame(403, $status);

        [$status] = $this->receipts($id, 'u|l');
        $this->assertSame(403, $status);

        [$status] = $this->receipts('00000000-0000-4000-8000-000000000000');
        $this->assertSame(404, $status);
    }

    public function testValidation()
    {
        $id = $this->publish();

        [$status] = $this->report('u|a', [['postId' => $id, 'state' => 'seen']]);
        $this->assertSame(422, $status);

        [$status] = $this->report('u|a', [['postId' => 'nope', 'state' => 'read']]);
        $this->assertSame(422, $status);

        [$status] = $this->call_('POST', '/app/clubs/1/posts/receipts', 'u|a', []);
        $this->assertSame(422, $status);

        $tooMany = array_fill(0, 101, ['postId' => $id, 'state' => 'delivered']);
        [$status] = $this->report('u|a', $tooMany);
        $this->assertSame(422, $status);
    }

    public function testABatchRecordsEveryPost()
    {
        $one = $this->publish(['title' => 'One']);
        $two = $this->publish(['title' => 'Two']);

        $this->report('u|a', [
            ['postId' => $one, 'state' => 'delivered'],
            ['postId' => $two, 'state' => 'read'],
        ]);

        $this->assertSame('delivered', $this->state($this->receipts($one)[1], 'Abi Last1'));
        $this->assertSame('read', $this->state($this->receipts($two)[1], 'Abi Last1'));
    }
}
