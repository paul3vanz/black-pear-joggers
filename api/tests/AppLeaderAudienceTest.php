<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Services\LeaderAudience;
use App\Services\NotificationCategories;
use App\Services\RunReminderService;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * D106: who is asked to lead. The same audience rules apply to the run-level alert
 * (RunReminderService) and the group-level alert when a leader withdraws (RunNotifier), so every
 * scenario runs through both channels.
 *
 * Now is Monday 2026-10-12 09:00Z; the run is that evening (19:00 London) or, in the timezone test,
 * Monday 2026-10-19 00:30 London, which is still Sunday in UTC. leaderB ("Lou") holds the leader
 * role and has never led, so every scenario asks Lou too.
 */
class AppLeaderAudienceTest extends AppGroupsBase
{
    /** @var SessionSeries */
    private $monday;
    /** @var SessionSeries */
    private $wednesday;
    /** @var array<string, ClubMember> */
    private $m = [];
    private $nextId = 400;

    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();

        $this->monday = SessionSeries::create([
            'club_id' => 1, 'title' => 'Monday club run', 'weekday' => 1, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
        $this->wednesday = SessionSeries::create([
            'club_id' => 1, 'title' => 'Wednesday', 'weekday' => 3, 'start_time' => '19:00', 'duration_min' => 60,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
    }

    private function who(string $key, array $roles = [], string $status = 'active'): ClubMember
    {
        $id = $this->nextId++;

        return $this->m[$key] = $this->member('sub-' . $key, $id, $roles, $status, $key);
    }

    private function days(ClubMember $member, ?string $days): void
    {
        MemberPreference::updateOrCreate(
            ['club_id' => 1, 'member_id' => $member->id],
            ['pace_unit' => 'mi', 'distance_unit' => 'mi', 'lead_days' => $days]
        );
    }

    private function sessionOn(?SessionSeries $series, string $date, string $hm): ClubSession
    {
        return $this->session(['date' => $date, 'series_id' => $series ? $series->id : null, 'occurrence_date' => $series ? $date : null]
            + SessionGenerator::times($date, $hm, 90, 'Europe/London'));
    }

    /** A leader row (default: withdrawn, to show any status counts) on a session of $series on $date. */
    private function ledBefore(ClubMember $member, string $date, ?SessionSeries $series, string $status = 'withdrawn', string $hm = '19:00'): void
    {
        $session = $series ? ClubSession::where('series_id', $series->id)->where('occurrence_date', $date)->first() : null;
        $session = $session ?: $this->sessionOn($series, $date, $hm);
        $group = $this->group($session, [], ['label' => 'Old', 'status' => 'active']);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $group->id, 'member_id' => $member->id, 'status' => $status]);
    }

    /**
     * Fires the alert through one channel and returns the sorted first names of members asked to lead.
     *
     * @param string $channel 'run' (reminder service, leaderless group) or 'group' (leaderA withdraws)
     */
    private function asked(string $channel, ClubSession $run, string $nowUtc = '2026-10-12 08:00'): array
    {
        if ($channel === 'run') {
            $this->group($run, [], ['label' => 'Steady', 'pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
            Carbon::setTestNow($now = Carbon::parse($nowUtc, 'UTC'));
            app(RunReminderService::class)->run($now);
        } else {
            $group = $this->group($run, [$this->leaderA], ['label' => 'Steady', 'pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
            $this->attend($run, $this->leaderA, 'going', $group);
            [$status] = $this->api('DELETE', "/groups/{$group->id}/leaders/me", 'leaderA');
            $this->assertSame(200, $status);
        }

        $names = Notification::where('category', 'leaders_needed')->get()->map(function ($row) {
            return explode(' ', ClubMember::find($row->member_id)->display_name)[0];
        })->all();
        sort($names);

        return $names;
    }

    /** @return array<int, array{string}> */
    public function channels(): array
    {
        return [['run'], ['group']];
    }

    /** @dataProvider channels */
    public function testTheAudienceMatrixOnASeriesRun(string $channel)
    {
        $run = $this->sessionOn($this->monday, '2026-10-12', '19:00');

        // Rule 1: chosen days decide, over history and over the role.
        $this->days($this->who('daysMatch'), '1,3');
        $this->days($this->who('daysOther'), '2,4');
        $this->ledBefore($this->m['daysOther'], '2026-10-05', $this->monday);
        $this->days($this->who('daysNone'), '');
        $this->ledBefore($this->m['daysNone'], '2026-10-05', $this->monday);
        $this->days($this->who('daysOtherLeaderRole', ['leader']), '2,3');
        $this->days($this->who('daysMatchOtherHistory', ['leader']), '1');
        $this->ledBefore($this->m['daysMatchOtherHistory'], '2026-10-07', $this->wednesday);

        // Rule 2: led this series before (any status), plain member or not.
        $this->ledBefore($this->who('historySeries'), '2026-10-05', $this->monday, 'withdrawn');
        $this->ledBefore($this->who('historyConfirmed'), '2026-09-28', $this->monday, 'confirmed');
        $this->ledBefore($this->who('historyOtherSeries'), '2026-10-07', $this->wednesday);
        // Rule 3 does not apply once someone has led anywhere: a role-only leader with history elsewhere.
        $this->ledBefore($this->who('roleHistoryElsewhere', ['leader']), '2026-10-07', $this->wednesday);

        // Rule 3: a brand-new leader (a preferences row without days does not change that).
        $this->days($this->who('newLeader', ['leader']), null);

        // Rule 4 and the existing exclusions.
        $this->who('plain');
        $this->days($this->who('notGoing'), '1');
        $this->attend($run, $this->m['notGoing'], 'not_going');
        $this->days($this->who('alreadyLeading'), '1');
        $this->group($run, [$this->m['alreadyLeading']], ['label' => 'Other']);
        $this->days($this->who('inactive', [], 'inactive'), '1');

        $this->assertSame(
            ['Lou', 'daysMatch', 'daysMatchOtherHistory', 'historyConfirmed', 'historySeries', 'newLeader'],
            $this->asked($channel, $run)
        );
    }

    /** @dataProvider channels */
    public function testALeaderWhoOnlyLedAnotherSeriesIsNotAskedForThisOne(string $channel)
    {
        $run = $this->sessionOn($this->monday, '2026-10-12', '19:00');
        $this->ledBefore($this->who('roleOnWednesdays', ['leader']), '2026-10-07', $this->wednesday);

        $this->assertSame(['Lou'], $this->asked($channel, $run));
    }

    /** @dataProvider channels */
    public function testTheTwentySixWeekWindowIsInclusiveAtItsStart(string $channel)
    {
        $run = $this->sessionOn($this->monday, '2026-10-12', '19:00');
        // 2026-10-12 19:00 London minus 26 weeks = 2026-04-13 19:00 London: exactly on the edge.
        $this->ledBefore($this->who('onTheEdge'), '2026-04-13', $this->monday);
        $this->ledBefore($this->who('aWeekTooOld'), '2026-04-06', $this->monday);
        $this->ledBefore($this->who('recent'), '2026-09-14', $this->monday);

        $this->assertSame(['Lou', 'onTheEdge', 'recent'], $this->asked($channel, $run));
    }

    /** @dataProvider channels */
    public function testARunWithoutASeriesUsesSameWeekdayHistory(string $channel)
    {
        $run = $this->sessionOn(null, '2026-10-12', '19:00'); // an ad-hoc Monday run
        $this->ledBefore($this->who('adHocMonday'), '2026-10-05', null);
        $this->ledBefore($this->who('adHocWednesday'), '2026-10-07', null);
        $this->ledBefore($this->who('seriesMonday'), '2026-09-28', $this->monday);
        $this->ledBefore($this->who('oldMonday'), '2026-04-06', null); // 27 weeks back
        $this->days($this->who('daysTuesday'), '2');
        $this->ledBefore($this->m['daysTuesday'], '2026-10-05', null);
        $this->days($this->who('daysMonday'), '1');

        $this->assertSame(['Lou', 'adHocMonday', 'daysMonday', 'seriesMonday'], $this->asked($channel, $run));
    }

    /** @dataProvider channels */
    public function testTheWeekdayIsClubLocalNotUtc(string $channel)
    {
        // Monday 2026-10-19 00:30 BST is Sunday 23:30Z.
        $run = $this->sessionOn(null, '2026-10-19', '00:30');
        $this->assertSame(7, Carbon::parse($run->starts_at)->setTimezone('UTC')->dayOfWeekIso);
        $this->assertSame(1, app(LeaderAudience::class)->weekday($run, 'Europe/London'));

        $this->days($this->who('mondays'), '1');
        $this->days($this->who('sundays'), '7');
        $this->ledBefore($this->who('midnightMonday'), '2026-10-12', null, 'withdrawn', '00:30'); // Monday in London, Sunday in UTC

        $this->assertSame(['Lou', 'midnightMonday', 'mondays'], $this->asked($channel, $run, '2026-10-18 12:00'));
    }

    public function testThePaceFitStillAppliesToTheGroupLevelAlert()
    {
        $run = $this->sessionOn($this->monday, '2026-10-12', '19:00');
        $fits = $this->who('fits');
        $slow = $this->who('slow');
        $this->days($fits, '1');
        $this->days($slow, '1');
        MemberPreference::where('member_id', $slow->id)->update(['pace_from_s' => 780, 'pace_to_s' => 840]);

        $this->assertSame(['Lou', 'fits'], $this->asked('group', $run));
    }

    public function testDefaultsForTheLeadersNeededCategory()
    {
        $plain = $this->who('plainOne');
        $badge = $this->who('badge', ['leader']);
        $chose = $this->who('chose');
        $this->days($chose, '');
        $neverChose = $this->who('neverChose');
        $this->days($neverChose, null); // a row, but no days chosen
        $led = $this->who('led');
        $this->ledBefore($led, '2026-10-05', $this->monday);

        $on = function (ClubMember $member) {
            return NotificationCategories::defaultFor('leaders_needed', $member);
        };

        $this->assertFalse($on($plain));
        $this->assertTrue($on($badge));
        $this->assertTrue($on($chose)); // days set (even "none") is not null
        $this->assertFalse($on($neverChose));
        $this->assertTrue($on($led));
        $this->assertTrue(NotificationCategories::defaultFor('run_reminders', $plain)); // others unchanged
    }

    /** @dataProvider channels */
    public function testWithoutLeadDaysTheRunDaysLimitTheFallback(string $channel)
    {
        $run = $this->sessionOn($this->monday, '2026-10-12', '19:00');
        $this->ledBefore($this->who('historyMonday'), '2026-10-05', $this->monday);
        $this->ledBefore($this->who('historyWednesday'), '2026-10-05', $this->monday);
        $this->who('newLeaderWednesday', ['leader']);
        $this->who('leadsMondayRunsWednesday');
        foreach (['historyMonday' => '1,3', 'historyWednesday' => '3', 'newLeaderWednesday' => '3'] as $key => $days) {
            MemberPreference::updateOrCreate(['club_id' => 1, 'member_id' => $this->m[$key]->id], ['pace_unit' => 'mi', 'distance_unit' => 'mi', 'run_days' => $days]);
        }
        // Explicit lead days still win over run days.
        MemberPreference::updateOrCreate(['club_id' => 1, 'member_id' => $this->m['leadsMondayRunsWednesday']->id], ['pace_unit' => 'mi', 'distance_unit' => 'mi', 'run_days' => '3', 'lead_days' => '1']);

        $this->assertSame(['Lou', 'historyMonday', 'leadsMondayRunsWednesday'], $this->asked($channel, $run));
    }

    public function testAnExplicitPreferenceStillWinsAndAMemberWithDaysNeedsNoRole()
    {
        $run = $this->sessionOn($this->monday, '2026-10-12', '19:00');
        $this->days($this->who('opted'), '1');
        $this->days($this->who('optedOut'), '1');
        NotificationPreference::create([
            'club_id' => 1, 'member_id' => $this->m['optedOut']->id, 'category' => 'leaders_needed', 'push_enabled' => false,
        ]);

        $this->assertSame(['Lou', 'opted', 'optedOut'], $this->asked('run', $run));

        // Both have the inbox row; only the one with no opt-out is pushed (no `leader` role needed).
        $pushed = function (string $key) {
            return Notification::where('category', 'leaders_needed')->where('member_id', $this->m[$key]->id)->first()->push_requested_at;
        };
        $this->assertNotNull($pushed('opted'));
        $this->assertNull($pushed('optedOut'));
    }
}
