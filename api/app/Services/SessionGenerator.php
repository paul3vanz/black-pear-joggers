<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubSession;
use App\Models\SessionSeries;
use Illuminate\Support\Carbon;

/**
 * Materialises club run sessions from their weekly series, 8 weeks ahead
 * (contract: mobile/docs/api-contract.md, "Generation rules").
 *
 * Idempotent: a run with nothing to change writes nothing, so `updated_at`
 * (and therefore the app's `?since=` sync) only moves when a row really changes.
 * Detached sessions (edited or cancelled by hand), past sessions, `notes` and
 * `coordinator_member_id` are never touched.
 */
class SessionGenerator
{
    const HORIZON_DAYS = 56; // 8 weeks

    /** @var array<int, string> club id => timezone */
    private $timezones = [];

    /**
     * @return array{created:int, updated:int, restored:int, deleted:int}
     */
    public function generateForSeries(SessionSeries $series, ?Carbon $today = null): array
    {
        $tz = $this->timezoneFor($series->club_id);
        $todayYmd = ($today ? $today->copy()->setTimezone($tz) : Carbon::now($tz))->format('Y-m-d');
        $wanted = $series->trashed() ? [] : $this->occurrenceDates($series, $todayYmd);

        $stats = ['created' => 0, 'updated' => 0, 'restored' => 0, 'deleted' => 0];

        // Existing rows from today on, including soft-deleted ones (the unique
        // key still covers them, so a returning date is restored, not inserted).
        $existing = ClubSession::withTrashed()
            ->where('series_id', $series->id)
            ->where('occurrence_date', '>=', $todayYmd)
            ->get()
            ->keyBy(function (ClubSession $s) {
                return $s->occurrenceYmd();
            });

        foreach ($wanted as $date) {
            $fields = $this->fieldsFor($series, $date, $tz);
            $session = $existing->get($date);

            if (!$session) {
                ClubSession::create($fields + [
                    'club_id' => $series->club_id,
                    'series_id' => $series->id,
                    'occurrence_date' => $date,
                ]);
                $stats['created']++;

                continue;
            }

            if ($session->is_detached) {
                continue;
            }

            $wasTrashed = $session->trashed();
            $session->fill($fields);

            if ($wasTrashed) {
                $session->restore();
                $session->save();
                $stats['restored']++;
            } elseif ($session->isDirty()) {
                $session->save();
                $stats['updated']++;
            }
        }

        // Future, non-detached rows that no longer match the series.
        foreach ($existing as $date => $session) {
            if (!$session->is_detached && !$session->trashed() && !in_array($date, $wanted, true)) {
                $session->delete();
                $stats['deleted']++;
            }
        }

        return $stats;
    }

    /** Runs every series (soft-deleted ones too, so their future sessions are cleaned up). */
    public function generateAll(?Carbon $today = null): array
    {
        $total = ['series' => 0, 'created' => 0, 'updated' => 0, 'restored' => 0, 'deleted' => 0];

        foreach (SessionSeries::withTrashed()->orderBy('created_at')->get() as $series) {
            $stats = $this->generateForSeries($series, $today);
            $total['series']++;

            foreach ($stats as $key => $count) {
                $total[$key] += $count;
            }
        }

        return $total;
    }

    /**
     * Y-m-d dates in [today, today + 8 weeks] on the series weekday, inside
     * [valid_from, valid_until], every interval_weeks weeks counted from the
     * week (Monday start) containing valid_from.
     *
     * @return string[]
     */
    public function occurrenceDates(SessionSeries $series, string $todayYmd): array
    {
        $from = Carbon::parse($series->validFromYmd(), 'UTC')->startOfDay();
        $until = $series->validUntilYmd();
        $cursor = Carbon::parse($todayYmd, 'UTC')->startOfDay();
        $horizon = $cursor->copy()->addDays(self::HORIZON_DAYS);
        $firstWeek = $from->copy()->startOfWeek(Carbon::MONDAY);
        $interval = max(1, (int) $series->interval_weeks);

        $dates = [];

        for (; $cursor->lte($horizon); $cursor->addDay()) {
            if ($cursor->dayOfWeekIso !== (int) $series->weekday || $cursor->lt($from)) {
                continue;
            }

            if ($until !== null && $cursor->format('Y-m-d') > $until) {
                continue;
            }

            $weeks = intdiv($firstWeek->diffInDays($cursor->copy()->startOfWeek(Carbon::MONDAY)), 7);

            if ($weeks % $interval === 0) {
                $dates[] = $cursor->format('Y-m-d');
            }
        }

        return $dates;
    }

    /** The columns a series controls on one of its sessions. */
    private function fieldsFor(SessionSeries $series, string $date, string $tz): array
    {
        return [
            'title' => $series->title,
            'venue_id' => $series->venue_id,
            'group_mode' => $series->group_mode,
        ] + self::times($date, $series->startHm(), (int) $series->duration_min, $tz);
    }

    /**
     * Club-local date + start (HH:MM) + duration to the session time columns.
     * The local wall-clock time is converted with the club timezone, so a
     * 19:00 run is 18:00Z in BST and 19:00Z in GMT.
     */
    public static function times(string $date, string $startHm, int $durationMin, string $tz): array
    {
        $starts = Carbon::createFromFormat('Y-m-d H:i', "$date $startHm", $tz)->utc();
        $ends = $starts->copy()->addMinutes($durationMin);

        return [
            'starts_at' => $starts,
            'ends_at' => $ends,
            'local_date' => $date,
            'local_start_time' => $startHm,
            'local_end_time' => $ends->copy()->setTimezone($tz)->format('H:i'),
        ];
    }

    private function timezoneFor(int $clubId): string
    {
        if (!isset($this->timezones[$clubId])) {
            $this->timezones[$clubId] = Club::find($clubId)->timezone ?? 'Europe/London';
        }

        return $this->timezones[$clubId];
    }
}
