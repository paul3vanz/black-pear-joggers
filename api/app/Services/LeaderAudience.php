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
 * A member is a candidate, with a reason, when:
 *  1. their `lead_days` is set (not null): the run's weekday, in club-local time, is in it, else no.
 *     An explicit choice always wins, even over history. Reason `chose_day`;
 *  2. else they hid the run's series: no (nobody leads a run they chose not to see, D117; this
 *     replaced the run-days check of D115);
 *  3. else they led this series before: any `session_group_leaders` row (any status) on a session of
 *     the same series in the 26 weeks before the run. Reason `led_series`;
 *  4. else they led on the same club-local weekday in that window, in another series or in a run
 *     with no series (D127: the winter Thursday run and the summer Mug Run share a day). Reason
 *     `led_day`. A run with no series only has this tier;
 *  5. else they hold the `leader` role and have never led anywhere (a brand-new leader). Reason
 *     `new_leader`;
 *  6. else no.
 */
class LeaderAudience
{
    const HISTORY_WEEKS = 26;

    const CHOSE_DAY = 'chose_day';
    const LED_SERIES = 'led_series';
    const LED_DAY = 'led_day';
    const NEW_LEADER = 'new_leader';

    /**
     * @param Collection|iterable $members ClubMember rows of this club
     * @return string[] ids of the members who may be asked, in the given order
     */
    public function candidates(ClubSession $session, string $tz, $members): array
    {
        return array_keys($this->reasons($session, $tz, $members));
    }

    /**
     * Same rules as candidates(), with the reason each member qualifies.
     *
     * @param Collection|iterable $members ClubMember rows of this club
     * @return array<string, string> member id => reason, in the given order
     */
    public function reasons(ClubSession $session, string $tz, $members): array
    {
        $members = collect($members);
        $weekday = $this->weekday($session, $tz);
        $prefs = MemberPreference::where('club_id', $session->club_id)->get()->keyBy('member_id');
        $history = $this->history($session, $tz, $weekday);
        $everLed = null;
        $series = $session->series_id ? SessionSeries::withTrashed()->find($session->series_id) : null;
        $modes = $series ? app(SeriesFollows::class)->modesForSeries($series, $members->pluck('id')->all()) : [];

        $reasons = [];
        foreach ($members as $member) {
            $pref = $prefs->get($member->id);
            $days = $pref ? MemberPreference::parseDays($pref->lead_days) : null;

            if ($days !== null) {
                if (in_array($weekday, $days, true)) {
                    $reasons[$member->id] = self::CHOSE_DAY;
                }
            } elseif (($modes[$member->id] ?? null) === MemberSeriesPref::HIDE) {
                continue;
            } elseif (isset($history['series'][$member->id])) {
                $reasons[$member->id] = self::LED_SERIES;
            } elseif (isset($history['day'][$member->id])) {
                $reasons[$member->id] = self::LED_DAY;
            } elseif ($member->hasRole('leader')) {
                $everLed = $everLed ?? array_flip(SessionGroupLeader::where('club_id', $session->club_id)->pluck('member_id')->unique()->all());

                if (!isset($everLed[$member->id])) {
                    $reasons[$member->id] = self::NEW_LEADER;
                }
            }
        }

        return $reasons;
    }

    /** ISO weekday (1 = Monday ... 7 = Sunday) of the run in club-local time. */
    public function weekday(ClubSession $session, string $tz): int
    {
        return Carbon::parse($session->starts_at)->setTimezone($tz)->dayOfWeekIso;
    }

    /**
     * Who led before this run, and how, in the 26 weeks before it starts (any leader row counts for
     * membership, withdrawn included). `series` is the same series; `day` is the same club-local
     * weekday in any series or none, so it also holds the series' own leaders.
     *
     * Each entry: ledCount (sessions with a confirmed row), lastLedOn (club-local Y-m-d of the latest
     * of those, null when none) and lastLed, the group of that latest session (else of the latest
     * session at all): kind, label, paceUnit, paceFromS, paceToS, distanceValue, distanceUnit.
     *
     * @return array{series: array<string, array>, day: array<string, array>}
     */
    public function history(ClubSession $session, string $tz, ?int $weekday = null): array
    {
        $weekday = $weekday ?? $this->weekday($session, $tz);
        $start = Carbon::parse($session->starts_at);

        $others = ClubSession::where('club_id', $session->club_id)
            ->where('id', '!=', $session->id)
            ->where('starts_at', '>=', $start->copy()->subWeeks(self::HISTORY_WEEKS))
            ->where('starts_at', '<', $start)
            ->get(['id', 'series_id', 'starts_at']);

        $seriesIds = [];
        $dayIds = [];

        foreach ($others as $other) {
            if ($session->series_id !== null && $other->series_id === $session->series_id) {
                $seriesIds[$other->id] = true;
            }

            if (Carbon::parse($other->starts_at)->setTimezone($tz)->dayOfWeekIso === $weekday) {
                $dayIds[$other->id] = true;
            }
        }

        $sessionIds = array_keys($seriesIds + $dayIds);

        if (!$sessionIds) {
            return ['series' => [], 'day' => []];
        }

        $groups = SessionGroup::withTrashed()->whereIn('session_id', $sessionIds)->get()->keyBy('id');
        $rows = $groups->isEmpty() ? collect() : SessionGroupLeader::whereIn('group_id', $groups->keys())->get();
        $startsAt = $others->keyBy('id');

        $entries = ['series' => [], 'day' => []];

        foreach ($rows as $row) {
            $group = $groups->get($row->group_id);
            $other = $startsAt->get($group->session_id);

            foreach (['series' => $seriesIds, 'day' => $dayIds] as $tier => $ids) {
                if (isset($ids[$group->session_id])) {
                    $entries[$tier][$row->member_id][] = [
                        'sessionId' => $group->session_id,
                        'startsAt' => Carbon::parse($other->starts_at),
                        'confirmed' => $row->status === SessionGroupLeader::CONFIRMED,
                        'group' => $group,
                    ];
                }
            }
        }

        foreach ($entries as $tier => $byMember) {
            foreach ($byMember as $memberId => $list) {
                $entries[$tier][$memberId] = $this->summary($list, $tz);
            }
        }

        return $entries;
    }

    /** @param array<int, array{sessionId: string, startsAt: Carbon, confirmed: bool, group: SessionGroup}> $list */
    private function summary(array $list, string $tz): array
    {
        $confirmed = array_values(array_filter($list, fn ($row) => $row['confirmed']));
        $pool = $confirmed ?: $list;
        usort($pool, fn ($a, $b) => $b['startsAt'] <=> $a['startsAt']);
        $latest = $pool[0];
        $group = $latest['group'];

        return [
            'ledCount' => count(array_unique(array_column($confirmed, 'sessionId'))),
            'lastLedOn' => $confirmed ? $latest['startsAt']->copy()->setTimezone($tz)->format('Y-m-d') : null,
            'lastLed' => [
                'kind' => $group->kind,
                'label' => $group->label,
                'paceUnit' => $group->pace_unit,
                'paceFromS' => $group->pace_from_s,
                'paceToS' => $group->pace_to_s,
                'distanceValue' => $group->distance_value,
                'distanceUnit' => $group->distance_unit,
            ],
        ];
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
