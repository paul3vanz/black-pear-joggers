<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Models\Venue;
use App\Services\NotificationService;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 5b triggers that fire from a request: a run cancelled, restored or
 * moved (session endpoints and the generator), a leader withdrawing, a group
 * being removed. "Now" is Monday 2026-10-12 09:00 UTC; the default run is that
 * evening (19:00 London = 18:00Z). The queue is faked, nothing is pushed.
 */
class AppRunNotificationsTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    /** @return Notification[] a member's rows, oldest first */
    private function inbox(ClubMember $member, ?string $category = null): array
    {
        $query = Notification::where('member_id', $member->id)->orderBy('created_at')->orderBy('id');

        if ($category) {
            $query->where('category', $category);
        }

        return $query->get()->all();
    }

    private function inboxCount(ClubMember $member, ?string $category = null): int
    {
        return count($this->inbox($member, $category));
    }

    private function pushes(): int
    {
        return Queue::pushed(SendPushNotificationsJob::class)->count();
    }

    private function member_(string $sub, int $athleteId, array $roles = [], string $status = 'active', string $name = 'Zed'): ClubMember
    {
        return $this->member($sub, $athleteId, $roles, $status, $name);
    }

    // ---- cancelled / restored ----------------------------------------------------

    public function testCancellingARunTellsGoingMaybeLeadersAndTheCoordinator()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);
        $maybe = $this->member_('maybe', 301);
        $out = $this->member_('out', 302);
        $bystander = $this->member_('bystander', 303);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $maybe, 'maybe');
        $this->attend($s, $out, 'not_going');

        [$status] = $this->api('POST', "/sessions/{$s->id}/cancel", 'committee', ['reason' => 'Flooded car park']);
        $this->assertSame(200, $status);

        foreach ([$this->plain, $maybe, $this->leaderA, $this->coord] as $who) {
            $rows = $this->inbox($who);
            $this->assertCount(1, $rows, $who->display_name);
            $this->assertSame('my_group_changes', $rows[0]->category);
            $this->assertSame('Run cancelled: Monday 12 Oct', $rows[0]->title);
            $this->assertSame('session_change:' . $s->id, $rows[0]->dedupe_key);
            $this->assertSame('/runs/' . $s->id, $rows[0]->data['route']);
            $this->assertSame($s->id, $rows[0]->data['sessionId']);
            $this->assertStringContainsString('Flooded car park', $rows[0]->body);
            $this->assertLessThanOrEqual(140, mb_strlen($rows[0]->body));
        }

        foreach ([$out, $bystander, $this->committee] as $who) {
            $this->assertSame(0, $this->inboxCount($who), $who->display_name);
        }

        $this->assertSame(1, $this->pushes()); // one job, locked category
    }

    public function testTheActorIsNeverNotifiedAboutTheirOwnAction()
    {
        $s = $this->session(['coordinator_member_id' => $this->committee->id]);
        $this->attend($s, $this->committee, 'going');
        $this->attend($s, $this->plain, 'going');

        $this->api('POST', "/sessions/{$s->id}/cancel", 'committee');

        $this->assertSame(0, $this->inboxCount($this->committee));
        $this->assertSame(1, $this->inboxCount($this->plain));
    }

    public function testOnlyActiveMembersAreNotified()
    {
        $s = $this->session();
        $lapsed = $this->member_('lapsed', 304, [], 'lapsed');
        $this->attend($s, $lapsed, 'going');
        $this->attend($s, $this->plain, 'going');

        $this->api('POST', "/sessions/{$s->id}/cancel", 'committee');

        $this->assertSame(0, $this->inboxCount($lapsed));
        $this->assertSame(1, $this->inboxCount($this->plain));
    }

    public function testRestoringReplacesTheCancelledNoticeAndPushesAgain()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        $this->api('POST', "/sessions/{$s->id}/cancel", 'committee');
        $this->api('POST', "/sessions/{$s->id}/restore", 'committee');

        $rows = $this->inbox($this->plain);
        $this->assertCount(1, $rows);
        $this->assertSame('Run back on: Monday 12 Oct', $rows[0]->title);
        $this->assertNull($rows[0]->read_at);
        $this->assertSame(2, $this->pushes()); // locked: cancel and restore both push
    }

    public function testCancellingAnAlreadyCancelledRunSaysNothingNew()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        $this->api('POST', "/sessions/{$s->id}/cancel", 'committee', ['reason' => 'x']);
        $this->api('POST', "/sessions/{$s->id}/cancel", 'committee', ['reason' => 'x']);
        $this->api('POST', "/sessions/{$s->id}/restore", 'committee');
        $this->api('POST', "/sessions/{$s->id}/restore", 'committee');

        $this->assertSame(1, $this->inboxCount($this->plain));
        $this->assertSame(2, $this->pushes());
    }

    public function testAPastRunIsNotAnnounced()
    {
        $s = $this->pastSession();
        $this->attend($s, $this->plain, 'going');

        [$status] = $this->api('POST', "/sessions/{$s->id}/cancel", 'committee');

        $this->assertSame(200, $status);
        $this->assertSame(0, $this->inboxCount($this->plain));
    }

    // ---- moved ---------------------------------------------------------------------

    public function testChangingTheStartTimeAndVenueTellsTheSignedUp()
    {
        $venue = Venue::create(['club_id' => 1, 'name' => 'Riverside']);
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        [$status] = $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['startTime' => '19:30', 'venueId' => $venue->id]);
        $this->assertSame(200, $status);

        $row = $this->inbox($this->plain)[0];
        $this->assertSame('Run moved: now 19:30 at Riverside', $row->title);
        $this->assertSame('Monday club run on Monday 12 Oct is now 19:30 at Riverside. Was 19:00.', $row->body);
        $this->assertSame('/runs/' . $s->id, $row->data['route']);
        $this->assertSame('my_group_changes', $row->category);
    }

    public function testAVenueOnlyChangeNamesTheOldVenue()
    {
        $old = Venue::create(['club_id' => 1, 'name' => 'Pitchcroft']);
        $new = Venue::create(['club_id' => 1, 'name' => 'Riverside']);
        $s = $this->session(['venue_id' => $old->id]);
        $this->attend($s, $this->plain, 'maybe');

        $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['venueId' => $new->id]);

        $row = $this->inbox($this->plain)[0];
        $this->assertSame('Run moved: now 19:00 at Riverside', $row->title);
        $this->assertStringContainsString('Was 19:00 at Pitchcroft.', $row->body);
    }

    public function testADateChangeOnAnAdHocRunIsSpelledOut()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['localDate' => '2026-10-14']);

        $row = $this->inbox($this->plain)[0];
        $this->assertSame('Run moved: now Wed 14 Oct 19:00', $row->title);
        $this->assertStringContainsString('Was Mon 12 Oct 19:00.', $row->body);
    }

    public function testChangesThatDoNotMoveTheRunAreSilent()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['notes' => 'Bring a torch', 'title' => 'Renamed']);
        $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['startTime' => '19:00', 'durationMin' => 120]);

        $this->assertSame(0, $this->inboxCount($this->plain));
    }

    public function testMovingAPastOrCancelledRunIsSilent()
    {
        $past = $this->pastSession();
        $this->attend($past, $this->plain, 'going');
        $cancelled = $this->session(['status' => 'cancelled', 'date' => '2026-10-19']);
        $this->attend($cancelled, $this->plain, 'going');

        $this->api('PATCH', "/sessions/{$past->id}", 'committee', ['startTime' => '20:00']);
        $this->api('PATCH', "/sessions/{$cancelled->id}", 'committee', ['startTime' => '20:00']);

        $this->assertSame(0, $this->inboxCount($this->plain));
    }

    public function testALongMessageIsKeptWithinOneHundredAndFortyCharacters()
    {
        $s = $this->session(['title' => str_repeat('Very long run title ', 12)]);
        $this->attend($s, $this->plain, 'going');

        $this->api('POST', "/sessions/{$s->id}/cancel", 'committee', ['reason' => str_repeat('Because ', 30)]);

        $this->assertLessThanOrEqual(140, mb_strlen($this->inbox($this->plain)[0]->body));
    }

    // ---- the generator -------------------------------------------------------------

    private function series(): SessionSeries
    {
        return SessionSeries::create([
            'club_id' => 1, 'title' => 'Monday club run', 'weekday' => 1, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
    }

    private function generate(SessionSeries $series): array
    {
        return (new SessionGenerator())->generateForSeries($series->fresh(), Carbon::parse('2026-10-12 09:00', 'Europe/London'));
    }

    private function run19th(SessionSeries $series): ClubSession
    {
        return ClubSession::where('series_id', $series->id)->where('occurrence_date', '2026-10-19')->first();
    }

    public function testGeneratingNewRunsNotifiesNobody()
    {
        $series = $this->series();
        $this->generate($series);

        $this->assertSame(0, Notification::count());
    }

    public function testASeriesTimeChangeTellsThePeopleSignedUpToAnAttachedRun()
    {
        $series = $this->series();
        $this->generate($series);
        $run = $this->run19th($series);
        $this->attend($run, $this->plain, 'going');

        $series->start_time = '18:30';
        $series->save();
        $stats = $this->generate($series);

        $this->assertGreaterThan(0, $stats['updated']);
        $rows = $this->inbox($this->plain);
        $this->assertCount(1, $rows);
        $this->assertSame('Run moved: now 18:30', $rows[0]->title);
        $this->assertSame('/runs/' . $run->id, $rows[0]->data['route']);
        $this->assertSame(1, Notification::count()); // other runs have nobody signed up

        // A second pass changes nothing, so says nothing more.
        $this->generate($series);
        $this->assertSame(1, Notification::count());
    }

    public function testASeriesVenueChangeIsAnnouncedAndDetachedRunsAreLeftAlone()
    {
        $venue = Venue::create(['club_id' => 1, 'name' => 'Riverside']);
        $series = $this->series();
        $this->generate($series);
        $run = $this->run19th($series);
        $this->attend($run, $this->plain, 'going');
        $detached = ClubSession::where('series_id', $series->id)->where('occurrence_date', '2026-10-26')->first();
        $detached->is_detached = true;
        $detached->save();
        $this->attend($detached, $this->plain, 'going');

        $series->venue_id = $venue->id;
        $series->save();
        $this->generate($series);

        $rows = $this->inbox($this->plain);
        $this->assertCount(1, $rows);
        $this->assertSame('Run moved: now 19:00 at Riverside', $rows[0]->title);
        $this->assertSame('/runs/' . $run->id, $rows[0]->data['route']);
    }

    public function testASeriesChangeThatDoesNotMoveTheRunIsSilent()
    {
        $series = $this->series();
        $this->generate($series);
        $run = $this->run19th($series);
        $this->attend($run, $this->plain, 'going');

        $series->title = 'Renamed run';
        $series->duration_min = 60;
        $series->save();
        $this->generate($series);

        $this->assertSame('Renamed run', ClubSession::find($run->id)->title);
        $this->assertSame(0, Notification::count());
    }

    // ---- the last leader withdraws -------------------------------------------------

    private function pace(ClubMember $member, int $from, ?int $to = null, string $unit = 'mi'): void
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $member->id, 'pace_unit' => $unit, 'pace_from_s' => $from, 'pace_to_s' => $to]);
    }

    /** A paced run with a 9:30-10:00/mi group led by leaderA. */
    private function ledGroup(array $session = [], array $group = [])
    {
        $s = $this->session($session);
        $g = $this->group($s, [$this->leaderA], $group + ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600, 'label' => 'Steady']);
        $this->attend($s, $this->leaderA, 'going', $g);

        return [$s, $g];
    }

    public function testTheLastLeaderWithdrawingTellsTheGroupAndFittingLeaders()
    {
        [$s, $g] = $this->ledGroup();
        $maybe = $this->member_('maybe', 301);
        $out = $this->member_('out', 302);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $maybe, 'maybe', $g);
        $this->attend($s, $out, 'not_going');

        $fits = $this->member_('fits', 311, ['leader']);
        $this->pace($fits, 560, 600);
        $slow = $this->member_('slow', 312, ['leader']);
        $this->pace($slow, 780, 840);
        $noPace = $this->member_('nopace', 313, ['leader']);
        $notGoing = $this->member_('notgoing', 314, ['leader']);
        $this->attend($s, $notGoing, 'not_going');
        $this->pace($notGoing, 570, 600);
        $leadsElsewhere = $this->member_('elsewhere', 315, ['leader']);
        $this->pace($leadsElsewhere, 570, 600);
        $this->group($s, [$leadsElsewhere]);
        $insider = $this->member_('insider', 316, ['leader']);
        $this->attend($s, $insider, 'going', $g);
        $ordinary = $this->member_('ordinary', 317);
        $this->pace($ordinary, 570, 600);

        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(200, $status);
        $this->assertSame('needs_leader', $body['status']);

        foreach ([$this->plain, $maybe, $insider] as $who) {
            $rows = $this->inbox($who);
            $this->assertCount(1, $rows, $who->display_name);
            $this->assertSame('my_group_changes', $rows[0]->category);
            $this->assertSame('Your group needs a leader', $rows[0]->title);
            $this->assertSame('leader_withdrawn:' . $g->id, $rows[0]->dedupe_key);
            $this->assertSame('/runs/' . $s->id, $rows[0]->data['route']);
            $this->assertSame($g->id, $rows[0]->data['groupId']);
            $this->assertStringContainsString('Steady 9:30-10:00/mi', $rows[0]->body);
        }

        foreach ([$fits, $noPace, $this->leaderB] as $who) {
            $rows = $this->inbox($who);
            $this->assertCount(1, $rows, $who->display_name);
            $this->assertSame('leaders_needed', $rows[0]->category);
            $this->assertSame('leaders_needed_group:' . $g->id, $rows[0]->dedupe_key);
            $this->assertSame('/runs/' . $s->id, $rows[0]->data['route']);
            $this->assertStringContainsString('Steady 9:30-10:00/mi', $rows[0]->title);
        }

        // The leader themselves, the "not going", the slow leader, the one leading elsewhere
        // and a member without the role hear nothing; the insider is told once, not twice.
        foreach ([$this->leaderA, $out, $slow, $notGoing, $leadsElsewhere, $ordinary, $this->coord] as $who) {
            $this->assertSame(0, $this->inboxCount($who), $who->display_name);
        }
    }

    public function testPaceTextIsInTheRecipientsUnit()
    {
        [$s, $g] = $this->ledGroup();
        $this->attend($s, $this->plain, 'going', $g);
        $this->pace($this->plain, 340, 360, 'km');

        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');

        $this->assertStringContainsString('Steady 5:54-6:13/km', $this->inbox($this->plain)[0]->body);
    }

    public function testWithdrawingTwiceDoesNotNotifyTwiceButAChangedGroupReplacesAndPushesAgain()
    {
        [$s, $g] = $this->ledGroup();
        $this->attend($s, $this->plain, 'going', $g);
        $fits = $this->member_('fits', 311, ['leader']);
        $this->pace($fits, 560, 600);

        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(2, $this->pushes()); // attendees (locked) and leaders_needed
        $first = $this->inbox($this->plain)[0];

        // Replaying the withdraw is a no-op.
        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(2, $this->pushes());

        // Joined again and withdrew again with nothing different: same news, nothing new.
        $this->api('POST', "/groups/{$g->id}/leaders", 'leaderA');
        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(1, $this->inboxCount($this->plain));
        $this->assertSame(2, $this->pushes());

        // The group changed meanwhile: the notice is replaced in place and pushed again.
        $this->api('POST', "/groups/{$g->id}/leaders", 'leaderA');
        $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['label' => 'Brisk']);
        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');

        $rows = $this->inbox($this->plain);
        $this->assertCount(1, $rows);
        $this->assertSame($first->id, $rows[0]->id);
        $this->assertStringContainsString('Brisk', $rows[0]->body);
        $this->assertNull($rows[0]->read_at);
        $this->assertSame(3, $this->pushes()); // leaders_needed uses skip: still one row, no re-push
        $this->assertSame(1, $this->inboxCount($fits));
    }

    public function testAnotherLeaderRemainingMeansNobodyIsToldAndRoutesRunsStayActive()
    {
        [$s, $g] = $this->ledGroup();
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $g->id, 'member_id' => $this->leaderB->id]);
        $this->attend($s, $this->plain, 'going', $g);

        $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderA');
        $this->assertSame(0, Notification::count());

        $routes = $this->session(['group_mode' => 'routes', 'date' => '2026-10-19']);
        $rg = $this->group($routes, [$this->leaderA], ['status' => 'active']);
        $this->attend($routes, $this->plain, 'going', $rg);

        $this->api('DELETE', "/groups/{$rg->id}/leaders/me", 'leaderA');
        $this->assertSame(0, Notification::count());
    }

    // ---- a group is removed ----------------------------------------------------------

    public function testRemovingAGroupTellsItsAttendeesOnly()
    {
        [$s, $g] = $this->ledGroup();
        $maybe = $this->member_('maybe', 301);
        $out = $this->member_('out', 302);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $maybe, 'maybe', $g);
        $this->attend($s, $out, 'not_going');
        $other = $this->group($s, [$this->leaderB]);
        $elsewhere = $this->member_('elsewhere', 303);
        $this->attend($s, $elsewhere, 'going', $other);

        [$status] = $this->api('DELETE', "/groups/{$g->id}", 'leaderA');
        $this->assertSame(204, $status);

        foreach ([$this->plain, $maybe] as $who) {
            $rows = $this->inbox($who);
            $this->assertCount(1, $rows, $who->display_name);
            $this->assertSame('my_group_changes', $rows[0]->category);
            $this->assertSame('Group removed', $rows[0]->title);
            $this->assertSame('group_removed:' . $g->id, $rows[0]->dedupe_key);
            $this->assertSame('/runs/' . $s->id, $rows[0]->data['route']);
            $this->assertSame($s->id, $rows[0]->data['sessionId']);
        }

        // The deleting leader is the actor; the rest were not in the group.
        foreach ([$this->leaderA, $out, $elsewhere, $this->leaderB] as $who) {
            $this->assertSame(0, $this->inboxCount($who), $who->display_name);
        }

        // Replaying the delete says nothing more.
        $this->api('DELETE', "/groups/{$g->id}", 'leaderA');
        $this->assertSame(2, Notification::count());
    }

    public function testRemovingAnEmptyGroupSaysNothing()
    {
        $g = $this->group($this->session(), [$this->leaderA]);

        $this->api('DELETE', "/groups/{$g->id}", 'committee');

        $this->assertSame(0, Notification::count());
    }

    public function testRemovingAGroupOnAPastRunIsRefusedAndSilent()
    {
        $s = $this->pastSession();
        $g = $this->group($s, [$this->leaderA]);
        $this->attend($s, $this->plain, 'going', $g);

        [$status] = $this->api('DELETE', "/groups/{$g->id}", 'leaderA');

        $this->assertSame(409, $status);
        $this->assertSame(0, Notification::count());
    }

    // ---- a notification failure never fails the request ----------------------------

    public function testAFailingNotificationDoesNotFailTheRequest()
    {
        $this->app->instance(NotificationService::class, new class extends NotificationService {
            public function notifyMembers(...$args): array
            {
                throw new \RuntimeException('FCM exploded');
            }
        });
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        [$status, $body] = $this->api('POST', "/sessions/{$s->id}/cancel", 'committee');

        $this->assertSame(200, $status);
        $this->assertSame('cancelled', $body['status']);
        $this->assertSame('cancelled', ClubSession::find($s->id)->status);
    }
}
