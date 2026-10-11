<?php

namespace App\Services;

use App\Models\ClubSession;
use App\Models\SessionGroup;
use App\Models\Venue;
use Illuminate\Support\Carbon;

/**
 * Plain-English snippets for run notifications (club-local day, time, venue,
 * group names in the recipient's pace unit).
 */
class RunText
{
    const BODY_MAX = 140;

    public static function local(Carbon $time, string $tz): Carbon
    {
        return $time->copy()->setTimezone($tz);
    }

    /** "Tuesday 14 Oct" */
    public static function day(Carbon $time, string $tz): string
    {
        return self::local($time, $tz)->format('l j M');
    }

    /** "7:30pm" (club-local start of an instant). */
    public static function time(Carbon $time, string $tz): string
    {
        return self::clock(self::local($time, $tz)->format('H:i'));
    }

    /**
     * The club's way of writing a time: 24-hour "HH:MM" in, "h[:mm]am|pm" out.
     * No leading zero, minutes dropped on the hour: 07:00 = "7am", 19:30 = "7:30pm",
     * 12:00 = "12pm" (noon), 00:00 = "12am" (midnight). Anything unparseable comes back unchanged.
     */
    public static function clock(string $hm): string
    {
        [$h, $m, $suffix] = self::clockParts($hm) ?? [null, null, null];

        if ($h === null) {
            return $hm;
        }

        return $h . ($m === 0 ? '' : sprintf(':%02d', $m)) . $suffix;
    }

    /**
     * A start-end range: "7-8:30pm" when both ends share am/pm, "11am-1pm" when they do not,
     * and just the start ("7pm") when there is no end.
     */
    public static function range(string $startHm, ?string $endHm): string
    {
        $start = self::clockParts($startHm);
        $end = $endHm === null ? null : self::clockParts($endHm);

        if (!$start || !$end) {
            return self::clock($startHm);
        }

        $first = $start[0] . ($start[1] === 0 ? '' : sprintf(':%02d', $start[1])) . ($start[2] === $end[2] ? '' : $start[2]);

        return $first . '-' . self::clock($endHm);
    }

    /** @return array{0:int,1:int,2:string}|null hour (1-12), minute, am|pm */
    private static function clockParts(string $hm): ?array
    {
        if (!preg_match('/^(\d{1,2}):(\d{2})(?::\d{2})?$/', trim($hm), $match) || (int) $match[1] > 23 || (int) $match[2] > 59) {
            return null;
        }

        $hour = (int) $match[1];

        return [$hour % 12 === 0 ? 12 : $hour % 12, (int) $match[2], $hour >= 12 ? 'pm' : 'am'];
    }

    public static function venueName(?string $venueId): ?string
    {
        if (!$venueId) {
            return null;
        }

        $venue = Venue::withTrashed()->find($venueId);

        return $venue ? $venue->name : null;
    }

    /**
     * "Jog/walk 9:00-9:30/mi", "9:00-9:30/mi", "Jog/walk", or null for a group with
     * neither a label nor a pace.
     */
    public static function groupName(SessionGroup $group, ?string $unit): ?string
    {
        $parts = array_filter([
            $group->label ? trim($group->label) : null,
            PaceMatcher::formatGroup($group, $unit) ?: null,
        ]);

        return $parts ? implode(' ', $parts) : null;
    }

    /** Cuts a message to the body limit, ending with an ellipsis when it was cut. */
    public static function clip(string $text, int $max = self::BODY_MAX): string
    {
        return mb_strlen($text) <= $max ? $text : rtrim(mb_substr($text, 0, $max - 1)) . '…';
    }

    /** The data block every run notification carries. */
    public static function data(ClubSession $session, ?string $groupId = null): array
    {
        $data = ['route' => '/runs/' . $session->id, 'sessionId' => $session->id];

        if ($groupId !== null) {
            $data['groupId'] = $groupId;
        }

        return $data;
    }
}
