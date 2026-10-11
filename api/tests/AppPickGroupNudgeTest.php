<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Jobs\NotifyMatchingGroupJob;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Services\RunNotifier;
use App\Services\RunReminderService;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * 2026-10-13 (D50): "pick your pace group" for people who are going but chose no group.
 * Default run: Monday 2026-10-12 19:00 London (BST) = 18:00Z, so the nudge is due from
 * 16:00 London = 15:00Z. The queue is faked.
 */
class AppPickGroupNudgeTest extends AppGroupsBase
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

    private function runOn(string $date, string $hm, array $overrides = []): ClubSession
    {
        return $this->session(['date' => $date] + $overrides + SessionGenerator::times($date, $hm, 90, 'Europe/London'));
    }

    private function m(string $sub, int $athleteId, ?array $pace = null, string $status = 'active'): ClubMember
    {
        $member = $this->member($sub, $athleteId, [], $status, 'M' . $athleteId);

        if ($pace) {
            MemberPreference::create([
                'club_id' => 1, 'member_id' => $member->id, 'pace_unit' => 'mi', 'pace_from_s' => $pace[0], 'pace_to_s' => $pace[1] ?? null,
            ]);
        }

        return $member;
    }

    /** @return Notification[] */
    private function nudges(ClubMember $member): array
    {
        return Notification::where('member_id', $member->id)->where('title', 'Pick your pace group')->get()->all();
    }

    private function nudgeTotal(): int
    {
        return Notification::where('title', 'Pick your pace group')->count();
    }

    /** A run with one led pace group and a going member with no group. */
    private function runWithGroupAndGoer(): array
    {
        $s = $this->session();
        $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->attend($s, $this->plain, 'going');

        return [$s, $this->plain];
    }

    // ---- timing --------------------------------------------------------------------------

    public function testNudgeIsDueThreeHoursBeforeTheStartUntilItStarts()
    {
        [$s, $pat] = $this->runWithGroupAndGoer();

        $this->assertSame(0, $this->runAt('2026-10-12 14:59')['pickGroup']); // 15:59 BST
        $this->assertSame(0, $this->nudgeTotal());

        $this->assertSame(1, $this->runAt('2026-10-12 15:00')['pickGroup']); // 16:00 BST
        $rows = $this->nudges($pat);
        $this->assertCount(1, $rows);

        // Late command runs still send, as long as the run has not started.
        Notification::query()->delete();
        $this->assertSame(1, $this->runAt('2026-10-12 17:59')['pickGroup']);
        Notification::query()->delete();
        $this->assertSame(0, $this->runAt('2026-10-12 18:00')['pickGroup']); // exactly the start
        $this->assertSame(0, $this->runAt('2026-10-12 19:00')['pickGroup']);
        $this->assertSame(0, $this->nudgeTotal());
    }

    public function testNeverBeforeEightInTheMorningLocal()
    {
        // 09:00 BST run: three hours before is 06:00, held back to 08:00 BST (07:00Z).
        $s = $this->runOn('2026-10-12', '09:00');
        $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570]);
        $this->attend($s, $this->plain, 'going');

        $this->assertSame(0, $this->runAt('2026-10-12 06:59')['pickGroup']); // 07:59 BST
        $this->assertSame(1, $this->runAt('2026-10-12 07:00')['pickGroup']); // 08:00 BST
    }

    public function testMidMorningRunsAreNudgedThreeHoursBefore()
    {
        // 12:00 BST run: due 09:00 BST = 08:00Z.
        $s = $this->runOn('2026-10-12', '12:00');
        $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570]);
        $this->attend($s, $this->plain, 'going');

        $this->assertSame(0, $this->runAt('2026-10-12 07:59')['pickGroup']);
        $this->assertSame(1, $this->runAt('2026-10-12 08:00')['pickGroup']);
        $this->assertSame("Today's run has 1 pace group. Tap to choose yours", $this->nudges($this->plain)[0]->body);
    }

    public function testAnEarlyRunIsNeverNudgedBecauseThe0800StartHasPassed()
    {
        // 07:30 BST run: the nudge could only come at 08:00, after the start.
        $s = $this->runOn('2026-10-12', '07:30');
        $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570]);
        $this->attend($s, $this->plain, 'going');

        foreach (['2026-10-11 20:00', '2026-10-12 05:00', '2026-10-12 06:29', '2026-10-12 07:00'] as $at) {
            $this->assertSame(0, $this->runAt($at)['pickGroup'], $at);
        }
        $this->assertSame(0, $this->nudgeTotal());
    }

    public function testAfterMidnightRunIsNudgedTheEveningBefore()
    {
        // 00:30 BST on the 13th: three hours before is 21:30 BST on the 12th (after 08:00, so kept).
        $s = $this->runOn('2026-10-13', '00:30', ['date' => '2026-10-13']);
        $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570]);
        $this->attend($s, $this->plain, 'going');

        $this->assertSame(0, $this->runAt('2026-10-12 20:29')['pickGroup']);
        $this->assertSame(1, $this->runAt('2026-10-12 20:30')['pickGroup']); // 21:30 BST
        $this->assertSame("Tomorrow's run has 1 pace group. Tap to choose yours", $this->nudges($this->plain)[0]->body);
    }

    // ---- audience --------------------------------------------------------------------------

    public function testOnlyActiveGoingMembersWithNoGroupWhoLeadNothingAreNudged()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderB], ['pace_unit' => 'mi', 'pace_from_s' => 570]);

        $goer = $this->m('goer', 301);
        $inGroup = $this->m('inGroup', 302);
        $maybe = $this->m('maybe', 303);
        $notGoing = $this->m('notGoing', 304);
        $silent = $this->m('silent', 305);
        $inactive = $this->m('inactive', 306, null, 'left');
        $leading = $this->m('leading', 307);
        $deletedGroup = $this->m('deletedGroup', 308);
        $withPace = $this->m('withPace', 309, [570]);

        $this->attend($s, $goer, 'going');
        $this->attend($s, $inGroup, 'going', $g);
        $this->attend($s, $maybe, 'maybe');
        $this->attend($s, $notGoing, 'not_going');
        $this->attend($s, $inactive, 'going');
        $this->attend($s, $leading, 'going'); // leads the run's second group but has no group on their own row
        $this->group($s, [$leading], ['label' => 'Walk']);
        $this->attend($s, $withPace, 'going'); // a usual pace does not exempt them from the timed nudge

        $gone = $this->group($s, [$this->leaderA], ['label' => 'Gone']);
        $this->attend($s, $deletedGroup, 'going', $gone);
        // Deleting the group leaves them going with no group.
        $gone->delete();
        SessionAttendee::where('member_id', $deletedGroup->id)->update(['group_id' => null]);

        $this->assertSame(3, $this->runAt('2026-10-12 15:00')['pickGroup']);

        foreach ([$goer, $deletedGroup, $withPace] as $who) {
            $this->assertCount(1, $this->nudges($who), $who->display_name);
        }
        foreach ([$inGroup, $maybe, $notGoing, $silent, $inactive, $leading] as $who) {
            $this->assertCount(0, $this->nudges($who), $who->display_name);
        }
    }

    public function testRowShapeCategoryKeyAndRoute()
    {
        [$s, $pat] = $this->runWithGroupAndGoer();
        $this->group($s, [$this->leaderB], ['label' => 'Jog/walk']);

        $this->runAt('2026-10-12 15:00');

        $row = $this->nudges($pat)[0];
        $this->assertSame('run_reminders', $row->category);
        $this->assertSame('Pick your pace group', $row->title);
        $this->assertSame("Tonight's run has 2 pace groups. Tap to choose yours", $row->body);
        $this->assertSame('pick_group:' . $s->id, $row->dedupe_key);
        $this->assertSame('/runs/' . $s->id, $row->data['route']);
        $this->assertSame($s->id, $row->data['sessionId']);
        $this->assertArrayNotHasKey('actions', $row->data);
        $this->assertArrayNotHasKey('actionToken', $row->data);
    }

    public function testCancelledRunsAreNeverNudged()
    {
        [$s] = $this->runWithGroupAndGoer();
        $s->update(['status' => 'cancelled']);

        $this->assertSame(0, $this->runAt('2026-10-12 16:00')['pickGroup']);
    }

    // ---- groups ------------------------------------------------------------------------------

    public function testNothingIsSentWhenTheRunHasNoActiveGroup()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        $this->assertSame(0, $this->runAt('2026-10-12 16:00')['pickGroup']);

        // A group nobody leads (needs_leader) is not an active one.
        $this->group($s, [], ['label' => 'Walk']);
        $this->assertSame(0, $this->runAt('2026-10-12 16:05')['pickGroup']);

        // A deleted group does not count either.
        $gone = $this->group($s, [$this->leaderA], ['label' => 'Gone']);
        $gone->delete();
        $this->assertSame(0, $this->runAt('2026-10-12 16:10')['pickGroup']);
        $this->assertSame(0, $this->nudgeTotal());

        // Once an active group exists, the next tick sends it, with the right count.
        $this->group($s, [$this->leaderB], ['label' => 'Fast']);
        $this->assertSame(1, $this->runAt('2026-10-12 16:20')['pickGroup']);
        $this->assertSame("Tonight's run has 1 pace group. Tap to choose yours", $this->nudges($this->plain)[0]->body);
    }

    // ---- idempotency and ordering ---------------------------------------------------------------

    public function testItIsSentOnlyOncePerRun()
    {
        [$s, $pat] = $this->runWithGroupAndGoer();

        $this->assertSame(1, $this->runAt('2026-10-12 15:00')['pickGroup']);
        $this->assertSame(0, $this->runAt('2026-10-12 15:10')['pickGroup']);
        $this->assertSame(0, $this->runAt('2026-10-12 17:50')['pickGroup']);
        $this->assertCount(1, $this->nudges($pat));

        // A member who only answers later still gets exactly one.
        $late = $this->m('late', 311);
        $this->attend($s, $late, 'going');
        $this->assertSame(1, $this->runAt('2026-10-12 17:55')['pickGroup']);
        $this->assertCount(1, $this->nudges($pat));
        $this->assertCount(1, $this->nudges($late));
    }

    public function testChoosingAGroupBeforeTheNudgeStopsIt()
    {
        [$s, $pat] = $this->runWithGroupAndGoer();
        $group = SessionGroup::where('session_id', $s->id)->first();

        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $group->id]);

        $this->assertSame(0, $this->runAt('2026-10-12 16:00')['pickGroup']);
    }

    public function testItComesAfterTheMorningReminderAndDoesNotReplaceIt()
    {
        [$s, $pat] = $this->runWithGroupAndGoer();

        $this->assertSame(2, $this->runAt('2026-10-12 07:00')['reminders']); // plain and the leader
        $this->assertSame(0, $this->runAt('2026-10-12 07:00')['pickGroup']);

        $this->assertSame(0, $this->runAt('2026-10-12 15:00')['reminders']); // already reminded
        // A command that only got going at 15:10 (the morning reminder rows gone): both are due in one tick.
        Notification::query()->delete();
        $stats = $this->runAt('2026-10-12 15:10');
        $this->assertSame(2, $stats['reminders']);
        $this->assertSame(1, $stats['pickGroup']);

        $rows = Notification::where('member_id', $pat->id)->where('category', 'run_reminders')->orderBy('created_at')->orderBy('id')->get();
        $this->assertCount(2, $rows);
        $keys = $rows->pluck('dedupe_key')->sort()->values()->all();
        $this->assertSame(['pick_group:' . $s->id, 'reminder:' . $s->id], $keys);
    }

    // ---- a group added after the nudge time (NotifyMatchingGroupJob) -----------------------------

    private function runJob(SessionGroup $g, ?string $actorId = null): void
    {
        (new NotifyMatchingGroupJob($g->id, $actorId))->handle(app(RunNotifier::class));
    }

    public function testGroupAddedAfterTheTimeNudgesPeopleWithNoGroupAndNoUsualPaceOnly()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-12 16:00:00', 'UTC')); // 17:00 BST, past 16:00
        $s = $this->session();

        $noPace = $this->m('noPace', 321);
        $noPace2 = $this->m('noPace2', 322);
        $fits = $this->m('fits', 323, [570, 600]);
        $tooFast = $this->m('tooFast', 324, [420, 450]);
        $inGroup = $this->m('inGroup', 325);
        $maybe = $this->m('maybe', 326);

        $other = $this->group($s, [$this->leaderB], ['label' => 'Other']);
        foreach ([$noPace, $noPace2, $fits, $tooFast, $maybe] as $who) {
            $this->attend($s, $who, $who === $maybe ? 'maybe' : 'going');
        }
        $this->attend($s, $inGroup, 'going', $other);

        $added = $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->runJob($added, $this->leaderA->id);

        foreach ([$noPace, $noPace2] as $who) {
            $this->assertCount(1, $this->nudges($who), $who->display_name);
            $this->assertSame('pick_group:' . $s->id, $this->nudges($who)[0]->dedupe_key);
            $this->assertSame("Tonight's run has 2 pace groups. Tap to choose yours", $this->nudges($who)[0]->body);
            $this->assertCount(0, Notification::where('member_id', $who->id)->where('category', 'group_matches')->get());
        }

        // The member with a usual pace that fits gets the group match only, never both.
        $this->assertCount(0, $this->nudges($fits));
        $this->assertCount(1, Notification::where('member_id', $fits->id)->where('category', 'group_matches')->get());
        // Nothing for a usual pace that does not fit, a maybe, or someone already in a group.
        foreach ([$tooFast, $maybe, $inGroup] as $who) {
            $this->assertCount(0, Notification::where('member_id', $who->id)->get(), $who->display_name . ' ' . json_encode(Notification::where('member_id', $who->id)->pluck('title')));
        }

        // Re-running the job never repeats it.
        $this->runJob($added, $this->leaderA->id);
        $this->assertSame(2, $this->nudgeTotal());

        // The timed service then covers the people the job left out (usual pace, still no group),
        // but nobody twice.
        $this->assertSame(2, $this->runAt('2026-10-12 16:10')['pickGroup']);
        $this->assertCount(1, $this->nudges($fits));
        $this->assertCount(1, $this->nudges($tooFast));
        $this->assertCount(1, $this->nudges($noPace));
        $this->assertSame(0, $this->runAt('2026-10-12 16:20')['pickGroup']);
        $this->assertSame(4, $this->nudgeTotal());
    }

    public function testAPacelessGroupAddedAfterTheTimeNudgesToo()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-12 16:00:00', 'UTC'));
        $s = $this->session();
        $noPace = $this->m('noPace', 331);
        $withPace = $this->m('withPace', 332, [570]);
        $this->attend($s, $noPace, 'going');
        $this->attend($s, $withPace, 'going');

        $walk = $this->group($s, [$this->leaderA], ['label' => 'Jog/walk']);
        $this->runJob($walk, $this->leaderA->id);

        $this->assertCount(1, $this->nudges($noPace));
        $this->assertSame("Tonight's run has 1 pace group. Tap to choose yours", $this->nudges($noPace)[0]->body);
        $this->assertCount(0, Notification::where('member_id', $withPace->id)->get());
        $this->assertSame(0, Notification::where('category', 'group_matches')->count());
    }

    public function testAGroupAddedBeforeTheTimeDoesNotNudgeYetButTheTimedRunDoes()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-12 12:00:00', 'UTC')); // 13:00 BST, before 16:00
        $s = $this->session();
        $noPace = $this->m('noPace', 341);
        $this->attend($s, $noPace, 'going');

        $added = $this->group($s, [$this->leaderA], ['label' => 'Walk']);
        $this->runJob($added, $this->leaderA->id);
        $this->assertSame(0, $this->nudgeTotal());

        $this->assertSame(1, $this->runAt('2026-10-12 15:00')['pickGroup']);
    }

    public function testJobAddsNothingWhenThereIsNoActiveGroupTheRunStartedOrWasCancelled()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-12 16:00:00', 'UTC'));
        $s = $this->session();
        $noPace = $this->m('noPace', 351);
        $this->attend($s, $noPace, 'going');

        // The only group has no leader: not active.
        $leaderless = $this->group($s, [], ['label' => 'Walk']);
        $this->runJob($leaderless);
        $this->assertSame(0, $this->nudgeTotal());

        // Started: past the start, nothing.
        $started = $this->session(['date' => '2026-10-12'] + SessionGenerator::times('2026-10-12', '17:00', 90, 'Europe/London'));
        $startedGroup = $this->group($started, [$this->leaderA], ['label' => 'Walk']);
        $this->attend($started, $noPace, 'going');
        $this->runJob($startedGroup);
        $this->assertSame(0, $this->nudgeTotal());

        $cancelled = $this->runOn('2026-10-19', '19:00', ['status' => 'cancelled']);
        $cancelledGroup = $this->group($cancelled, [$this->leaderA], ['label' => 'Walk']);
        $this->attend($cancelled, $noPace, 'going');
        Carbon::setTestNow(Carbon::parse('2026-10-19 16:00:00', 'UTC'));
        $this->runJob($cancelledGroup);
        $this->assertSame(0, $this->nudgeTotal());
    }

    public function testCreatingAGroupQueuesTheJobAndThePostStillSucceedsWhenTheNudgeFails()
    {
        Carbon::setTestNow(Carbon::parse('2026-10-12 16:00:00', 'UTC'));
        $s = $this->session();
        $noPace = $this->m('noPace', 361);
        $this->attend($s, $noPace, 'going');

        [$status, $body] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', ['lead' => true, 'label' => 'Walk']);
        $this->assertSame(201, $status);
        $job = Queue::pushed(NotifyMatchingGroupJob::class)->first();
        $this->assertSame($body['id'], $job->groupId());

        $job->handle(app(RunNotifier::class));
        $this->assertCount(1, $this->nudges($noPace));
        // The creator is in their own group and leads it: no nudge for them.
        $this->assertCount(0, $this->nudges($this->leaderA));
    }
}
