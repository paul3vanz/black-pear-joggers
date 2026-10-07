<?php

namespace App\Http\Controllers\Concerns;

use App\Models\Venue;
use Illuminate\Support\Carbon;

/**
 * Shared by the club-run controllers (venues, series, sessions).
 */
trait ManagesRuns
{
    use AppResponses;

    /** Roles that may change venues, series and sessions. */
    protected static $runManagerRoles = ['committee', 'admin'];

    protected function canManageRuns($member): bool
    {
        return $member->hasRole(...self::$runManagerRoles);
    }

    protected function idConflict()
    {
        return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
    }

    /** A 422 response when venueId names no live venue of this club, else null. */
    protected function checkVenue($club, $venueId)
    {
        if ($venueId === null || $venueId === '') {
            return null;
        }

        if (!Venue::where('club_id', $club->id)->whereKey($venueId)->exists()) {
            return response()->json([
                'error' => 'validation_failed',
                'message' => 'venueId does not match a venue of this club.',
                'errors' => ['venueId' => ['venueId does not match a venue of this club.']],
            ], 422);
        }

        return null;
    }

    /** Today (Y-m-d) in the timezone of the club. */
    protected function clubToday($club): string
    {
        return Carbon::now($club->timezone ?: 'Europe/London')->format('Y-m-d');
    }
}
