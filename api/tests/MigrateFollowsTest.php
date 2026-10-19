<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\SessionSeries;
use Illuminate\Support\Facades\Artisan;

/**
 * `app:migrate-follows` (D117): the mapping table (first match wins), the dry run's counts per
 * rule, and that a second run changes nothing.
 */
class MigrateFollowsTest extends AppGroupsBase
{
    private $mon;
    private $thu;

    protected function setUp(): void
    {
        parent::setUp();

        $this->mon = $this->series('Monday club run', 1);
        $this->thu = $this->series('Thursday Perdiswell', 4);

        // plain: Never on Thursday although Thursday is a run day; Monday Automatic on another day.
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'pace_unit' => 'mi', 'run_days' => '4']);
        MemberSeriesPref::create(['club_id' => 1, 'member_id' => $this->plain->id, 'series_id' => $this->thu->id, 'reminders' => 'off']);
        // leaderA: Always on Monday, no day filter (Thursday no_day_filter).
        MemberSeriesPref::create(['club_id' => 1, 'member_id' => $this->leaderA->id, 'series_id' => $this->mon->id, 'reminders' => 'on']);
        // leaderB: Thursday is a lead day and run days are set, so it counts as selected.
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->leaderB->id, 'pace_unit' => 'mi', 'run_days' => '1', 'lead_days' => '4']);
        // coord, committee, admin: nothing at all.
    }

    private function series(string $title, int $weekday): SessionSeries
    {
        return SessionSeries::create([
            'club_id' => 1, 'title' => $title, 'weekday' => $weekday, 'start_time' => '19:00', 'duration_min' => 60,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
    }

    private function migrate(bool $dry): string
    {
        Artisan::call('app:migrate-follows', $dry ? ['--dry-run' => true] : []);

        return Artisan::output();
    }

    /** Everything the command could touch, for "nothing changed" checks. */
    private function snapshot(): array
    {
        return [
            MemberSeriesPref::orderBy('member_id')->orderBy('series_id')->get(['member_id', 'series_id', 'reminders', 'mode', 'updated_at'])->toArray(),
            MemberPreference::orderBy('member_id')->get(['member_id', 'run_days', 'lead_days', 'follows_migrated_at', 'updated_at'])->toArray(),
        ];
    }

    /** rule => count, parsed from the command's table. */
    private function counts(string $output): array
    {
        preg_match_all('/\|\s*([a-z_]+)\s*\|\s*(\d+)\s*\|/', $output, $m, PREG_SET_ORDER);

        return array_column(array_map(function ($row) {
            return [$row[1], (int) $row[2]];
        }, $m), 1, 0);
    }

    public function testDryRunCountsEachRuleAndWritesNothing()
    {
        $before = $this->snapshot();

        $out = $this->migrate(true);

        $this->assertStringContainsString('Dry run: would migrate 6 members (0 already migrated)', $out);
        $this->assertSame([
            'never_to_hide' => 1,
            'always_to_follow' => 1,
            'automatic_on_selected_day_to_follow' => 2, // leaderB Monday (run day) and Thursday (lead day)
            'automatic_on_other_day_to_auto' => 1,      // plain Monday
            'no_day_filter_to_auto' => 7,               // leaderA Thursday + 3 members x 2 series
        ], $this->counts($out));
        $this->assertSame($before, $this->snapshot());
    }

    public function testTheRealRunAppliesTheMappingAndASecondRunChangesNothing()
    {
        $out = $this->migrate(false);
        $this->assertStringContainsString('Migrated 6 members (0 already migrated)', $out);

        $mode = function ($member, $series) {
            $row = MemberSeriesPref::where('member_id', $member->id)->where('series_id', $series->id)->first();

            return $row ? $row->mode : null;
        };
        $this->assertSame('hide', $mode($this->plain, $this->thu)); // Never wins over a selected day
        $this->assertNull($mode($this->plain, $this->mon));         // auto: no row needed
        $this->assertSame('follow', $mode($this->leaderA, $this->mon));
        $this->assertSame('follow', $mode($this->leaderB, $this->mon));
        $this->assertSame('follow', $mode($this->leaderB, $this->thu));
        $this->assertSame(4, MemberSeriesPref::count());
        $this->assertSame('off', MemberSeriesPref::where('member_id', $this->plain->id)->first()->reminders); // old data kept
        $this->assertSame(6, MemberPreference::whereNotNull('follows_migrated_at')->count());

        // A member changes something afterwards; running again must not undo it.
        $this->api('PUT', "/follows/{$this->thu->id}", 'plain', ['mode' => 'follow']);
        $this->tick();
        $after = $this->snapshot();

        $out = $this->migrate(false);

        $this->assertStringContainsString('Migrated 0 members (6 already migrated)', $out);
        $this->assertSame(array_fill_keys(array_keys($this->counts($out)), 0), $this->counts($out));
        $this->assertSame($after, $this->snapshot());
    }
}
