<?php

namespace App\Services;

use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Collection;

/**
 * camelCase JSON for run groups, plus the per-caller session summary.
 * Values are returned as entered; the canonical values (sec/km, metres) are
 * derived here and never stored.
 */
class GroupPresenter
{
    const KM_PER_MILE = 1.609344;

    /** Relations a session needs loaded so a page of sessions costs a fixed number of queries. */
    public static function eagerLoads(): array
    {
        return [
            'groups' => function ($query) {
                $query->orderBy('sort_order')->orderBy('created_at')->orderBy('id');
            },
            'groups.leaders' => function ($query) {
                $query->where('status', SessionGroupLeader::CONFIRMED)->orderBy('created_at')->orderBy('id');
            },
            'groups.leaders.member',
            'attendees:id,session_id,member_id,group_id,status',
        ];
    }

    /** Pace in seconds per km from a pace in the given unit, or null. */
    public static function perKm($seconds, ?string $unit): ?int
    {
        if ($seconds === null || $unit === null) {
            return null;
        }

        return (int) round($unit === 'mi' ? $seconds / self::KM_PER_MILE : $seconds);
    }

    public static function metres($value, ?string $unit): ?int
    {
        if ($value === null || $unit === null) {
            return null;
        }

        return (int) round((float) $value * ($unit === 'mi' ? self::KM_PER_MILE : 1) * 1000);
    }

    /**
     * @param Collection|null $attendees the session's attendee rows (any group) used for the counts;
     *                                   queried for this group when null
     * Expects `leaders.member` loaded (only confirmed rows are listed either way).
     */
    public static function group(SessionGroup $group, ?Collection $attendees = null): array
    {
        $group->loadMissing('leaders.member');

        if ($attendees === null) {
            $attendees = SessionAttendee::where('group_id', $group->id)->get(['id', 'group_id', 'member_id', 'status']);
        }

        $mine = $attendees->where('group_id', $group->id);
        $from = self::int($group->pace_from_s);
        $to = self::int($group->pace_to_s);

        return [
            'id' => $group->id,
            'sessionId' => $group->session_id,
            'kind' => $group->kind,
            'label' => $group->label,
            'description' => $group->description,
            'paceUnit' => $group->pace_unit,
            'paceFromS' => $from,
            'paceToS' => $to,
            'paceFromSPerKm' => self::perKm($from, $group->pace_unit),
            'paceToSPerKm' => self::perKm($to, $group->pace_unit),
            'distanceValue' => $group->distance_value !== null ? (float) $group->distance_value : null,
            'distanceUnit' => $group->distance_unit,
            'distanceM' => self::metres($group->distance_value, $group->distance_unit),
            'status' => $group->status,
            'sortOrder' => (int) $group->sort_order,
            'leaders' => $group->leaders
                ->filter(function ($leader) {
                    return $leader->status === SessionGroupLeader::CONFIRMED;
                })
                ->map(function ($leader) {
                    return [
                        'memberId' => $leader->member_id,
                        'displayName' => $leader->member ? $leader->member->display_name : null,
                        'role' => $leader->role,
                    ];
                })->values()->all(),
            'goingCount' => $mine->where('status', SessionAttendee::GOING)->count(),
            'maybeCount' => $mine->where('status', SessionAttendee::MAYBE)->count(),
            'updatedAt' => NotificationPresenter::time($group->updated_at),
            'deletedAt' => NotificationPresenter::time($group->deleted_at),
        ];
    }

    /** The session's live groups. Expects the relations from eagerLoads() (loads them if missing). */
    public static function groupsFor(ClubSession $session): array
    {
        $session->loadMissing(self::eagerLoads());

        return $session->groups->map(function ($group) use ($session) {
            return self::group($group, $session->attendees);
        })->all();
    }

    /** The summary block, computed for the caller. */
    public static function summary(ClubSession $session, ?string $memberId): array
    {
        $session->loadMissing(self::eagerLoads());

        $mine = $memberId ? $session->attendees->firstWhere('member_id', $memberId) : null;
        $leaders = $session->groups->flatMap(function ($group) {
            return $group->leaders->filter(function ($leader) {
                return $leader->status === SessionGroupLeader::CONFIRMED;
            });
        });

        return [
            'groupCount' => $session->groups->count(),
            'leaderCount' => $leaders->pluck('member_id')->unique()->count(),
            'goingCount' => $session->attendees->where('status', SessionAttendee::GOING)->count(),
            'maybeCount' => $session->attendees->where('status', SessionAttendee::MAYBE)->count(),
            'myStatus' => $mine ? $mine->status : null,
            'myGroupId' => $mine ? $mine->group_id : null,
            'myLeading' => $memberId ? $leaders->contains('member_id', $memberId) : false,
        ];
    }

    private static function int($value): ?int
    {
        return $value === null ? null : (int) $value;
    }
}
