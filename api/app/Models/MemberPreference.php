<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * A member's pace/distance units, usual pace range and the days they run and may lead, for one club.
 *
 * `run_days` and `lead_days` are comma-separated ISO weekdays (1 = Monday ... 7 = Sunday): null =
 * never chosen, '' = chose none. Lead days are kept inside run days when both are set (D115).
 */
final class MemberPreference extends Model
{
    use HasUuids;

    const UNITS = ['mi', 'km'];

    protected $fillable = [
        'club_id',
        'member_id',
        'pace_unit',
        'distance_unit',
        'pace_from_s',
        'pace_to_s',
        'push_daily_cap',
        'lead_days',
        'run_days',
    ];

    protected $casts = [
        'push_daily_cap' => 'integer',
        'lead_days' => 'string',
        'run_days' => 'string',
    ];

    /** ISO weekdays (1-7), sorted: null = never chosen, [] = none. */
    public static function parseDays($raw): ?array
    {
        if ($raw === null) {
            return null;
        }
        $days = [];
        foreach (explode(',', (string) $raw) as $d) {
            if ($d !== '' && ctype_digit($d) && (int) $d >= 1 && (int) $d <= 7) {
                $days[] = (int) $d;
            }
        }
        $days = array_values(array_unique($days));
        sort($days);

        return $days;
    }

    /** The stored form of a weekday list (null stays null, [] becomes ''). */
    public static function formatDays(?array $days): ?string
    {
        if ($days === null) {
            return null;
        }
        $days = array_values(array_unique(array_map('intval', $days)));
        sort($days);

        return implode(',', $days);
    }

    /**
     * Whether a member with these preferences runs on $weekday (ISO), for run notifications they did
     * not ask for by answering (D115): no run days chosen means every day, and a day they may lead
     * always counts.
     */
    public static function runsOn(?self $pref, int $weekday): bool
    {
        $run = $pref ? self::parseDays($pref->run_days) : null;

        if ($run === null) {
            return true;
        }

        return in_array($weekday, $run, true) || in_array($weekday, self::parseDays($pref->lead_days) ?? [], true);
    }

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id')->withTrashed();
    }
}
