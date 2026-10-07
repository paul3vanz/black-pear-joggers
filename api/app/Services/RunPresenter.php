<?php

namespace App\Services;

use App\Models\ClubSession;
use App\Models\SessionSeries;
use App\Models\Venue;

/**
 * Builds the camelCase JSON shapes for venues, series and sessions.
 */
class RunPresenter
{
    public static function venue(Venue $venue): array
    {
        return [
            'id' => $venue->id,
            'name' => $venue->name,
            'address' => $venue->address,
            'lat' => $venue->lat !== null ? (float) $venue->lat : null,
            'lng' => $venue->lng !== null ? (float) $venue->lng : null,
            'notes' => $venue->notes,
            'updatedAt' => NotificationPresenter::time($venue->updated_at),
            'deletedAt' => NotificationPresenter::time($venue->deleted_at),
        ];
    }

    public static function series(SessionSeries $series): array
    {
        return [
            'id' => $series->id,
            'title' => $series->title,
            'description' => $series->description,
            'venueId' => $series->venue_id,
            'weekday' => (int) $series->weekday,
            'startTime' => $series->startHm(),
            'durationMin' => (int) $series->duration_min,
            'intervalWeeks' => (int) $series->interval_weeks,
            'validFrom' => $series->validFromYmd(),
            'validUntil' => $series->validUntilYmd(),
            'groupMode' => $series->group_mode,
            'cmsSlug' => $series->cms_slug,
            'updatedAt' => NotificationPresenter::time($series->updated_at),
            'deletedAt' => NotificationPresenter::time($series->deleted_at),
        ];
    }

    /** Expects the `series` and `coordinator` relations loaded. */
    public static function session(ClubSession $session): array
    {
        return [
            'id' => $session->id,
            'seriesId' => $session->series_id,
            'occurrenceDate' => $session->occurrenceYmd(),
            'title' => $session->title,
            'venueId' => $session->venue_id,
            'notes' => $session->notes,
            'startsAt' => self::instant($session->starts_at),
            'endsAt' => self::instant($session->ends_at),
            'localDate' => $session->localDateYmd(),
            'localStartTime' => $session->local_start_time,
            'localEndTime' => $session->local_end_time,
            'groupMode' => $session->group_mode,
            'status' => $session->status,
            'cancelReason' => $session->cancel_reason,
            'coordinatorMemberId' => $session->coordinator_member_id,
            'coordinatorName' => $session->coordinator ? $session->coordinator->display_name : null,
            'isDetached' => (bool) $session->is_detached,
            'original' => self::original($session),
            'updatedAt' => NotificationPresenter::time($session->updated_at),
            'deletedAt' => NotificationPresenter::time($session->deleted_at),
        ];
    }

    /** What the series says, for a detached occurrence that now differs from it. */
    private static function original(ClubSession $session): ?array
    {
        if (!$session->is_detached || !$session->series) {
            return null;
        }

        $series = $session->series;
        $original = [
            'localStartTime' => $series->startHm(),
            'venueId' => $series->venue_id,
            'title' => $series->title,
        ];

        $current = [
            'localStartTime' => $session->local_start_time,
            'venueId' => $session->venue_id,
            'title' => $session->title,
        ];

        return $original === $current ? null : $original;
    }

    /** Whole-second ISO8601 UTC, as in the contract example (2026-10-12T18:00:00Z). */
    private static function instant($value): ?string
    {
        return $value ? \Illuminate\Support\Carbon::parse($value)->utc()->format('Y-m-d\TH:i:s\Z') : null;
    }
}
