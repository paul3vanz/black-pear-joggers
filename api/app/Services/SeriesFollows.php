<?php

namespace App\Services;

use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\SessionAttendee;
use App\Models\SessionSeries;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Storage for "Runs I follow" (D117): one mode per member and series in `member_series_prefs.mode`
 * (follow | auto | hide, no row = auto), plus the "usually comes" history that auto needs. What a
 * mode means for a run is `FollowResolver`'s job, not this class's.
 *
 * Members not yet migrated (`member_preferences.follows_migrated_at` null) are read through the
 * migration's own mapping (`legacy`), so they behave exactly as they will once `app:migrate-follows`
 * has run. Every write migrates the member first, so a written mode never meets old data.
 */
class SeriesFollows
{
    /** How many finished runs of a series decide "usually comes" (D35). */
    const AUTO_HISTORY = 6;

    // Migration rules, first match wins; also the dry-run report keys.
    const RULE_NEVER = 'never_to_hide';
    const RULE_ALWAYS = 'always_to_follow';
    const RULE_SELECTED_DAY = 'automatic_on_selected_day_to_follow';
    const RULE_OTHER_DAY = 'automatic_on_other_day_to_auto';
    const RULE_NO_DAYS = 'no_day_filter_to_auto';
    const RULES = [self::RULE_NEVER, self::RULE_ALWAYS, self::RULE_SELECTED_DAY, self::RULE_OTHER_DAY, self::RULE_NO_DAYS];

    /** The club's live series in week order (weekday, then time, then title). */
    public function series(int $clubId): Collection
    {
        return SessionSeries::where('club_id', $clubId)
            ->orderBy('weekday')->orderBy('start_time')->orderBy('title')
            ->get();
    }

    // ---- reading modes -------------------------------------------------------------------------

    /** The mode a stored row (or its absence) stands for. */
    public static function effective(?MemberSeriesPref $row, ?MemberPreference $pref, int $weekday): string
    {
        if ($row && $row->mode !== null) {
            return $row->mode;
        }
        if ($pref && $pref->follows_migrated_at !== null) {
            return MemberSeriesPref::AUTO;
        }

        return self::legacy($row ? $row->reminders : null, $pref, $weekday)[0];
    }

    /**
     * The migration mapping for one member and series (first match wins): Never is hide even on a
     * selected day; Always is follow; Automatic is follow on a selected day (run days, plus lead
     * days, as the old Runs tab showed them) and auto on any other day; no day filter is auto.
     *
     * @return array{0: string, 1: string} mode, rule
     */
    public static function legacy(?string $reminders, ?MemberPreference $pref, int $weekday): array
    {
        if ($reminders === MemberSeriesPref::OFF) {
            return [MemberSeriesPref::HIDE, self::RULE_NEVER];
        }
        if ($reminders === MemberSeriesPref::ON) {
            return [MemberSeriesPref::FOLLOW, self::RULE_ALWAYS];
        }
        $run = $pref ? MemberPreference::parseDays($pref->run_days) : null;
        if ($run === null) {
            return [MemberSeriesPref::AUTO, self::RULE_NO_DAYS];
        }
        $days = array_merge($run, MemberPreference::parseDays($pref->lead_days) ?? []);

        return in_array($weekday, $days, true)
            ? [MemberSeriesPref::FOLLOW, self::RULE_SELECTED_DAY]
            : [MemberSeriesPref::AUTO, self::RULE_OTHER_DAY];
    }

    /**
     * One member's mode for each series.
     *
     * @param iterable<SessionSeries> $series
     * @return array<string, string> series id => mode
     */
    public function modesForMember(int $clubId, string $memberId, iterable $series): array
    {
        $pref = MemberPreference::where('club_id', $clubId)->where('member_id', $memberId)->first();
        $rows = MemberSeriesPref::where('club_id', $clubId)->where('member_id', $memberId)->get()->keyBy('series_id');

        $modes = [];
        foreach ($series as $s) {
            $modes[$s->id] = self::effective($rows->get($s->id), $pref, (int) $s->weekday);
        }

        return $modes;
    }

    /**
     * Each given member's mode for one series.
     *
     * @param string[] $memberIds
     * @return array<string, string> member id => mode
     */
    public function modesForSeries(SessionSeries $series, array $memberIds): array
    {
        $rows = MemberSeriesPref::where('club_id', $series->club_id)->where('series_id', $series->id)->get()->keyBy('member_id');
        $prefs = MemberPreference::where('club_id', $series->club_id)->whereIn('member_id', $memberIds)->get()->keyBy('member_id');

        $modes = [];
        foreach ($memberIds as $id) {
            $modes[$id] = self::effective($rows->get($id), $prefs->get($id), (int) $series->weekday);
        }

        return $modes;
    }

    /**
     * Followed / in-My-runs for every given member on one run, with their answer for it
     * (FollowResolver). A run with no series resolves with mode null.
     *
     * @param string[] $memberIds
     * @param array<string, ?string> $rsvps member id => going | maybe | not_going (absent = no answer)
     * @return array<string, array{followed: bool, inMine: bool}>
     */
    public function resolveRun(ClubSession $session, array $memberIds, array $rsvps, Carbon $now): array
    {
        $series = $session->series_id ? SessionSeries::withTrashed()->find($session->series_id) : null;
        $modes = $series ? $this->modesForSeries($series, $memberIds) : [];
        $usual = $series ? array_flip($this->usualMemberIds($series, $now, $session->id, $session->isEventMode())) : [];

        $out = [];
        foreach ($memberIds as $id) {
            $out[$id] = FollowResolver::resolve($rsvps[$id] ?? null, $series ? $modes[$id] : null, isset($usual[$id]));
        }

        return $out;
    }

    // ---- "usually comes" (D35) -----------------------------------------------------------------

    /**
     * Members who were going at one of the last 6 ended, not-cancelled runs of the series (never
     * $exceptSessionId). Events and races have no "usually comes" (D79), so for those it is nobody.
     *
     * @return string[]
     */
    public function usualMemberIds(SessionSeries $series, Carbon $now, ?string $exceptSessionId = null, ?bool $eventMode = null): array
    {
        if ($eventMode ?? in_array($series->group_mode, SessionSeries::EVENT_MODES, true)) {
            return [];
        }

        $recent = ClubSession::where('series_id', $series->id)
            ->when($exceptSessionId, function ($q) use ($exceptSessionId) {
                $q->where('id', '!=', $exceptSessionId);
            })
            ->where('status', ClubSession::STATUS_SCHEDULED)
            ->where('ends_at', '<', $now->copy()->utc())
            ->orderByDesc('starts_at')
            ->limit(self::AUTO_HISTORY)
            ->pluck('id');

        if ($recent->isEmpty()) {
            return [];
        }

        return SessionAttendee::whereIn('session_id', $recent)
            ->where('status', SessionAttendee::GOING)
            ->pluck('member_id')->unique()->values()->all();
    }

    // ---- writing -------------------------------------------------------------------------------

    /**
     * Saves modes for one member (migrating them first) and returns what each series was before.
     * Writing the same mode again changes nothing, so retries are safe.
     *
     * @param array<string, string> $modes series id => mode, series of this club
     * @return array<string, string> series id => previous mode
     */
    public function set(int $clubId, string $memberId, array $modes): array
    {
        return DB::transaction(function () use ($clubId, $memberId, $modes) {
            $this->migrateMember($clubId, $memberId);

            $series = SessionSeries::where('club_id', $clubId)->whereIn('id', array_map('strval', array_keys($modes)))->get();
            $previous = $this->modesForMember($clubId, $memberId, $series);

            foreach ($modes as $seriesId => $mode) {
                if (!array_key_exists($seriesId, $previous) || $previous[$seriesId] === $mode) {
                    continue; // not a live series of this club, or unchanged
                }
                MemberSeriesPref::updateOrCreate(
                    ['member_id' => $memberId, 'series_id' => (string) $seriesId],
                    ['club_id' => $clubId, 'mode' => $mode]
                );
            }

            return $previous;
        });
    }

    /**
     * Old app versions' "days I run" save (D115), kept for the rollout: every auto series on those
     * days becomes follow, the bulk equivalent of Follow all. Hidden and followed series are left
     * alone, the same as the migration treats a Never on a selected day.
     *
     * @param int[] $days ISO weekdays
     */
    public function followDays(int $clubId, string $memberId, array $days): void
    {
        $series = $this->series($clubId)->filter(function ($s) use ($days) {
            return in_array((int) $s->weekday, $days, true);
        });
        $modes = $this->modesForMember($clubId, $memberId, $series);

        $this->set($clubId, $memberId, array_map(function () {
            return MemberSeriesPref::FOLLOW;
        }, array_filter($modes, function ($mode) {
            return $mode === MemberSeriesPref::AUTO;
        })));
    }

    // ---- migration -----------------------------------------------------------------------------

    /**
     * Turns one member's old reminder settings and run days into modes (the `legacy` mapping) and
     * marks them migrated. Only non-auto results and existing rows are written; the old
     * `reminders` value and `run_days` are kept.
     *
     * @param ?Collection $series the club's live series (loaded when null)
     * @return ?array<string, int> rule => member/series pairs, or null when already migrated (nothing
     *                             to do). A dry run counts the same and writes nothing.
     */
    public function migrateMember(int $clubId, string $memberId, bool $dryRun = false, ?Collection $series = null): ?array
    {
        $pref = MemberPreference::where('club_id', $clubId)->where('member_id', $memberId)->first();

        if ($pref && $pref->follows_migrated_at !== null) {
            return null;
        }

        $series = $series ?? $this->series($clubId);
        $rows = MemberSeriesPref::where('club_id', $clubId)->where('member_id', $memberId)->get()->keyBy('series_id');
        $counts = array_fill_keys(self::RULES, 0);
        $now = Carbon::now();

        foreach ($series as $s) {
            $row = $rows->get($s->id);
            [$mode, $rule] = self::legacy($row ? $row->reminders : null, $pref, (int) $s->weekday);
            $counts[$rule]++;

            if ($dryRun || (!$row && $mode === MemberSeriesPref::AUTO)) {
                continue;
            }
            if ($row) {
                $row->mode = $row->mode ?? $mode;
                $row->save();
            } else {
                MemberSeriesPref::create(['club_id' => $clubId, 'member_id' => $memberId, 'series_id' => $s->id, 'mode' => $mode]);
            }
        }

        if (!$dryRun) {
            if (!$pref) {
                $pref = new MemberPreference(['club_id' => $clubId, 'member_id' => $memberId, 'pace_unit' => 'mi', 'distance_unit' => 'mi']);
            } else {
                $pref->timestamps = false; // the marker is not a change the member made
            }
            $pref->follows_migrated_at = $now;
            $pref->save();
        }

        return $counts;
    }
}
