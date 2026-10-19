<?php

namespace App\Services;

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Who is asked to lead a run that needs a leader (D106). Shared by the run-level alert
 * (RunReminderService) and the group-level one when a leader withdraws (RunNotifier), so the two
 * can never disagree. Pace fit and the other exclusions (already leading, not going, the actor)
 * stay in RunNotifier::availableLeaders; this only answers "might they lead this run?".
 *
 * A member is a candidate when:
 *  1. their `lead_days` is set (not null): the run's weekday, in club-local time, is in it, else no.
 *     An explicit choice always wins, even over history;
 *  2. else they hid the run's series: no (nobody leads a run they chose not to see, D117; this
 *     replaced the run-days check of D115);
 *  3. else they led before: any `session_group_leaders` row (any status) on a session of the same
 *     series in the 26 weeks before the run, or, for a run with no series, on any session on the
 *     same weekday in that window;
 *  4. else they hold the `leader` role and have never led anywhere (a brand-new leader);
 *  5. else no.
 */
class LeaderAudience
{
    const HISTORY_WEEKS = 26;

    /**
     * @param Collection|iterable $members ClubMember rows of this club
     * @return string[] ids of the members who may be asked, in the given order
     */
    public function candidates(ClubSession $session, string $tz, $members): array
    {
        $members = collect($members);
        $weekday = $this->weekday($session, $tz);
        $prefs = MemberPreference::where('club_id', $session->club_id)->get()->keyBy('member_id');
        $history = array_flip($this->historyMemberIds($session, $tz, $weekday));
        $everLed = null;
        $series = $session->series_id ? SessionSeries::withTrashed()->find($session->series_id) : null;
        $modes = $series ? app(SeriesFollows::class)->modesForSeries($series, $members->pluck('id')->all()) : [];

        $ids = [];
        foreach ($members as $member) {
            $pref = $prefs->get($member->id);
            $days = $pref ? MemberPreference::parseDays($pref->lead_days) : null;

            if ($days !== null) {
                if (in_array($weekday, $days, true)) {
                    $ids[] = $member->id;
                }
            } elseif (($modes[$member->id] ?? null) === MemberSeriesPref::HIDE) {
                continue;
            } elseif (isset($history[$member->id])) {
                $ids[] = $member->id;
            } elseif ($member->hasRole('leader')) {
                $everLed = $everLed ?? array_flip(SessionGroupLeader::where('club_id', $session->club_id)->pluck('member_id')->unique()->all());

                if (!isset($everLed[$member->id])) {
                    $ids[] = $member->id;
                }
            }
        }

        return $ids;
    }

    /** ISO weekday (1 = Monday ... 7 = Sunday) of the run in club-local time. */
    public function weekday(ClubSession $session, string $tz): int
    {
        return Carbon::parse($session->starts_at)->setTimezone($tz)->dayOfWeekIso;
    }

    /**
     * Members with a leader row (any status) on a session of this series, or on the same weekday
     * for a run without a series, in the 26 weeks before this run starts.
     *
     * @return string[]
     */
    public function historyMemberIds(ClubSession $session, string $tz, ?int $weekday = null): array
    {
        $weekday = $weekday ?? $this->weekday($session, $tz);
        $start = Carbon::parse($session->starts_at);

        $query = ClubSession::where('club_id', $session->club_id)
            ->where('id', '!=', $session->id)
            ->where('starts_at', '>=', $start->copy()->subWeeks(self::HISTORY_WEEKS))
            ->where('starts_at', '<', $start);

        if ($session->series_id !== null) {
            $sessionIds = $query->where('series_id', $session->series_id)->pluck('id')->all();
        } else {
            $sessionIds = $query->get(['id', 'starts_at'])->filter(function ($other) use ($tz, $weekday) {
                return Carbon::parse($other->starts_at)->setTimezone($tz)->dayOfWeekIso === $weekday;
            })->pluck('id')->all();
        }

        if (!$sessionIds) {
            return [];
        }

        $groupIds = SessionGroup::withTrashed()->whereIn('session_id', $sessionIds)->pluck('id')->all();

        if (!$groupIds) {
            return [];
        }

        return SessionGroupLeader::whereIn('group_id', $groupIds)->pluck('member_id')->unique()->values()->all();
    }

    /** True when the member has any leader row, or has chosen days: such a member wants "leaders needed" on by default. */
    public static function wantsPrompts(ClubMember $member): bool
    {
        $pref = MemberPreference::where('club_id', $member->club_id)->where('member_id', $member->id)->first();

        if ($pref && $pref->lead_days !== null) {
            return true;
        }

        return SessionGroupLeader::where('club_id', $member->club_id)->where('member_id', $member->id)->exists();
    }
}
