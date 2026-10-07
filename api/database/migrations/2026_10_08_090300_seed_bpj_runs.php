<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Seeds Black Pear Joggers' regular runs (club 1) so they show up in the app
 * straight away. These are best guesses for the committee to correct in the
 * app. Sessions are not seeded: the hourly `app:generate-sessions` (or any
 * series write) materialises them.
 *
 * Re-running is a no-op for anything that already exists (venue by name, series
 * by title, per club). Plain inserts only, so it shows up in `migrate --pretend`.
 */
return new class extends Migration
{
    private const CLUB_ID = 1;

    public function up(): void
    {
        $now = Carbon::now();

        $venues = [
            'Old Elizabethans Cricket Club',
            'University of Worcester Riverside',
            'Nunnery Wood Track',
            'Claines Church',
            'Perdiswell Leisure Centre',
        ];

        $venueIds = [];

        foreach ($venues as $name) {
            $existing = DB::table('venues')->where('club_id', self::CLUB_ID)->where('name', $name)->value('id');

            if ($existing) {
                $venueIds[$name] = $existing;

                continue;
            }

            $venueIds[$name] = (string) Str::orderedUuid();
            DB::table('venues')->insert([
                'id' => $venueIds[$name],
                'club_id' => self::CLUB_ID,
                'name' => $name,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        // title, weekday (ISO), start, minutes, venue, group mode, valid from, valid until
        $series = [
            ['Monday club run', 1, '19:00', 90, 'Old Elizabethans Cricket Club', 'paced', '2026-01-01', null],
            ['Tuesday Riverside Run', 2, '19:00', 90, 'University of Worcester Riverside', 'paced', '2026-01-01', null],
            ['Track night', 3, '19:00', 75, 'Nunnery Wood Track', 'single', '2026-01-01', null],
            ['The Mug Run', 4, '18:30', 90, 'Claines Church', 'open', '2027-04-01', '2027-09-30'],
            ['Thursday winter run', 4, '19:00', 90, 'Perdiswell Leisure Centre', 'paced', '2026-10-01', '2027-03-31'],
            ['Sunday long run', 7, '08:00', 150, null, 'routes', '2026-01-01', null],
        ];

        foreach ($series as [$title, $weekday, $start, $minutes, $venue, $mode, $from, $until]) {
            if (DB::table('session_series')->where('club_id', self::CLUB_ID)->where('title', $title)->exists()) {
                continue;
            }

            DB::table('session_series')->insert([
                'id' => (string) Str::orderedUuid(),
                'club_id' => self::CLUB_ID,
                'title' => $title,
                'venue_id' => $venue ? $venueIds[$venue] : null,
                'weekday' => $weekday,
                'start_time' => $start,
                'duration_min' => $minutes,
                'interval_weeks' => 1,
                'valid_from' => $from,
                'valid_until' => $until,
                'group_mode' => $mode,
                'cms_slug' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        // Intentionally empty: the committee may have edited or built on these rows.
        // Rolling back the table migrations drops them anyway.
    }
};
