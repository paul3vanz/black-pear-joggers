<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\Notification;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;

/**
 * The time-driven run notifications (Phase 5b, D31, D35), found by
 * `app:send-reminders` every 10 minutes:
 *
 *  - morning-of reminders (`run_reminders`, with going / not-going buttons)
 *  - "leaders needed" for runs within 72 hours (`leaders_needed`)
 *
 * Both are idempotent through dedupe keys, so the command can run late or twice.
 * "Now" is injected so tests can fix the clock; times are the club's local time.
 */
class RunReminderService
{
    /** Runs starting at or after this local hour are reminded that morning. */
    const LATE_START_HOUR = 11;
    const MORNING_HOUR = 8;
    /** Earlier runs are reminded the evening before. */
    const EVENING_HOUR = 18;
    /** The "leaders needed" check starts each local day at this hour. */
    const LEADERS_AFTER_HOUR = 9;
    const LEADERS_WINDOW_HOURS = 72;
    /** How many finished runs of a series decide who is reminded automatically. */
    const AUTO_HISTORY = 6;

    /** @var RunNotifier */
    private $notifier;

    public function __construct(RunNotifier $notifier)
    {
        $this->notifier = $notifier;
    }

    /**
     * @return array{reminders: int, leadersNeeded: int} notifications written
     */
    public function run(?Carbon $now = null): array
    {
        $now = $now ? $now->copy() : Carbon::now();
        $stats = ['reminders' => 0, 'leadersNeeded' => 0];

        foreach (Club::all() as $club) {
            $tz = $this->notifier->tz($club);
            $sessions = ClubSession::where('club_id', $club->id)
                ->where('status', ClubSession::STATUS_SCHEDULED)
                ->where('starts_at', '>', $now->copy()->utc())
                ->where('starts_at', '<=', $now->copy()->utc()->addHours(self::LEADERS_WINDOW_HOURS))
                ->orderBy('starts_at')->get();

            foreach ($sessions as $session) {
                $this->notifier->guard('reminder ' . $session->id, function () use ($club, $session, $now, $tz, &$stats) {
                    if ($this->reminderIsDue($session, $now, $tz)) {
                        $stats['reminders'] += $this->remind($club, $session, $now, $tz);
                    }

                    if ($this->leadersCheckIsOpen($now, $tz)) {
                        $stats['leadersNeeded'] += $this->alertLeaders($club, $session, $tz);
                    }
                });
            }
        }

        return $stats;
    }

    // ---- timing ----------------------------------------------------------------------------

    /** The club-local moment a run's reminder becomes due. */
    public function reminderTime(ClubSession $session, string $tz): Carbon
    {
        $start = $session->starts_at->copy()->setTimezone($tz);

        return $start->hour >= self::LATE_START_HOUR
            ? $start->copy()->setTime(self::MORNING_HOUR, 0)
            : $start->copy()->subDay()->setTime(self::EVENING_HOUR, 0);
    }

    private function reminderIsDue(ClubSession $session, Carbon $now, string $tz): bool
    {
        return $now->gte($this->reminderTime($session, $tz)) && $now->lt($session->starts_at);
    }

    private function leadersCheckIsOpen(Carbon $now, string $tz): bool
    {
        return $now->copy()->setTimezone($tz)->hour >= self::LEADERS_AFTER_HOUR;
    }

    // ---- reminders -------------------------------------------------------------------------

    /** @return int reminders written */
    private function remind(Club $club, ClubSession $session, Carbon $now, string $tz): int
    {
        $key = 'reminder:' . $session->id;
        $answers = SessionAttendee::where('session_id', $session->id)->get()->keyBy('member_id');
        $groups = SessionGroup::where('session_id', $session->id)->get()->keyBy('id');

        // member id => groups they confirmed as leader of on this run
        $leading = [];
        foreach (SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)->whereIn('group_id', $groups->keys())->get() as $row) {
            $leading[$row->member_id][] = $groups->get($row->group_id);
        }

        $audience = array_merge(
            $answers->filter(function ($a) {
                return in_array($a->status, [SessionAttendee::GOING, SessionAttendee::MAYBE], true);
            })->keys()->all(),
            array_keys($leading),
            $this->seriesAudience($session, $now)
        );

        $notGoing = $answers->filter(function ($a) {
            return $a->status === SessionAttendee::NOT_GOING;
        })->keys()->all();

        $already = Notification::where('club_id', $club->id)->where('dedupe_key', $key)->pluck('member_id')->all();
        $ids = $this->notifier->activeIds($club, array_diff(array_unique($audience), $notGoing, $already));

        if (!$ids) {
            return 0;
        }

        $units = $this->notifier->unitsFor($club, $ids);
        $when = $session->starts_at->copy()->setTimezone($tz);
        $title = ($when->isSameDay($now->copy()->setTimezone($tz)) ? 'Today' : 'Tomorrow')
            . ' at ' . $when->format('H:i') . ': ' . $session->title;
        $written = 0;

        foreach ($ids as $id) {
            $unit = $units[$id];
            $data = RunText::data($session);

            if (isset($leading[$id])) {
                $names = array_map(function (SessionGroup $g) use ($unit) {
                    return RunText::groupName($g, $unit) ?: 'a group';
                }, $leading[$id]);
                $body = "You're leading " . implode(' and ', array_unique($names)) . '.';
            } else {
                $answer = $answers->get($id);
                $group = $answer && $answer->group_id ? $groups->get($answer->group_id) : null;
                $name = $group ? RunText::groupName($group, $unit) : null;

                if ($answer && $answer->status === SessionAttendee::GOING) {
                    $body = ($name ? "You're down for the $name group" : "You're down for this run") . ". Can't make it?";
                } elseif ($answer && $answer->status === SessionAttendee::MAYBE) {
                    $body = 'You said maybe. Are you coming?';
                } else {
                    $body = 'Are you coming?';
                }

                $data['actions'] = ['going', 'not_going'];
                $data['actionToken'] = NotificationService::newActionToken();
            }

            $written += count(app(NotificationService::class)->notifyMembers(
                $club,
                [$id],
                NotificationCategories::RUN_REMINDERS,
                $title,
                RunText::clip($body),
                $data,
                false,
                ['dedupeKey' => $key, 'onDuplicate' => 'skip']
            ));
        }

        return $written;
    }

    /**
     * Members the series rule adds on top of the people who answered (D35): `on` always,
     * `off` never, otherwise (auto) anyone who was going at one of the last runs of the series.
     * A run with no series adds nobody.
     *
     * @return string[]
     */
    private function seriesAudience(ClubSession $session, Carbon $now): array
    {
        if (!$session->series_id) {
            return [];
        }

        $prefs = MemberSeriesPref::where('club_id', $session->club_id)->where('series_id', $session->series_id)
            ->pluck('reminders', 'member_id')->all();

        $recent = ClubSession::where('series_id', $session->series_id)
            ->where('id', '!=', $session->id)
            ->where('status', ClubSession::STATUS_SCHEDULED)
            ->where('ends_at', '<', $now->copy()->utc())
            ->orderByDesc('starts_at')
            ->limit(self::AUTO_HISTORY)
            ->pluck('id');

        $auto = $recent->isEmpty() ? [] : SessionAttendee::whereIn('session_id', $recent)
            ->where('status', SessionAttendee::GOING)->pluck('member_id')->unique()->all();

        $ids = [];
        foreach ($auto as $id) {
            if (($prefs[$id] ?? MemberSeriesPref::AUTO) !== MemberSeriesPref::OFF) {
                $ids[] = $id;
            }
        }

        foreach ($prefs as $id => $value) {
            if ($value === MemberSeriesPref::ON) {
                $ids[] = $id;
            }
        }

        return $ids;
    }

    // ---- leaders needed --------------------------------------------------------------------

    /** @return int notifications written */
    private function alertLeaders(Club $club, ClubSession $session, string $tz): int
    {
        if ($session->group_mode === 'routes') {
            return 0;
        }

        $reason = $this->leadersNeededReason($session);

        if ($reason === null) {
            return 0;
        }

        $ids = $this->notifier->availableLeaders($club, $session, []);

        // One message per member per run: skip anyone already asked about one of its groups.
        $groupKeys = SessionGroup::withTrashed()->where('session_id', $session->id)->pluck('id')
            ->map(function ($id) {
                return 'leaders_needed_group:' . $id;
            })->all();

        if ($ids && $groupKeys) {
            $asked = Notification::where('club_id', $club->id)->whereIn('dedupe_key', $groupKeys)->pluck('member_id')->all();
            $ids = array_values(array_diff($ids, $asked));
        }

        if (!$ids) {
            return 0;
        }

        $day = RunText::day($session->starts_at, $tz);
        $time = RunText::time($session->starts_at, $tz);
        $body = [
            'needs_leader' => "{$session->title} on $day at $time has a group with no leader. Can you lead it?",
            'uncovered' => "Some runners going to {$session->title} on $day at $time have no leader at their pace. Can you lead?",
            'no_leader' => "{$session->title} on $day at $time has people going but nobody leading yet. Can you lead?",
        ][$reason];

        return count(app(NotificationService::class)->notifyMembers(
            $club,
            $ids,
            NotificationCategories::LEADERS_NEEDED,
            "Leaders needed: $day",
            RunText::clip($body),
            RunText::data($session),
            false,
            ['dedupeKey' => 'leaders_needed_run:' . $session->id, 'onDuplicate' => 'skip']
        ));
    }

    /**
     * Why the run needs leaders, or null when it doesn't (D28 on the server): a group marked
     * needs_leader; going members whose pace no led group covers; or going members and no
     * led group at all.
     */
    private function leadersNeededReason(ClubSession $session): ?string
    {
        $groups = SessionGroup::where('session_id', $session->id)->get();

        if ($groups->contains('status', SessionGroup::STATUS_NEEDS_LEADER)) {
            return 'needs_leader';
        }

        $ledIds = SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
            ->whereIn('group_id', $groups->pluck('id'))->pluck('group_id')->unique()->all();
        $going = SessionAttendee::where('session_id', $session->id)->where('status', SessionAttendee::GOING)->get();

        if (!$going->count()) {
            return null;
        }

        if (!$ledIds) {
            return 'no_leader';
        }

        $bands = [];
        foreach ($groups->whereIn('id', $ledIds) as $group) {
            if ($band = PaceMatcher::groupBand($group)) {
                $bands[] = $band;
            }
        }

        $prefs = MemberPreference::where('club_id', $session->club_id)->whereIn('member_id', $going->pluck('member_id'))->get()->keyBy('member_id');

        foreach ($going as $answer) {
            $mine = PaceMatcher::memberBand($answer, $prefs->get($answer->member_id));

            if ($mine === null) {
                continue;
            }

            $covered = false;
            foreach ($bands as $band) {
                if (PaceMatcher::overlaps($mine, $band)) {
                    $covered = true;
                    break;
                }
            }

            if (!$covered) {
                return 'uncovered';
            }
        }

        return null;
    }
}
