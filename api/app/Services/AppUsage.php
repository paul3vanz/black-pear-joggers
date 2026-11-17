<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * Who has actually installed the app. A club member can exist without it (backfilled from website
 * registrations), so "has the app" means one of their logins has registered a push device.
 */
class AppUsage
{
    /**
     * @param  string[]|null  $memberIds  limit the check to these members (null = the whole club)
     * @return array<string, true>  member id => true, for members with the app
     */
    public static function memberIdsWithApp(int $clubId, ?array $memberIds = null): array
    {
        $query = DB::table('member_logins as l')
            ->join('devices as d', 'd.user_id', '=', 'l.user_id')
            ->where('l.club_id', $clubId);

        if ($memberIds !== null) {
            $query->whereIn('l.member_id', $memberIds);
        }

        return array_fill_keys($query->distinct()->pluck('l.member_id')->all(), true);
    }
}
