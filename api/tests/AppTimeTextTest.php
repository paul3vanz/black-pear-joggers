<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\Venue;
use App\Services\RunNotifier;
use App\Services\RunReminderService;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * 2026-10-13 (D48): every time in server-written notification text is 12-hour.
 * Default run: Monday 2026-10-12 19:00 London (7pm). The queue is faked.
 */
class AppTimeTextTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function last(string $category): Notification
    {
        return Notification::where('category', $category)->orderByDesc('created_at')->firstOrFail();
    }

    public function testCancelledAndRestoredTexts()
    {
        $venue = Venue::create(['club_id' => 1, 'name' => 'Riverside']);
        $s = $this->session(['venue_id' => $venue->id]);
        $this->attend($s, $this->plain, 'going');

        app(RunNotifier::class)->sessionChanged($s, 'cancelled');
        $row = $this->last('my_group_changes');
        $this->assertSame('Run cancelled: Monday 12 Oct', $row->title);
        $this->assertSame('Monday club run at 7pm has been cancelled.', $row->body);

        app(RunNotifier::class)->sessionChanged($s, 'restored');
        $row = $this->last('my_group_changes');
        $this->assertSame('Monday club run is on after all: 7pm at Riverside.', $row->body);
    }

    public function testMovedTextOnTheHourAndOffIt()
    {
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');

        $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['startTime' => '12:00']);
        $row = $this->last('my_group_changes');
        $this->assertSame('Run moved: now 12pm', $row->title);
        $this->assertSame('Monday club run on Monday 12 Oct is now 12pm. Was 7pm.', $row->body);

        $this->api('PATCH', "/sessions/{$s->id}", 'committee', ['startTime' => '18:45']);
        $row = $this->last('my_group_changes');
        $this->assertSame('Run moved: now 6:45pm', $row->title);
        $this->assertSame('Monday club run on Monday 12 Oct is now 6:45pm. Was 12pm.', $row->body);
    }

    public function testGroupMatchAndLeaderTexts()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['label' => 'Steady', 'pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'pace_unit' => 'mi', 'pace_from_s' => 580]);

        (new \App\Jobs\NotifyMatchingGroupJob($g->id))->handle(app(RunNotifier::class));
        $row = $this->last('group_matches');
        $this->assertSame('Monday club run on Monday 12 Oct at 7pm has a new group at your pace. Want to join it?', $row->body);

        // Leader withdraws: leader-role members hear that the group has no leader, with the time.
        app(RunNotifier::class)->leaderWithdrawn($g, $this->leaderA->id);
        $row = $this->last('leaders_needed');
        $this->assertSame('Steady 9:30-10:00/mi at 7pm on Monday 12 Oct has no leader. Can you lead it?', $row->body);
    }

    public function testLeadersNeededAlertText()
    {
        $s = $this->runOn('2026-10-12', '19:30');
        $this->group($s, [], ['label' => 'Walk']);

        Carbon::setTestNow($now = Carbon::parse('2026-10-12 09:00', 'UTC'));
        app(RunReminderService::class)->run($now);

        $row = $this->last('leaders_needed');
        $this->assertSame('Monday club run on Monday 12 Oct at 7:30pm has a group with no leader. Can you lead it?', $row->body);
    }

    public function testReminderTitlesUseTwelveHourTimes()
    {
        $evening = $this->runOn('2026-10-12', '19:30');
        $this->attend($evening, $this->plain, 'going');
        $early = $this->runOn('2026-10-13', '10:00');
        $this->attend($early, $this->plain, 'going');
        $noon = $this->runOn('2026-10-12', '12:00');
        $this->attend($noon, $this->plain, 'going');

        Carbon::setTestNow($now = Carbon::parse('2026-10-12 07:30', 'UTC')); // 08:30 BST: both of today's runs are due
        app(RunReminderService::class)->run($now);
        Carbon::setTestNow($now = Carbon::parse('2026-10-12 17:30', 'UTC')); // 18:30 BST: the evening before the 10:00 run
        app(RunReminderService::class)->run($now);

        $titles = Notification::where('member_id', $this->plain->id)->where('category', 'run_reminders')->pluck('title')->all();
        sort($titles);
        $this->assertSame([
            'Today at 12pm: Monday club run',
            'Today at 7:30pm: Monday club run',
            'Tomorrow at 10am: Monday club run',
        ], $titles);
    }

    private function runOn(string $date, string $hm): ClubSession
    {
        return $this->session(['date' => $date] + SessionGenerator::times($date, $hm, 90, 'Europe/London'));
    }

    public function testNoNotificationTextCarriesA24HourClockTime()
    {
        // Spot check across everything above: after a mixed run, no stored title or body has HH:MM.
        $s = $this->session();
        $this->attend($s, $this->plain, 'going');
        $this->group($s, [], ['label' => 'Walk']);
        app(RunNotifier::class)->sessionChanged($s, 'cancelled');
        Carbon::setTestNow($now = Carbon::parse('2026-10-12 09:00', 'UTC'));
        app(RunReminderService::class)->run($now);

        $this->assertGreaterThan(0, Notification::count());
        foreach (Notification::all() as $row) {
            $this->assertDoesNotMatchRegularExpression('/\b\d{2}:\d{2}\b/', $row->title . ' ' . $row->body);
        }
    }
}
