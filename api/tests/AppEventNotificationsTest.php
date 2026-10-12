<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Jobs\NotifyMatchingGroupJob;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\Notification;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Services\RunNotifier;
use App\Services\RunReminderService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 8a (D79): nothing pace-group related is sent for `events` and `race` runs, reminders only go to
 * people who are going/maybe (or explicitly opted in), and the removed-event wording. Session changes
 * work as before. "Now" is Monday 2026-10-12 09:00Z; the default run is that evening (18:00Z).
 */
class AppEventNotificationsTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function runAt(string $utc): array
    {
        Carbon::setTestNow($now = Carbon::parse($utc, 'UTC'));

        return app(RunReminderService::class)->run($now);
    }

    private function m(string $sub, int $athleteId, array $roles = []): ClubMember
    {
        return $this->member($sub, $athleteId, $roles, 'active', 'M' . $athleteId);
    }

    private function eventGroup(ClubSession $s, string $label = 'Worcester parkrun', ?ClubMember $creator = null): SessionGroup
    {
        return SessionGroup::create([
            'club_id' => 1, 'session_id' => $s->id, 'kind' => 'event', 'label' => $label, 'status' => 'active',
            'created_by_member_id' => $creator ? $creator->id : null,
        ]);
    }

    private function got(ClubMember $member, string $category = 'run_reminders'): array
    {
        return Notification::where('member_id', $member->id)->where('category', $category)->orderBy('created_at')->get()->all();
    }

    private function total(string $category): int
    {
        return Notification::where('category', $category)->count();
    }

    public function modes(): array
    {
        return ['events' => ['events'], 'race' => ['race']];
    }

    /** @dataProvider modes */
    public function testCreatingAnEventGroupQueuesNoGroupMatch(string $mode)
    {
        $s = $this->session(['group_mode' => $mode]);

        if ($mode === 'events') {
            $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['label' => 'Worcester parkrun']);
        } else {
            $this->eventGroup($s);
        }

        Queue::assertNotPushed(NotifyMatchingGroupJob::class);

        // Control: a pace group still queues it.
        $paced = $this->session(['date' => '2026-10-19']);
        $this->api('POST', "/sessions/{$paced->id}/groups", 'plain', ['paceUnit' => 'mi', 'paceFromS' => 570, 'lead' => true]);
        Queue::assertPushed(NotifyMatchingGroupJob::class, 1);
    }

    /** @dataProvider modes */
    public function testTheMatchingJobSendsNothingForEventRuns(string $mode)
    {
        $s = $this->session(['group_mode' => $mode]);
        $g = $this->eventGroup($s);
        $nopace = $this->m('nopace', 301);
        $fast = $this->m('fast', 302);
        MemberPreference::create(['club_id' => 1, 'member_id' => $fast->id, 'pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->attend($s, $nopace, 'going');

        // Even past the "pick your pace group" time (15:00Z is 16:00 London, 3 hours before).
        Carbon::setTestNow(Carbon::parse('2026-10-12 16:00', 'UTC'));
        $written = app(RunNotifier::class)->matchGroup($g->id, null, Carbon::now());
        (new NotifyMatchingGroupJob($g->id, null))->handle(app(RunNotifier::class));

        $this->assertSame(0, $written);
        $this->assertSame(0, Notification::count());
    }

    public function testControlAPacedRunStillNudgesAndMatches()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $fast = $this->m('fast', 302);
        MemberPreference::create(['club_id' => 1, 'member_id' => $fast->id, 'pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $nopace = $this->m('nopace', 301);
        $this->attend($s, $nopace, 'going');

        Carbon::setTestNow(Carbon::parse('2026-10-12 16:00', 'UTC'));
        $this->assertGreaterThan(0, app(RunNotifier::class)->matchGroup($g->id, null, Carbon::now()));
        $this->assertSame(1, $this->total('group_matches'));
        $this->assertCount(1, $this->got($nopace));
    }

    /** @dataProvider modes */
    public function testNoPickGroupNudgeAndNoLeadersNeeded(string $mode)
    {
        $s = $this->session(['group_mode' => $mode]);
        $this->eventGroup($s);
        $going = $this->m('going', 301);
        $this->attend($s, $going, 'going');
        $this->m('lead', 302, ['leader']); // an available leader who would normally be asked

        $stats = $this->runAt('2026-10-12 16:00'); // after 09:00 local and inside the pick-group window

        $this->assertSame(0, $stats['pickGroup']);
        $this->assertSame(0, $stats['leadersNeeded']);
        $this->assertSame(0, $this->total('leaders_needed'));
        foreach ($this->got($going) as $row) {
            $this->assertStringNotContainsString('Pick your pace group', $row->title);
        }
    }

    public function testControlAPacedRunAsksLeadersAndNudges()
    {
        $s = $this->session();
        $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->attend($s, $this->m('going', 301), 'going');
        $this->m('lead', 302, ['leader']);
        $tomorrow = $this->session(['date' => '2026-10-13']);
        $this->group($tomorrow, [], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]); // needs a leader

        $stats = $this->runAt('2026-10-12 16:00');

        $this->assertSame(1, $stats['pickGroup']);
        $this->assertSame(2, $stats['leadersNeeded']); // Lou and the new leader
    }

    public function testNoLeaderWithdrawalHandlingForEventGroups()
    {
        $s = $this->session(['group_mode' => 'events']);
        $g = $this->eventGroup($s);
        $this->attend($s, $this->plain, 'going', $g);
        $this->m('lead', 302, ['leader']);

        app(RunNotifier::class)->leaderWithdrawn($g, $this->leaderA->id);

        $this->assertSame(0, Notification::count());
    }

    // ---- reminders --------------------------------------------------------------------------

    private function eventsSeries(string $mode = 'events'): SessionSeries
    {
        return SessionSeries::create([
            'club_id' => 1, 'title' => 'parkrun', 'weekday' => 1, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => $mode,
        ]);
    }

    private function seriesRun(SessionSeries $series, string $date, string $mode): ClubSession
    {
        return $this->session(['date' => $date, 'series_id' => $series->id, 'occurrence_date' => $date, 'group_mode' => $mode, 'title' => 'parkrun']);
    }

    public function testEventRemindersGoOnlyToGoingMaybeAndExplicitOptIns()
    {
        $series = $this->eventsSeries();
        $past = $this->seriesRun($series, '2026-10-05', 'events');
        $s = $this->seriesRun($series, '2026-10-12', 'events');
        $group = $this->eventGroup($s);

        $going = $this->m('going', 301);
        $goingNoEvent = $this->m('goingnoevent', 302);
        $maybe = $this->m('maybe', 303);
        $notGoing = $this->m('notgoing', 304);
        $usual = $this->m('usual', 305);        // went to the last run: not enough for an event run
        $optedIn = $this->m('optedin', 306);    // explicit "on"
        $optedInButNo = $this->m('optedinbutno', 307);
        $this->attend($s, $going, 'going', $group);
        $this->attend($s, $goingNoEvent, 'going');
        $this->attend($s, $maybe, 'maybe', $group);
        $this->attend($s, $notGoing, 'not_going');
        $this->attend($past, $usual, 'going');
        $this->attend($s, $optedInButNo, 'not_going');
        MemberSeriesPref::create(['club_id' => 1, 'member_id' => $optedIn->id, 'series_id' => $series->id, 'reminders' => 'on']);
        MemberSeriesPref::create(['club_id' => 1, 'member_id' => $optedInButNo->id, 'series_id' => $series->id, 'reminders' => 'on']);

        $this->runAt('2026-10-12 08:00');

        $this->assertSame("You're going to Worcester parkrun. Can't make it?", $this->got($going)[0]->body);
        $this->assertSame("You're down for this run. Can't make it?", $this->got($goingNoEvent)[0]->body);
        $this->assertSame('You said maybe. Are you coming?', $this->got($maybe)[0]->body);
        $this->assertSame('Are you coming?', $this->got($optedIn)[0]->body);
        $this->assertCount(0, $this->got($notGoing));
        $this->assertCount(0, $this->got($usual));
        $this->assertCount(0, $this->got($optedInButNo));
        $this->assertSame(4, $this->total('run_reminders'));

        // The going-with-an-event reminder keeps its going / not going buttons.
        $this->assertSame(['going', 'not_going'], $this->got($going)[0]->data['actions']);
    }

    public function testControlAPacedSeriesStillRemindsThoseWhoUsuallyCome()
    {
        $series = $this->eventsSeries('paced');
        $past = $this->seriesRun($series, '2026-10-05', 'paced');
        $this->seriesRun($series, '2026-10-12', 'paced');
        $usual = $this->m('usual', 305);
        $this->attend($past, $usual, 'going');

        $this->runAt('2026-10-12 08:00');

        $this->assertCount(1, $this->got($usual));
    }

    public function testARaceRemindsOnlyThoseGoing()
    {
        $s = $this->session(['group_mode' => 'race', 'title' => 'Droitwich 10k']);
        $g = $this->eventGroup($s, 'Droitwich 10k');
        $going = $this->m('going', 301);
        $other = $this->m('other', 302);
        $this->attend($s, $going, 'going', $g);

        $this->runAt('2026-10-12 08:00');

        $this->assertSame("You're going to Droitwich 10k. Can't make it?", $this->got($going)[0]->body);
        $this->assertCount(0, $this->got($other));
    }

    // ---- changes ------------------------------------------------------------------------------

    public function testRemovingAnEventGroupTellsItsAttendeesWithTheEventWording()
    {
        $s = $this->session(['group_mode' => 'events']);
        $g = $this->eventGroup($s);
        $joiner = $this->m('joiner', 301);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $joiner, 'maybe', $g);

        [$status] = $this->api('DELETE', "/groups/{$g->id}", 'committee');

        $this->assertSame(204, $status);
        $rows = Notification::where('category', 'my_group_changes')->get();
        $this->assertCount(2, $rows);
        foreach ($rows as $row) {
            $this->assertSame("Worcester parkrun was removed. Pick another or let us know you can't make it.", $row->body);
            $this->assertSame('group_removed:' . $g->id, $row->dedupe_key);
        }
        $this->assertEqualsCanonicalizing([$this->plain->id, $joiner->id], $rows->pluck('member_id')->all());
    }

    public function testTheCreatorDeletingTheirOwnEventNotifiesOnlyTheOthers()
    {
        $s = $this->session(['group_mode' => 'events']);
        $g = $this->eventGroup($s, 'Worcester parkrun', $this->plain);
        $joiner = $this->m('joiner', 301);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $joiner, 'going', $g);

        $this->api('DELETE', "/groups/{$g->id}", 'plain');

        $this->assertSame([$joiner->id], Notification::where('category', 'my_group_changes')->pluck('member_id')->all());
    }

    public function testPaceGroupRemovalWordingIsUnchanged()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->attend($s, $this->plain, 'going', $g);

        $this->api('DELETE', "/groups/{$g->id}", 'committee');

        $this->assertStringContainsString("You're still down for the run", Notification::where('category', 'my_group_changes')->first()->body);
    }

    public function testCancellingAnEventsRunStillTellsThoseGoing()
    {
        $s = $this->session(['group_mode' => 'events', 'title' => 'parkrun']);
        $g = $this->eventGroup($s);
        $joiner = $this->m('joiner', 301);
        $this->attend($s, $joiner, 'going', $g);
        $this->attend($s, $this->plain, 'not_going');

        [$status] = $this->api('POST', "/sessions/{$s->id}/cancel", 'committee', ['reason' => 'Snow']);

        $this->assertSame(200, $status);
        $rows = Notification::where('category', 'my_group_changes')->get();
        // The going attendee and the run's coordinator; not the member who said not going.
        $this->assertEqualsCanonicalizing([$joiner->id, $this->coord->id], $rows->pluck('member_id')->all());
        $this->assertStringContainsString('parkrun at 7pm has been cancelled', $rows[0]->body);
    }
}
