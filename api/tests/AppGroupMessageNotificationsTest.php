<?php

require_once __DIR__ . '/AppMessagesBase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\ClubMember;
use App\Models\GroupMessage;
use App\Models\GroupThreadState;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Services\NotificationService;
use App\Services\PaceMatcher;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 6a: what a new group message tells people. Queue is faked (see base).
 * Group g is 9:00-9:30/mi, led by leaderA (Lee), coordinated by coord (Cory),
 * with Gwen going. Pushes are counted as queued SendPushNotificationsJobs.
 */
class AppGroupMessageNotificationsTest extends AppMessagesBase
{
    private function inbox(ClubMember $member): array
    {
        return Notification::where('member_id', $member->id)->where('category', 'group_messages')
            ->orderBy('created_at')->orderBy('id')->get()->all();
    }

    private function pushes(): int
    {
        return Queue::pushed(SendPushNotificationsJob::class)->count();
    }

    public function testAudienceIsLeadersAttendeesAndCoordinatorButNotTheAuthorOrOthers()
    {
        $maybe = $this->member('maybe', 302);
        $this->attend($this->sess, $maybe, 'maybe', $this->g);
        $out = $this->member('out', 303);
        $this->attend($this->sess, $out, 'not_going', $this->g);
        $elsewhere = $this->member('elsewhere', 304);
        $h = $this->group($this->sess, [$this->leaderB]);
        $this->attend($this->sess, $elsewhere, 'going', $h);
        $lapsed = $this->member('lapsed', 305, [], 'lapsed');
        $this->attend($this->sess, $lapsed, 'going', $this->g);

        [$status] = $this->postMsg('going', $this->g, 'Anyone got a spare light?');
        $this->assertSame(201, $status);

        foreach ([$this->leaderA, $maybe, $this->coord] as $who) {
            $rows = $this->inbox($who);
            $this->assertCount(1, $rows, $who->display_name);
            $this->assertSame('group_messages', $rows[0]->category);
            $this->assertSame('Gwen L. · 9:00-9:30/mi', $rows[0]->title);
            $this->assertSame('Anyone got a spare light?', $rows[0]->body);
            $this->assertSame('group_msg:' . $this->g->id, $rows[0]->dedupe_key);
            $this->assertSame([
                'route' => "/runs/{$this->sess->id}/groups/{$this->g->id}/chat",
                'sessionId' => $this->sess->id,
                'groupId' => $this->g->id,
            ], $rows[0]->data);
        }

        // The author, committee/admin who are only moderating, outsiders and inactive members hear nothing.
        foreach ([$this->going, $this->committee, $this->admin, $this->plain, $this->leaderB, $out, $elsewhere, $lapsed] as $who) {
            $this->assertSame([], $this->inbox($who), $who->display_name);
        }

        $this->assertSame(1, $this->pushes());
    }

    public function testCommitteeWhoAreAlsoParticipantsAreNotified()
    {
        $this->attend($this->sess, $this->committee, 'going', $this->g);

        $this->postMsg('going', $this->g, 'hi');

        $this->assertCount(1, $this->inbox($this->committee));
        $this->assertSame([], $this->inbox($this->admin));
    }

    public function testACommitteeMembersMessageNotifiesTheThread()
    {
        $this->postMsg('committee', $this->g, 'Route change tonight');

        $this->assertCount(1, $this->inbox($this->going));
        $this->assertCount(1, $this->inbox($this->leaderA));
        $this->assertSame('Cam L. · 9:00-9:30/mi', $this->inbox($this->going)[0]->title);
        $this->assertSame([], $this->inbox($this->committee));
    }

    public function testTitleUsesTheRecipientsUnits()
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->going->id, 'pace_unit' => 'km']);

        $this->postMsg('leaderA', $this->g, 'See you soon');

        $km = PaceMatcher::format('mi', 540, 570, 'km');
        $this->assertStringEndsWith('/km', $km);
        $this->assertSame('Lee L. · ' . $km, $this->inbox($this->going)[0]->title);
        $this->assertSame('Lee L. · 9:00-9:30/mi', $this->inbox($this->coord)[0]->title);
    }

    public function testGroupLabelIsPartOfTheTitleAndAnUnnamedGroupIsCalledGroup()
    {
        $this->g->forceFill(['label' => 'Social'])->save();
        $this->postMsg('going', $this->g, 'hello');
        $this->assertSame('Gwen L. · Social 9:00-9:30/mi', $this->inbox($this->leaderA)[0]->title);

        $h = $this->group($this->sess, [$this->leaderB]);
        $this->postMsg('leaderB', $h, 'anyone?');
        $this->attend($this->sess, $this->plain, 'going', $h);
        $this->postMsg('leaderB', $h, 'again');
        $this->assertSame('Lou L. · Group', $this->inbox($this->plain)[0]->title);
    }

    public function testBodyIsClippedToOneHundredFortyCharacters()
    {
        $this->postMsg('going', $this->g, str_repeat('word ', 100));

        $body = $this->inbox($this->leaderA)[0]->body;
        $this->assertLessThanOrEqual(140, mb_strlen($body));
        $this->assertStringEndsWith('…', $body);
    }

    public function testABurstIsOneInboxRowWithTheLatestMessageAndOnePush()
    {
        $this->postMsg('going', $this->g, 'first');
        $this->tick(60);
        $this->postMsg('going', $this->g, 'second');
        $this->tick(60);
        $this->postMsg('going', $this->g, 'third');

        $rows = $this->inbox($this->leaderA);
        $this->assertCount(1, $rows);
        $this->assertSame('third', $rows[0]->body);
        $this->assertSame(1, $this->pushes()); // all three inside the 5 minute window
    }

    public function testReplacedRowIsUnreadAgain()
    {
        $this->postMsg('going', $this->g, 'first');
        $row = $this->inbox($this->leaderA)[0];
        $row->forceFill(['read_at' => Carbon::now()])->save();

        $this->tick(30);
        $this->postMsg('going', $this->g, 'second');

        $this->assertNull($this->inbox($this->leaderA)[0]->read_at);
    }

    public function testAPushIsSentAgainOnlyAfterFiveMinutes()
    {
        $this->postMsg('going', $this->g, 'one');
        $this->assertSame(1, $this->pushes());

        $this->tick(4 * 60);
        $this->postMsg('going', $this->g, 'two');
        $this->assertSame(1, $this->pushes());

        $this->tick(2 * 60); // 6 minutes after the push
        $this->postMsg('going', $this->g, 'three');
        $this->assertSame(2, $this->pushes());
        $this->assertCount(1, $this->inbox($this->leaderA));
        $this->assertSame('three', $this->inbox($this->leaderA)[0]->body);
    }

    public function testEachThreadHasItsOwnRow()
    {
        $h = $this->group($this->sess, [$this->leaderB]);
        $this->attend($this->sess, $this->plain, 'going', $h);
        $this->postMsg('leaderB', $h, 'in h');
        $this->postMsg('going', $this->g, 'in g');

        $this->assertCount(1, $this->inbox($this->plain));
        $this->assertCount(2, $this->inbox($this->coord)); // the coordinator of the run hears both threads, one row each
        $this->assertSame(['group_msg:' . $this->g->id], array_map(function ($row) {
            return $row->dedupe_key;
        }, $this->inbox($this->leaderA)));
    }

    public function testMutedMembersGetNoRowAndNoPushButOthersDo()
    {
        GroupThreadState::create(['club_id' => 1, 'group_id' => $this->g->id, 'member_id' => $this->leaderA->id, 'muted' => true]);
        $this->api('PUT', "/groups/{$this->g->id}/thread", 'coord', ['muted' => true]);

        $this->postMsg('going', $this->g, 'hello?');

        $this->assertSame([], $this->inbox($this->leaderA));
        $this->assertSame([], $this->inbox($this->coord));
        $this->assertSame(0, Notification::where('member_id', $this->leaderA->id)->count());

        // Nobody left to tell: no job at all.
        $this->assertSame(0, $this->pushes());

        $this->postMsg('leaderA', $this->g, 'is anyone there');
        $this->assertCount(1, $this->inbox($this->going));
        $this->assertSame(1, $this->pushes());
    }

    public function testMutingOneThreadDoesNotMuteAnother()
    {
        $h = $this->group($this->sess, [$this->leaderB]);
        $this->attend($this->sess, $this->plain, 'going', $h);
        GroupThreadState::create(['club_id' => 1, 'group_id' => $this->g->id, 'member_id' => $this->plain->id, 'muted' => true]);

        $this->postMsg('leaderB', $h, 'hi h');

        $this->assertCount(1, $this->inbox($this->plain));
    }

    public function testAMemberWhoTurnedPushOffStillGetsTheInboxRow()
    {
        NotificationPreference::create(['club_id' => 1, 'member_id' => $this->leaderA->id, 'category' => 'group_messages', 'push_enabled' => false]);
        $this->postMsg('going', $this->g, 'hello');

        $rows = $this->inbox($this->leaderA);
        $this->assertCount(1, $rows);
        $this->assertNull($rows[0]->push_requested_at);
    }

    public function testTheDailyCapAppliesToMessageNotifications()
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->leaderA->id, 'push_daily_cap' => 1]);
        Notification::create([
            'club_id' => 1, 'member_id' => $this->leaderA->id, 'category' => 'club_updates', 'title' => 't', 'body' => 'b',
            'data' => [], 'push_requested_at' => Carbon::now()->subHours(2),
        ]);

        $this->postMsg('going', $this->g, 'hello');

        $row = $this->inbox($this->leaderA)[0];
        $this->assertNull($row->push_requested_at); // inbox row written, push dropped
        $this->assertNotNull($this->inbox($this->coord)[0]->push_requested_at);
        $this->assertSame(1, $this->pushes()); // coord only
    }

    public function testANotificationFailureNeverFailsThePost()
    {
        $this->app->bind(NotificationService::class, function () {
            return new class extends NotificationService {
                public function notifyMembers(...$args): array
                {
                    throw new \RuntimeException('FCM exploded');
                }
            };
        });

        [$status, $body] = $this->postMsg('going', $this->g, 'still gets stored');

        $this->assertSame(201, $status);
        $this->assertSame('still gets stored', $body['body']);
        $this->assertSame(1, GroupMessage::count());
    }

    public function testReplayAndRejectedPostsNotifyNobody()
    {
        $id = $this->uuid();
        $this->postMsg('going', $this->g, 'once', $id);
        Notification::query()->delete();

        $this->postMsg('going', $this->g, 'once', $id); // replay
        $this->postMsg('going', $this->g, '   ');       // invalid
        $this->postMsg('plain', $this->g, 'hi');         // not in the group

        $this->assertSame(0, Notification::count());
    }

    public function testNoNotificationWhenThePostIsRefusedBecauseTheThreadIsClosed()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-14 08:00:00', 'UTC'));

        $this->postMsg('going', $this->g, 'late');

        $this->assertSame(0, Notification::count());
    }
}
