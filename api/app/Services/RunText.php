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

    /** "19:30" */
    public static function time(Carbon $time, string $tz): string
    {
        return self::local($time, $tz)->format('H:i');
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
