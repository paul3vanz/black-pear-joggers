<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\LeaderThreadMember;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Services\EarlyLeaderNudge;
use App\Services\RunReminderService;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * D128: a gentle nudge to likely leaders 3 to 7 days out when a run has a hole in its spread of paces.
 *
 * "Now" is Monday 2026-10-12 09:00Z (10:00 London). The run is Saturday 2026-10-17 at 19:00, with two
 * leaders at 8:00 and 10:30, so the hole is 8:15 to 10:15/mi. Anna (9:15, led three times), Cara (8:00,
 * twice) and Ben (10:30, once) fit it, in that order; Dee (11:45) and Eli (jog/walk) do not. Each day
 * later the run is a day closer; it leaves this job's window on 2026-10-14 (inside 72 hours).
 */
class AppEarlyLeaderNudgeTest extends AppGroupsBase
{
    /** @var SessionSeries */
    private $series;
    /** @var ClubSession */
    private $target;
    /** @var array<string, ClubMember> */
    private $m = [];
    private $nextId = 700;

    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();

        $this->series = SessionSeries::create([
            'club_id' => 1, 'title' => 'Club run', 'weekday' => 4, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);

        foreach (['anna', 'ben', 'cara', 'dee', 'eli'] as $key) {
            $this->who($key);
        }

        foreach (['2026-09-17', '2026-09-24', '2026-10-01'] as $date) {
            $this->led($this->m['anna'], $date, 555);
        }
        $this->led($this->m['cara'], '2026-09-17', 480);
        $this->led($this->m['cara'], '2026-09-24', 480);
        $this->led($this->m['ben'], '2026-10-01', 630);
        $this->led($this->m['dee'], '2026-10-01', 705);
        $this->led($this->m['eli'], '2026-10-08', null, 'jog_walk');

        $this->target = $this->holeOn('2026-10-17');
    }

    private function who(string $key): ClubMember
    {
        return $this->m[$key] ?? ($this->m[$key] = $this->member('sub-' . $key, $this->nextId++, [], 'active', ucfirst($key)));
    }

    private function runOn(string $date, string $mode = 'paced'): ClubSession
    {
        return $this->session(['date' => $date, 'series_id' => $this->series->id, 'occurrence_date' => $date, 'group_mode' => $mode, 'title' => 'Club run']
            + SessionGenerator::times($date, '19:00', 90, 'Europe/London'));
    }

    private function led(ClubMember $member, string $date, ?int $from, string $kind = 'run'): void
    {
        $session = ClubSession::where('series_id', $this->series->id)->where('occurrence_date', $date)->first() ?: $this->runOn($date);
        $group = $this->group($session, [], [
            'label' => 'Old', 'status' => 'active', 'kind' => $kind,
            'pace_unit' => $from === null ? null : 'mi', 'pace_from_s' => $from,
        ]);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $group->id, 'member_id' => $member->id, 'status' => 'confirmed']);
    }

    /** A led group on $session at $from s/mi (none for jog/walk), by the member named $key or a fresh leader. */
    private function lead(ClubSession $session, int $from, string $kind = 'run', ?string $key = null): void
    {
        $leader = $this->who($key ?? 'lead' . $this->nextId);
        $jogWalk = $kind === 'jog_walk';
        $this->group($session, [$leader], [
            'pace_unit' => $jogWalk ? null : 'mi', 'pace_from_s' => $jogWalk ? null : $from, 'kind' => $kind, 'label' => 'G',
        ]);
    }

    /** A run on $date with leaders at 8:00 and 10:30: a hole of 8:15 to 10:15/mi. */
    private function holeOn(string $date): ClubSession
    {
        $run = $this->runOn($date);
        $this->lead($run, 480, 'run', 'gilla'); // the same two lead every run of the hole, so they never fit another
        $this->lead($run, 630, 'run', 'gillb');

        return $run;
    }

    private function nudge(string $utc): int
    {
        Carbon::setTestNow($now = Carbon::parse($utc, 'UTC'));

        return app(EarlyLeaderNudge::class)->run($now);
    }

    /** @return string[] lower-case names asked about $run so far, sorted */
    private function nudged(?ClubSession $run = null): array
    {
        $run = $run ?: $this->target;
        $names = Notification::where('dedupe_key', 'leaders_early:' . $run->id)->get()->map(function ($row) {
            return strtolower(explode(' ', ClubMember::find($row->member_id)->display_name)[0]);
        })->all();
        sort($names);

        return $names;
    }

    public function testTheTwoBestFitsForTheHoleAreAskedFirstAndOnlyOnceADay()
    {
        $this->assertSame(2, $this->nudge('2026-10-12 09:00'));
        $this->assertSame(['anna', 'cara'], $this->nudged());

        $n = Notification::where('member_id', $this->m['anna']->id)->first();
        $this->assertSame('leaders_needed', $n->category);
        $this->assertSame('Leaders needed: Saturday 17 Oct', $n->title);
        $this->assertSame('Club run on Saturday 17 Oct at 7pm needs a group between 8:15 and 10:15/mi. Can you lead?', $n->body);
        $this->assertSame('/runs/' . $this->target->id . '/groups/new?intent=lead&fast=308&slow=382', $n->data['route']);
        $this->assertSame($this->target->id, $n->data['sessionId']);

        // The 10-minute job runs again the same day: nobody else is asked.
        $this->assertSame(0, $this->nudge('2026-10-12 09:10'));
        $this->assertSame(0, $this->nudge('2026-10-12 17:00'));
        $this->assertSame(['anna', 'cara'], $this->nudged());

        // Those leading the run and people who don't fit are not asked.
        $this->assertSame(0, Notification::where('member_id', $this->m['dee']->id)->count());
        $this->assertSame(0, Notification::where('member_id', $this->m['eli']->id)->count());
        $this->assertSame(2, Notification::count());
    }

    public function testTheNextDayAsksTheNextPersonDownTheList()
    {
        $this->nudge('2026-10-12 09:00');

        $this->assertSame(1, $this->nudge('2026-10-13 09:00')); // only Ben is left who fits
        $this->assertSame(['anna', 'ben', 'cara'], $this->nudged());

        $this->assertSame(0, $this->nudge('2026-10-14 09:00')); // nobody left; nobody is asked twice
        $this->assertSame(['anna', 'ben', 'cara'], $this->nudged());
    }

    public function testOnceTheGapsAreFilledItAsksAboutTheEndsAndJogWalkInstead()
    {
        $this->nudge('2026-10-12 09:00'); // Anna and Cara, for the hole

        foreach ([520, 560, 600] as $from) { // 8:00, 8:40, 9:20, 10:00, 10:30: no gap of 45 s or more
            $this->lead($this->target, $from);
        }

        // The slow end (nothing slower than 11:30) and jog/walk are left; Ben fitted the old hole, not these.
        $this->assertSame(2, $this->nudge('2026-10-13 09:00'));
        $this->assertSame(['anna', 'cara', 'dee', 'eli'], $this->nudged());

        $bodies = Notification::whereIn('member_id', [$this->m['dee']->id, $this->m['eli']->id])->pluck('body', 'member_id');
        $this->assertStringContainsString('could use a group slower than 11:30/mi. Can you lead?', $bodies[$this->m['dee']->id]);
        $this->assertStringContainsString('could use a jog/walk group. Can you lead?', $bodies[$this->m['eli']->id]);
        $this->assertSame(0, Notification::where('member_id', $this->m['ben']->id)->count());
    }

    public function testAFullySpreadRunIsLeftAlone()
    {
        foreach ([520, 560, 600, 640, 680, 720] as $from) {
            $this->lead($this->target, $from);
        }
        $this->lead($this->target, 0, 'jog_walk'); // a jog/walk group is on offer too

        $this->assertSame(0, $this->nudge('2026-10-12 09:00'));
    }

    public function testOnlyBetweenNineAndSevenLocalAndOnlyThreeToSevenDaysOut()
    {
        $soon = $this->holeOn('2026-10-14'); // inside 72 hours: the existing alert's job
        $far = $this->holeOn('2026-10-22'); // more than a week away

        $this->assertSame(0, $this->nudge('2026-10-12 07:59')); // 08:59 local
        $this->assertSame(0, $this->nudge('2026-10-12 18:00')); // 19:00 local
        $this->assertSame(2, $this->nudge('2026-10-12 08:00')); // 09:00 local

        $this->assertSame(['anna', 'cara'], $this->nudged());
        $this->assertSame([], $this->nudged($soon));
        $this->assertSame([], $this->nudged($far));
    }

    public function testNothingForRunsThatDoNotUseTheSpread()
    {
        foreach (['single', 'open', 'routes', 'events', 'race'] as $mode) {
            $this->target->update(['group_mode' => $mode]);
            $this->assertSame(0, $this->nudge('2026-10-12 09:00'), $mode);
        }

        $this->target->update(['group_mode' => 'paced', 'status' => 'cancelled']);
        $this->assertSame(0, $this->nudge('2026-10-12 09:00'));
    }

    public function testPeopleTheCommitteeAlreadyAskedOrWhoCannotComeAreLeftAlone()
    {
        LeaderThreadMember::create(['club_id' => 1, 'session_id' => $this->target->id, 'member_id' => $this->m['anna']->id]);
        $this->attend($this->target, $this->m['cara'], 'not_going');

        $this->assertSame(1, $this->nudge('2026-10-12 09:00'));
        $this->assertSame(['ben'], $this->nudged());
    }

    public function testAMemberGetsOneEarlyNudgeAWeekWhicheverRun()
    {
        $friday = $this->holeOn('2026-10-16'); // starts before the Saturday run, so it is looked at first

        $this->assertSame(3, $this->nudge('2026-10-12 09:00'));
        $this->assertSame(['anna', 'cara'], $this->nudged($friday));
        $this->assertSame(['ben'], $this->nudged()); // Anna and Cara are resting for Saturday

        // A week on, Anna can be asked again, for a run that is then 3 to 7 days away.
        $later = $this->holeOn('2026-10-24');
        $this->nudge('2026-10-19 09:00');
        $this->assertSame(['anna', 'cara'], $this->nudged($later));
    }

    public function testARunWithNoLeadersAtAllAsksTheRegularsInGeneral()
    {
        $empty = $this->runOn('2026-10-16'); // looked at before the Saturday run

        $this->assertSame(3, $this->nudge('2026-10-12 09:00'));
        $this->assertSame(['anna', 'cara'], $this->nudged($empty));
        $this->assertSame(['ben'], $this->nudged());
        $row = Notification::where('dedupe_key', 'leaders_early:' . $empty->id)->first();
        $this->assertSame('Club run on Friday 16 Oct at 7pm has no leader yet. Can you lead?', $row->body);
    }

    public function testTheMessageIsSpokenInTheMembersOwnUnit()
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->m['anna']->id, 'pace_unit' => 'km', 'distance_unit' => 'km']);

        $this->nudge('2026-10-12 09:00');

        $this->assertStringContainsString('needs a group between 5:10 and 6:20/km', Notification::where('member_id', $this->m['anna']->id)->first()->body);
        $this->assertStringContainsString('between 8:15 and 10:15/mi', Notification::where('member_id', $this->m['cara']->id)->first()->body);
    }

    public function testTheReminderJobRunsItAndReportsTheCount()
    {
        Carbon::setTestNow($now = Carbon::parse('2026-10-12 09:00', 'UTC'));

        $stats = app(RunReminderService::class)->run($now);

        $this->assertSame(2, $stats['earlyLeaders']);
    }
}
