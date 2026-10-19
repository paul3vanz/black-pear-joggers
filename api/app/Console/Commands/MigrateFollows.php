<?php

namespace App\Console\Commands;

use App\Models\Club;
use App\Models\ClubMember;
use App\Services\SeriesFollows;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Turns the old run-reminder settings (Always / Automatic / Never) and "days I run" into one
 * follow | auto | hide mode per member and series (D117), using SeriesFollows::legacy. Members
 * already migrated are skipped, so running it twice changes nothing the second time. The old values
 * are kept.
 *
 *   php artisan app:migrate-follows --dry-run   (counts per rule, writes nothing)
 *   php artisan app:migrate-follows
 */
class MigrateFollows extends Command
{
    protected $signature = 'app:migrate-follows {--dry-run : Count what each rule would do and write nothing}';

    protected $description = 'Turn run-reminder settings and run days into per-series follow modes';

    public function handle(SeriesFollows $follows)
    {
        $dry = (bool) $this->option('dry-run');
        $totals = array_fill_keys(SeriesFollows::RULES, 0);
        $migrated = 0;
        $skipped = 0;

        foreach (Club::all() as $club) {
            $series = $follows->series($club->id);

            foreach (ClubMember::where('club_id', $club->id)->pluck('id') as $memberId) {
                $counts = DB::transaction(function () use ($follows, $club, $memberId, $dry, $series) {
                    return $follows->migrateMember($club->id, $memberId, $dry, $series);
                });

                if ($counts === null) {
                    $skipped++;

                    continue;
                }
                $migrated++;
                foreach ($counts as $rule => $n) {
                    $totals[$rule] += $n;
                }
            }
        }

        $this->info(($dry ? 'Dry run: would migrate ' : 'Migrated ') . "$migrated members ($skipped already migrated).");
        $this->table(['Rule', 'Member/series pairs'], array_map(function ($rule) use ($totals) {
            return [$rule, $totals[$rule]];
        }, SeriesFollows::RULES));

        return 0;
    }
}
