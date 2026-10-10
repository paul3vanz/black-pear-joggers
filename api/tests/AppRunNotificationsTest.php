<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\Notification;
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
        $other = $this->run19th($series)->replicate();

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
