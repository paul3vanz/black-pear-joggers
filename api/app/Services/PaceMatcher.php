<?php

namespace App\Services;

use App\Models\MemberPreference;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;

/**
 * The server-side pace matching rule (D28, same as PaceSpec in the app).
 *
 * A pace band is a [fast, slow] pair in seconds per km. A range is used as it
 * stands; a single pace is widened by TOLERANCE either side. Two bands match
 * when they touch. A member or group with no pace never matches anything.
 */
class PaceMatcher
{
    /** Seconds per km either side of a single pace. */
    const TOLERANCE = 15;

    /**
     * @return array{0: float, 1: float}|null [fast, slow] in s/km, null when there is no pace
     */
    public static function band(?string $unit, $fromS, $toS): ?array
    {
        if ($unit === null || $unit === '' || $fromS === null) {
            return null;
        }

        $from = GroupPresenter::perKm((int) $fromS, $unit);

        if ($toS === null || (int) $toS === (int) $fromS) {
            return [$from - self::TOLERANCE, $from + self::TOLERANCE];
        }

        $to = GroupPresenter::perKm((int) $toS, $unit);

        return [min($from, $to), max($from, $to)];
    }

    public static function groupBand(SessionGroup $group): ?array
    {
        return self::band($group->pace_unit, $group->pace_from_s, $group->pace_to_s);
    }

    /** True when both bands exist and touch. */
    public static function overlaps(?array $a, ?array $b): bool
    {
        return $a !== null && $b !== null && $a[0] <= $b[1] && $b[0] <= $a[1];
    }

    /**
     * The band a member would run at: their per-run answer if it carries a pace,
     * otherwise their usual range from their preferences.
     */
    public static function memberBand(?SessionAttendee $attendee, ?MemberPreference $preference): ?array
    {
        if ($attendee && $attendee->pace_unit && $attendee->pace_from_s !== null) {
            return self::band($attendee->pace_unit, $attendee->pace_from_s, $attendee->pace_to_s);
        }

        if ($preference) {
            return self::band($preference->pace_unit, $preference->pace_from_s, $preference->pace_to_s);
        }

        return null;
    }

    /** True when the member's effective pace fits the group's pace. */
    public static function memberFitsGroup(?SessionAttendee $attendee, ?MemberPreference $preference, SessionGroup $group): bool
    {
        return self::overlaps(self::memberBand($attendee, $preference), self::groupBand($group));
    }

    /**
     * "9:30/mi" or "9:00-9:30/mi", shown in $viewerUnit ('mi' or 'km').
     * Empty when there is no pace.
     */
    public static function format(?string $unit, $fromS, $toS, ?string $viewerUnit = 'mi'): string
    {
        if ($unit === null || $unit === '' || $fromS === null) {
            return '';
        }

        $viewerUnit = $viewerUnit === 'km' ? 'km' : 'mi';
        $from = self::convert((int) $fromS, $unit, $viewerUnit);
        $text = self::clock($from);

        if ($toS !== null && (int) $toS !== (int) $fromS) {
            $to = self::convert((int) $toS, $unit, $viewerUnit);
            $text = self::clock(min($from, $to)) . '-' . self::clock(max($from, $to));
        }

        return $text . '/' . $viewerUnit;
    }

    public static function formatGroup(SessionGroup $group, ?string $viewerUnit = 'mi'): string
    {
        return self::format($group->pace_unit, $group->pace_from_s, $group->pace_to_s, $viewerUnit);
    }

    /** Seconds per $from-unit to seconds per $to-unit, rounded to whole seconds. */
    private static function convert(int $seconds, string $from, string $to): int
    {
        if ($from === $to) {
            return $seconds;
        }

        return (int) round($from === 'mi' ? $seconds / GroupPresenter::KM_PER_MILE : $seconds * GroupPresenter::KM_PER_MILE);
    }

    private static function clock(int $seconds): string
    {
        return intdiv($seconds, 60) . ':' . str_pad((string) ($seconds % 60), 2, '0', STR_PAD_LEFT);
    }
}
