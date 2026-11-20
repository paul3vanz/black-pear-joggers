<?php

require_once __DIR__ . '/AppMessagesBase.php';

use App\Models\ContentReport;
use App\Models\MemberBlock;
use App\Models\Notification;
use Illuminate\Support\Carbon;

/** Report and block (Apple guideline 1.2). */
class AppSafetyTest extends AppMessagesBase
{
    public function testBlockListsUnblocksAndIsIdempotent()
    {
        [$status, $body] = $this->api('POST', '/blocks', 'plain', ['memberId' => $this->going->id]);
        $this->assertSame(201, $status);
        $this->assertSame($this->going->id, $body['memberId']);
        $this->assertSame('Gwen L.', $body['name']);

        [$status] = $this->api('POST', '/blocks', 'plain', ['memberId' => $this->going->id]);
        $this->assertSame(200, $status);
        $this->assertSame(1, MemberBlock::count());

        [, $list] = $this->api('GET', '/blocks', 'plain');
        $this->assertCount(1, $list['items']);

        // Blocks are personal.
        [, $theirs] = $this->api('GET', '/blocks', 'going');
        $this->assertCount(0, $theirs['items']);

        [$status] = $this->api('DELETE', "/blocks/{$this->going->id}", 'plain');
        $this->assertSame(204, $status);
        [$status] = $this->api('DELETE', "/blocks/{$this->going->id}", 'plain');
        $this->assertSame(204, $status);
        $this->assertSame(0, MemberBlock::count());
    }

    public function testCannotBlockYourselfOrAStranger()
    {
        [$status] = $this->api('POST', '/blocks', 'plain', ['memberId' => $this->plain->id]);
        $this->assertSame(422, $status);

        [$status] = $this->api('POST', '/blocks', 'plain', ['memberId' => $this->uuid()]);
        $this->assertSame(404, $status);

        [$status] = $this->api('POST', '/blocks', 'plain', []);
        $this->assertSame(422, $status);
    }

    public function testBlocksNeedSignIn()
    {
        [$status] = $this->api('GET', '/blocks', null);
        $this->assertSame(401, $status);
    }

    public function testReportAMessageCopiesTheTextAndTellsTheCommittee()
    {
        $message = $this->msg($this->going, $this->g, 'rude words');

        [$status, $body] = $this->api('POST', '/reports', 'plain', [
            'kind' => 'message', 'targetId' => $message->id,
            'reportedMemberId' => $this->going->id, 'reason' => 'abusive', 'details' => 'Not nice',
        ]);

        $this->assertSame(201, $status);
        $report = ContentReport::find($body['id']);
        $this->assertSame('rude words', $report->excerpt);
        $this->assertSame($this->plain->id, $report->reporter_member_id);
        $this->assertSame('open', $report->status);

        foreach ([$this->committee, $this->admin] as $manager) {
            $row = Notification::where('member_id', $manager->id)->where('title', 'Content reported')->first();
            $this->assertNotNull($row, 'committee and admin are told');
            $this->assertSame("/runs/{$this->sess->id}/groups/{$this->g->id}/chat", $row->data['route']);
        }
        $this->assertSame(0, Notification::where('member_id', $this->plain->id)->where('title', 'Content reported')->count());
    }

    public function testReportAProfile()
    {
        [$status] = $this->api('POST', '/reports', 'plain', [
            'kind' => 'profile', 'reportedMemberId' => $this->going->id, 'reason' => 'inappropriate',
        ]);

        $this->assertSame(201, $status);
        $this->assertNull(ContentReport::first()->target_id);
    }

    public function testReportValidation()
    {
        $message = $this->msg($this->going, $this->g);
        $ok = ['kind' => 'message', 'targetId' => $message->id, 'reportedMemberId' => $this->going->id, 'reason' => 'spam'];

        foreach ([
            ['kind' => 'nonsense'],
            ['reason' => 'rude'],
            ['targetId' => null],
            ['reportedMemberId' => $this->plain->id], // yourself
            ['details' => str_repeat('x', 501)],
        ] as $change) {
            [$status] = $this->api('POST', '/reports', 'plain', $change + $ok);
            $this->assertSame(422, $status, json_encode($change));
        }

        // A message written by someone else, or that does not exist.
        [$status] = $this->api('POST', '/reports', 'plain', ['reportedMemberId' => $this->leaderA->id] + $ok);
        $this->assertSame(404, $status);
        [$status] = $this->api('POST', '/reports', 'plain', ['targetId' => $this->uuid()] + $ok);
        $this->assertSame(404, $status);

        $this->assertSame(0, ContentReport::count());
    }

    public function testReportsArePerHourLimited()
    {
        $data = ['kind' => 'profile', 'reportedMemberId' => $this->going->id, 'reason' => 'spam'];

        for ($i = 0; $i < 10; $i++) {
            [$status] = $this->api('POST', '/reports', 'plain', $data);
            $this->assertSame(201, $status);
        }

        [$status, $body] = $this->api('POST', '/reports', 'plain', $data);
        $this->assertSame(429, $status);
        $this->assertSame('too_many_requests', $body['error']);

        Carbon::setTestNow(Carbon::now()->addHours(2));
        [$status] = $this->api('POST', '/reports', 'plain', $data);
        $this->assertSame(201, $status);
    }
}
