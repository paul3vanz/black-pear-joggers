<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\MemberSeriesPref;
use App\Models\Notification;
use App\Models\SessionSeries;
use App\Services\FollowResolver;
use App\Services\RunReminderService;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * D117: one resolver for the feed and the notifications, checked against the shared case table
 * (tests/fixtures/follow_resolver_cases.json, also read by the app's tests). The second test
 * plays every row through the real reminder job and the follows endpoint, so "the feed and the
 * reminder job give the same answer for the same member and run" is tested end to end.
 */
class FollowResolverTest extends AppGroupsBase
{
    /** @return array<int, array{rsvp: ?string, mode: ?string, usuallyComes: bool, followed: bool, inMine: bool, why: string}> */
    private static function cases(): array
    {
        $table = json_decode(file_get_contents(__DIR__ . '/fixtures/follow_resolver_cases.json'), true);

        return array_map(function ($row) use ($table) {
            return array_combine($table['columns'], $row);
        }, $table['cases']);
    }

    public function testTheResolverMatchesTheSharedTable()
    {
        $cases = self::cases();
        $this->assertGreaterThan(20, count($cases));

        foreach ($cases as $c) {
            $this->assertSame(
                ['followed' => $c['followed'], 'inMine' => $c['inMine']],
                FollowResolver::resolve($c['rsvp'], $c['mode'], $c['usuallyComes']),
                json_encode($c)
            );
        }
    }

    public function testTheReminderJobAndTheFollowsEndpointAgreeWithTheTable()
    {
        Queue::fake();
        $series = SessionSeries::create([
            'club_id' => 1, 'title' => 'Monday club run', 'weekday' => 1, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
        $last = $this->session(['date' => '2026-10-05', 'series_id' => $series->id, 'occurrence_date' => '2026-10-05']);
        $run = $this->session(['series_id' => $series->id, 'occurrence_date' => '2026-10-12']);
        $oneOff = $this->session(['title' => 'Social run'] + SessionGenerator::times('2026-10-12', '19:30', 60, 'Europe/London'));

        $members = [];
        foreach (self::cases() as $i => $c) {
            $member = $this->member('case' . $i, 400 + $i, [], 'active', 'Case' . $i);
            $members[$i] = $member;
            $target = $c['mode'] === null ? $oneOff : $run;

            if ($c['mode'] !== null) {
                MemberSeriesPref::create(['club_id' => 1, 'member_id' => $member->id, 'series_id' => $series->id, 'mode' => $c['mode']]);
            }
            if ($c['usuallyComes']) {
                $this->attend($last, $member, 'going');
            }
            if ($c['rsvp'] !== null) {
                $this->attend($target, $member, $c['rsvp']);
            }
        }

        Carbon::setTestNow($now = Carbon::parse('2026-10-12 08:00', 'UTC'));
        app(RunReminderService::class)->run($now);

        foreach (self::cases() as $i => $c) {
            $member = $members[$i];
            $target = $c['mode'] === null ? $oneOff : $run;
            $reminded = Notification::where('member_id', $member->id)->where('dedupe_key', 'reminder:' . $target->id)->exists();
            $expected = $c['rsvp'] !== 'not_going' && ($c['followed'] || in_array($c['rsvp'], ['going', 'maybe'], true));
            $this->assertSame($expected, $reminded, 'reminder: ' . json_encode($c));

            if ($c['mode'] !== null) {
                [, $body] = $this->api('GET', '/follows', 'case' . $i);
                $row = $body['series'][0];
                $this->assertSame([$c['mode'], $c['usuallyComes'], $c['followed']], [$row['mode'], $row['usuallyComes'], $row['followed']], 'follows: ' . json_encode($c));
            }
        }
    }
}
