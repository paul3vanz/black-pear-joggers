<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Jobs\NotifyMatchingGroupJob;
use App\Jobs\SendPushNotificationsJob;
use App\Models\ClubMember;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\SessionGroup;
use App\Services\RunNotifier;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 5b "a group at your pace was added": the delayed job is queued by group
 * create and by a pace change, and re-checks everything when it runs. "Now" is
 * Monday 2026-10-12 09:00 UTC; the default run is that evening. The queue is
 * faked; the job is run by calling handle() directly.
 */
class AppGroupMatchTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function m(string $sub, int $athleteId, ?array $pace = null, array $roles = [], string $status = 'active'): ClubMember
    {
        $member = $this->member($sub, $athleteId, $roles, $status, 'M' . $athleteId);

        if ($pace) {
            MemberPreference::create([
                'club_id' => 1, 'member_id' => $member->id, 'pace_unit' => $pace[2] ?? 'mi', 'pace_from_s' => $pace[0], 'pace_to_s' => $pace[1] ?? null,
            ]);
        }

        return $member;
    }

    /** A 9:30-10:00/mi group (354-373 s/km) on the default run, led by leaderA. */
    private function paced(\App\Models\ClubSession $s, array $overrides = []): SessionGroup
    {
        return $this->group($s, [$this->leaderA], $overrides + ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
    }

    private function runJob(SessionGroup $g, ?string $actorId = null): void
    {
        (new NotifyMatchingGroupJob($g->id, $actorId))->handle(app(RunNotifier::class));
    }

    private function matchRows(ClubMember $member): array
    {
        return Notification::where('member_id', $member->id)->where('category', 'group_matches')->get()->all();
    }

    private function queued(): int
    {
        return Queue::pushed(NotifyMatchingGroupJob::class)->count();
    }

    // ---- when the job is queued --------------------------------------------------------

    public function testCreatingAGroupWithAPaceQueuesTheDelayedJob()
    {
        $s = $this->session();

        [$status, $body] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', [
            'lead' => true, 'paceUnit' => 'mi', 'paceFromS' => 570, 'paceToS' => 600,
        ]);
        $this->assertSame(201, $status);

        $job = Queue::pushed(NotifyMatchingGroupJob::class)->first();
        $this->assertSame($body['id'], $job->groupId());
        $this->assertSame('notifications', $job->queue);
        $this->assertSame(180, $job->delay);
    }

    public function testCreatingAGroupWithoutAPaceQueuesNothing()
    {
        $s = $this->session();

        $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', ['lead' => true, 'label' => 'Jog/walk']);

        $this->assertSame(0, $this->queued());
    }

    public function testReplayingACreateDoesNotQueueAgain()
    {
        $s = $this->session();
        $id = '11111111-1111-4111-8111-111111111111';
        $data = ['id' => $id, 'lead' => true, 'paceUnit' => 'mi', 'paceFromS' => 570];

        $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', $data);
        $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', $data);

        $this->assertSame(1, $this->queued());
    }

    public function testOnlyAChangedPaceQueuesTheJobOnUpdate()
    {
        $s = $this->session();
        $g = $this->paced($s);

        $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['label' => 'Renamed', 'description' => 'x']);
        $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['paceFromS' => 570, 'paceToS' => 600]); // same values
        $this->assertSame(0, $this->queued());

        $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['paceFromS' => 540]);
        $this->assertSame(1, $this->queued());

        $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['paceUnit' => 'km', 'paceFromS' => 330, 'paceToS' => 360]);
        $this->assertSame(2, $this->queued());

        // Removing the pace has nobody to tell.
        $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['paceUnit' => null, 'paceFromS' => null, 'paceToS' => null]);
        $this->assertSame(2, $this->queued());
    }

    public function testAFailureQueuingTheJobDoesNotFailTheRequest()
    {
        $dispatcher = new class {
            public $attempts = 0;

            public function dispatch($job)
            {
                $this->attempts++;

                throw new \RuntimeException('queue down');
            }
        };
        $this->app->instance(\Illuminate\Contracts\Bus\Dispatcher::class, $dispatcher);
        $s = $this->session();

        [$status] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', ['lead' => true, 'paceUnit' => 'mi', 'paceFromS' => 570]);

        $this->assertSame(201, $status);
        $this->assertSame(1, $dispatcher->attempts);
        $this->assertSame(1, SessionGroup::count());
    }

    // ---- who the job tells ---------------------------------------------------------------

    public function testMatchingMembersAreToldOnceWithTheRunAndGroup()
    {
        $s = $this->session(['title' => 'Monday club run']);
        $g = $this->paced($s, ['label' => 'Steady']);
        $fits = $this->m('fits', 301, [560, 600]);
        $single = $this->m('single', 302, [585]);       // 585 s/mi = 363 s/km, inside
        $near = $this->m('near', 303, [630]);           // 391 s/km +/-15 touches 373? 376..406: no
        $edge = $this->m('edge', 304, [615]);           // 382 +/-15 = 367..397: touches 373
        $fast = $this->m('fast', 305, [420, 450]);

        $this->runJob($g);
        $this->runJob($g); // twice: still one each

        foreach ([$fits, $single, $edge] as $who) {
            $rows = $this->matchRows($who);
            $this->assertCount(1, $rows, $who->display_name);
            $this->assertSame('group_match:' . $s->id, $rows[0]->dedupe_key);
            $this->assertSame('New group: Steady 9:30-10:00/mi', $rows[0]->title);
            $this->assertSame('/runs/' . $s->id, $rows[0]->data['route']);
            $this->assertSame($s->id, $rows[0]->data['sessionId']);
            $this->assertSame($g->id, $rows[0]->data['groupId']);
            $this->assertLessThanOrEqual(140, mb_strlen($rows[0]->body));
        }

        $this->assertCount(0, $this->matchRows($near));
        $this->assertCount(0, $this->matchRows($fast));
    }

    public function testMembersWithNoPaceAreNeverMatched()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $nobody = $this->m('nobody', 301);
        $unit = MemberPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'pace_unit' => 'mi']);

        $this->runJob($g);

        $this->assertCount(0, $this->matchRows($nobody));
        $this->assertCount(0, $this->matchRows($this->plain));
    }

    public function testNotGoingMembersAndMembersAlreadyInThisGroupAreLeftOut()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $out = $this->m('out', 301, [570, 600]);
        $inside = $this->m('inside', 302, [570, 600]);
        $maybe = $this->m('maybe', 303, [570, 600]);
        $this->attend($s, $out, 'not_going');
        $this->attend($s, $inside, 'going', $g);
        $this->attend($s, $maybe, 'maybe');

        $this->runJob($g);

        $this->assertCount(0, $this->matchRows($out));
        $this->assertCount(0, $this->matchRows($inside));
        $this->assertCount(1, $this->matchRows($maybe));
    }

    public function testMembersAlreadyInAGroupThatFitsAreLeftOutButOthersAreNot()
    {
        $s = $this->session();
        $happy = $this->m('happy', 301, [570, 600]);
        $misfit = $this->m('misfit', 302, [570, 600]);
        $fitting = $this->group($s, [$this->leaderB], ['pace_unit' => 'mi', 'pace_from_s' => 560, 'pace_to_s' => 610]);
        $slow = $this->group($s, [$this->leaderB], ['pace_unit' => 'mi', 'pace_from_s' => 780, 'pace_to_s' => 840]);
        $nopace = $this->group($s, [$this->leaderB], ['label' => 'Jog/walk']);
        $this->attend($s, $happy, 'going', $fitting);
        $this->attend($s, $misfit, 'going', $slow);
        $jogger = $this->m('jogger', 303, [570, 600]);
        $this->attend($s, $jogger, 'going', $nopace);
        $g = $this->paced($s);

        $this->runJob($g);

        $this->assertCount(0, $this->matchRows($happy));
        $this->assertCount(1, $this->matchRows($misfit));
        $this->assertCount(1, $this->matchRows($jogger));
    }

    public function testThisRunsPaceAnswerBeatsTheUsualRange()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $nowSlow = $this->m('nowslow', 301, [570, 600]);
        $nowFast = $this->m('nowfast', 302, [420, 450]);
        $this->attend($s, $nowSlow, 'going', null, ['pace_unit' => 'mi', 'pace_from_s' => 780, 'pace_to_s' => 840]);
        $this->attend($s, $nowFast, 'maybe', null, ['pace_unit' => 'mi', 'pace_from_s' => 580]);

        $this->runJob($g);

        $this->assertCount(0, $this->matchRows($nowSlow));
        $this->assertCount(1, $this->matchRows($nowFast));
    }

    public function testLeadersTheActorAndInactiveMembersAreLeftOut()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $coLeader = $this->m('coleader', 301, [570, 600]);
        \App\Models\SessionGroupLeader::create(['club_id' => 1, 'group_id' => $g->id, 'member_id' => $coLeader->id]);
        $withdrawn = $this->m('withdrawn', 302, [570, 600]);
        \App\Models\SessionGroupLeader::create(['club_id' => 1, 'group_id' => $g->id, 'member_id' => $withdrawn->id, 'status' => 'withdrawn']);
        $actor = $this->m('actor', 303, [570, 600]);
        $lapsed = $this->m('lapsed', 304, [570, 600], [], 'lapsed');
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->leaderA->id, 'pace_unit' => 'mi', 'pace_from_s' => 570]);

        $this->runJob($g, $actor->id);

        $this->assertCount(0, $this->matchRows($coLeader));
        $this->assertCount(1, $this->matchRows($withdrawn)); // no longer leading: an ordinary candidate
        $this->assertCount(0, $this->matchRows($actor));
        $this->assertCount(0, $this->matchRows($lapsed));
        $this->assertCount(0, $this->matchRows($this->leaderA));
    }

    public function testASecondGroupOnTheSameRunDoesNotNotifyTheSameMemberAgain()
    {
        $s = $this->session();
        $first = $this->paced($s);
        $second = $this->paced($s, ['pace_from_s' => 580]);
        $fits = $this->m('fits', 301, [570, 600]);

        $this->runJob($first);
        $this->runJob($second);

        $this->assertCount(1, $this->matchRows($fits));
    }

    public function testPaceTextUsesTheRecipientsUnit()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $km = $this->m('km', 301, [340, 360, 'km']);

        $this->runJob($g);

        $this->assertSame('New group: 5:54-6:13/km', $this->matchRows($km)[0]->title);
    }

    // ---- the re-check when the job runs ----------------------------------------------------

    public function testAGroupDeletedBeforeTheDelayFiresNotifiesNobody()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $this->m('fits', 301, [570, 600]);

        $g->delete();
        $this->runJob($g);

        $this->assertSame(0, Notification::count());
    }

    public function testAGroupThatLostItsPaceNotifiesNobody()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $this->m('fits', 301, [570, 600]);

        $g->update(['pace_unit' => null, 'pace_from_s' => null, 'pace_to_s' => null]);
        $this->runJob($g);

        $this->assertSame(0, Notification::count());
    }

    public function testATypoFixedBeforeTheDelayOnlyMatchesTheFinalPace()
    {
        $s = $this->session();
        $g = $this->paced($s, ['pace_from_s' => 300, 'pace_to_s' => 330]); // typo: 5:00/mi
        $slowish = $this->m('slowish', 301, [570, 600]);
        $fast = $this->m('fast', 302, [290, 320]);

        $g->update(['pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->runJob($g);

        $this->assertCount(1, $this->matchRows($slowish));
        $this->assertCount(0, $this->matchRows($fast));
    }

    public function testACancelledOrFinishedRunNotifiesNobody()
    {
        $this->m('fits', 301, [570, 600]);
        $cancelled = $this->session(['status' => 'cancelled', 'date' => '2026-10-19']);
        $past = $this->pastSession();

        $this->runJob($this->paced($cancelled));
        $this->runJob($this->paced($past));

        $this->assertSame(0, Notification::count());
    }

    public function testTheJobHandlesAnUnknownGroupQuietly()
    {
        (new NotifyMatchingGroupJob('00000000-0000-4000-8000-000000000000'))->handle(app(RunNotifier::class));

        $this->assertSame(0, Notification::count());
    }

    // ---- push eligibility ---------------------------------------------------------------------

    /** @return string[] ids of every notification handed to a push job */
    private function pushedIds(): array
    {
        $ids = [];
        foreach (Queue::pushed(SendPushNotificationsJob::class) as $job) {
            $ids = array_merge($ids, $job->notificationIds());
        }

        return $ids;
    }

    public function testAMemberWhoTurnedTheCategoryOffGetsTheInboxRowButNoPush()
    {
        $s = $this->session();
        $g = $this->paced($s);
        $on = $this->m('on', 301, [570, 600]);
        $off = $this->m('off', 302, [570, 600]);
        NotificationPreference::create(['club_id' => 1, 'member_id' => $off->id, 'category' => 'group_matches', 'push_enabled' => false]);

        $this->runJob($g);

        $pushed = $this->pushedIds();
        $this->assertContains($this->matchRows($on)[0]->id, $pushed);
        $this->assertNotContains($this->matchRows($off)[0]->id, $pushed);
        $this->assertCount(1, $this->matchRows($off));
    }

    public function testTheDailyCapStopsThePushButNotTheInboxRowAndLockedNoticesIgnoreIt()
    {
        $capped = $this->m('capped', 301, [570, 600]);
        MemberPreference::where('member_id', $capped->id)->update(['push_daily_cap' => 1]);

        $first = $this->session();
        $second = $this->session(['date' => '2026-10-13']);
        $this->runJob($this->paced($first));
        $this->runJob($this->paced($second));

        $rows = Notification::where('member_id', $capped->id)->orderBy('created_at')->orderBy('id')->get();
        $this->assertCount(2, $rows);
        $this->assertNotNull($rows[0]->push_requested_at);
        $this->assertNull($rows[1]->push_requested_at);
        $this->assertContains($rows[0]->id, $this->pushedIds());
        $this->assertNotContains($rows[1]->id, $this->pushedIds());

        // A locked notice (a run cancelled) is pushed regardless, and does not use up the cap.
        $this->attend($first, $capped, 'going');
        $this->api('POST', "/sessions/{$first->id}/cancel", 'committee');

        $locked = Notification::where('member_id', $capped->id)->where('category', 'my_group_changes')->first();
        $this->assertNotNull($locked);
        $this->assertContains($locked->id, $this->pushedIds());
        $this->assertNull($locked->push_requested_at);
    }
}
