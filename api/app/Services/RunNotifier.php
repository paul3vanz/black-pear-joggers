<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\MemberPreference;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Notifications that happen because someone changed something (Phase 5b, D31):
 * a run is cancelled, restored or moved, a leader withdraws, a group is removed
 * or a pace group is added. Everything goes through NotificationService, to
 * ACTIVE club members only, and never to the member who did it.
 *
 * The public trigger methods are safe to call from a request: they swallow and
 * log any failure, so a notification problem can never fail the original write.
 * Time-driven alerts (reminders, leaders needed) live in RunReminderService.
 */
class RunNotifier
{
    const CHANGES = NotificationCategories::MY_GROUP_CHANGES;

    /** Seconds the group-match job waits, so a leader can fix a typo first. */
    const GROUP_MATCH_DELAY = 180;

    // ---- triggers (never throw) ---------------------------------------------------

    /**
     * A run was cancelled, restored or had its time or venue changed.
     *
     * @param string      $kind    cancelled | restored | changed
     * @param array       $before  for "changed": starts_at (Carbon) and venue_id before the edit
     * @param string|null $actorId club_members.id of who made the change
     */
    public function sessionChanged(ClubSession $session, string $kind, ?string $actorId = null, array $before = []): void
    {
        $this->guard('session change', function () use ($session, $kind, $actorId, $before) {
            // Only runs still to happen; a move of a cancelled run is nobody's news.
            if ($session->trashed() || $session->hasEnded() || ($kind === 'changed' && $session->isCancelled())) {
                return;
            }

            $club = Club::find($session->club_id);
            $ids = $this->activeIds($club, $this->sessionAudience($session), $actorId);

            if (!$ids) {
                return;
            }

            $tz = $this->tz($club);
            [$title, $body] = $this->sessionChangeText($session, $kind, $tz, $before);

            app(NotificationService::class)->notifyMembers(
                $club,
                $ids,
                self::CHANGES,
                $title,
                $body,
                RunText::data($session),
                false,
                ['dedupeKey' => 'session_change:' . $session->id, 'onDuplicate' => 'replace']
            );
        });
    }

    /**
     * The last leader of a group stepped down, so it needs one (D36). Its attendees get a
     * locked notice; `leader`-role members whose pace fits get "leaders needed".
     */
    public function leaderWithdrawn(SessionGroup $group, ?string $actorId = null): void
    {
        $this->guard('leader withdrawn', function () use ($group, $actorId) {
            $session = $group->session;

            if (!$session || !$this->isOpen($session)) {
                return;
            }

            $club = Club::find($group->club_id);
            $tz = $this->tz($club);
            $day = RunText::day($session->starts_at, $tz);
            $time = RunText::time($session->starts_at, $tz);
            $data = RunText::data($session, $group->id);

            $attendees = $this->activeIds($club, SessionAttendee::where('group_id', $group->id)
                ->whereIn('status', [SessionAttendee::GOING, SessionAttendee::MAYBE])->pluck('member_id')->all(), $actorId);

            $this->notifyByUnit($club, $attendees, self::CHANGES, $data, [
                'dedupeKey' => 'leader_withdrawn:' . $group->id, 'onDuplicate' => 'replace',
            ], function (?string $unit) use ($group, $day) {
                $name = RunText::groupName($group, $unit) ?: 'your group';

                return ['Your group needs a leader', RunText::clip("The leader of $name on $day has stepped down. Open the run to help find a new one.")];
            });

            $candidates = $this->availableLeaders($club, $session, array_merge($attendees, [$actorId]), $group);

            $this->notifyByUnit($club, $candidates, NotificationCategories::LEADERS_NEEDED, $data, [
                'dedupeKey' => 'leaders_needed_group:' . $group->id, 'onDuplicate' => 'skip',
            ], function (?string $unit) use ($group, $day, $time) {
                $name = RunText::groupName($group, $unit);

                return [
                    'Leader needed: ' . ($name ?: $day),
                    RunText::clip(($name ?: 'A group') . " at $time on $day has no leader. Can you lead it?"),
                ];
            });
        });
    }

    /**
     * A group was deleted; $attendeeIds are the people who were signed up to it, read before
     * the delete turned them into unassigned runners.
     */
    public function groupRemoved(SessionGroup $group, array $attendeeIds, ?string $actorId = null): void
    {
        $this->guard('group removed', function () use ($group, $attendeeIds, $actorId) {
            $session = ClubSession::find($group->session_id);

            if (!$session || !$this->isOpen($session)) {
                return;
            }

            $club = Club::find($group->club_id);
            $day = RunText::day($session->starts_at, $this->tz($club));

            $this->notifyByUnit($club, $this->activeIds($club, $attendeeIds, $actorId), self::CHANGES, RunText::data($session, $group->id), [
                'dedupeKey' => 'group_removed:' . $group->id, 'onDuplicate' => 'replace',
            ], function (?string $unit) use ($group, $day) {
                $name = RunText::groupName($group, $unit) ?: 'Your group';

                return ['Group removed', RunText::clip("$name on $day was removed. You're still down for the run: open it to pick another group.")];
            });
        });
    }

    /** Queues the 3 minute delayed "matching group" check for a group (never throws). */
    public function queueGroupMatch(SessionGroup $group, ?string $actorId = null): void
    {
        $this->guard('group match queue', function () use ($group, $actorId) {
            dispatch((new \App\Jobs\NotifyMatchingGroupJob($group->id, $actorId))->delay(self::GROUP_MATCH_DELAY));
        });
    }

    /**
     * Tells members whose pace fits a newly added or re-paced group (runs from the delayed job
     * and re-checks everything, so a deleted or fixed group sends nothing).
     *
     * @return int how many members were notified
     */
    public function matchGroup(string $groupId, ?string $actorId = null): int
    {
        $group = SessionGroup::find($groupId);
        $session = $group ? $group->session : null;

        if (!$group || !$session || !$this->isOpen($session) || PaceMatcher::groupBand($group) === null) {
            return 0;
        }

        $club = Club::find($group->club_id);
        $attendees = SessionAttendee::where('session_id', $session->id)->get()->keyBy('member_id');
        $groups = SessionGroup::where('session_id', $session->id)->get()->keyBy('id');
        $prefs = MemberPreference::where('club_id', $club->id)->get()->keyBy('member_id');
        $leaders = SessionGroupLeader::where('group_id', $group->id)->where('status', SessionGroupLeader::CONFIRMED)->pluck('member_id')->all();

        $ids = [];
        foreach ($this->activeIds($club, ClubMember::where('club_id', $club->id)->pluck('id'), $actorId) as $id) {
            $answer = $attendees->get($id);
            $pref = $prefs->get($id);

            if (in_array($id, $leaders, true)
                || ($answer && $answer->status === SessionAttendee::NOT_GOING)
                || ($answer && $answer->group_id === $group->id)
                || !PaceMatcher::memberFitsGroup($answer, $pref, $group)) {
                continue;
            }

            $current = $answer && $answer->group_id ? $groups->get($answer->group_id) : null;

            if ($current && PaceMatcher::memberFitsGroup($answer, $pref, $current)) {
                continue; // already in a group that suits them
            }

            $ids[] = $id;
        }

        $tz = $this->tz($club);
        $day = RunText::day($session->starts_at, $tz);
        $time = RunText::time($session->starts_at, $tz);

        return $this->notifyByUnit($club, $ids, NotificationCategories::GROUP_MATCHES, RunText::data($session, $group->id), [
            'dedupeKey' => 'group_match:' . $session->id, 'onDuplicate' => 'skip',
        ], function (?string $unit) use ($group, $session, $day, $time) {
            $name = RunText::groupName($group, $unit) ?: 'pace group';

            return [
                "New group: $name",
                RunText::clip("{$session->title} on $day at $time has a new group at your pace. Want to join it?"),
            ];
        });
    }

    // ---- shared helpers -----------------------------------------------------------

    /**
     * Sends one message per pace unit (so pace text reads in the recipient's units).
     *
     * @param string[]                    $ids
     * @param callable(string): array     $text unit => [title, body]
     * @return int rows written
     */
    public function notifyByUnit(Club $club, array $ids, string $category, array $data, array $options, callable $text): int
    {
        if (!$ids) {
            return 0;
        }

        $byUnit = [];
        foreach ($this->unitsFor($club, $ids) as $id => $unit) {
            $byUnit[$unit][] = $id;
        }

        $written = 0;
        foreach ($byUnit as $unit => $members) {
            [$title, $body] = $text($unit);
            $written += count(app(NotificationService::class)->notifyMembers($club, $members, $category, $title, $body, $data, false, $options));
        }

        return $written;
    }

    /**
     * `leader`-role active members who could lead $group (or any needy group in the run): not
     * leading anything in the run, not "not going", and whose pace fits the group's (or who
     * have no pace, or whose group has none).
     *
     * @param array<int, string|null> $exclude member ids to leave out
     * @return string[]
     */
    public function availableLeaders(Club $club, ClubSession $session, array $exclude, ?SessionGroup $group = null): array
    {
        $leading = SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
            ->whereIn('group_id', SessionGroup::where('session_id', $session->id)->pluck('id'))
            ->pluck('member_id')->all();
        $answers = SessionAttendee::where('session_id', $session->id)->get()->keyBy('member_id');
        $prefs = MemberPreference::where('club_id', $club->id)->get()->keyBy('member_id');
        $groupBand = $group ? PaceMatcher::groupBand($group) : null;

        $ids = [];
        foreach (ClubMember::where('club_id', $club->id)->where('status', 'active')->get() as $member) {
            $answer = $answers->get($member->id);

            if (!$member->hasRole('leader')
                || in_array($member->id, $exclude, true)
                || in_array($member->id, $leading, true)
                || ($answer && $answer->status === SessionAttendee::NOT_GOING)) {
                continue;
            }

            $band = PaceMatcher::memberBand($answer, $prefs->get($member->id));

            if ($groupBand !== null && $band !== null && !PaceMatcher::overlaps($band, $groupBand)) {
                continue;
            }

            $ids[] = $member->id;
        }

        return $ids;
    }

    /** Runs $fn; a failure is logged and swallowed. */
    public function guard(string $what, callable $fn): void
    {
        try {
            $fn();
        } catch (\Throwable $e) {
            try {
                Log::warning('Run notification failed (' . $what . '): ' . $e->getMessage());
            } catch (\Throwable $ignored) {
                // Logging must not fail the request either.
            }
        }
    }

    public function tz(Club $club): string
    {
        return $club->timezone ?: 'Europe/London';
    }

    /** True for a scheduled run that has not finished yet. */
    public function isOpen(ClubSession $session): bool
    {
        return !$session->trashed() && !$session->isCancelled() && !$session->hasEnded();
    }

    /**
     * Active members of the club among $ids, minus the actor.
     *
     * @return string[]
     */
    public function activeIds(Club $club, iterable $ids, ?string $actorId = null): array
    {
        $wanted = [];
        foreach ($ids as $id) {
            if ($id !== null && $id !== $actorId) {
                $wanted[$id] = $id;
            }
        }

        if (!$wanted) {
            return [];
        }

        return ClubMember::where('club_id', $club->id)
            ->where('status', 'active')
            ->whereIn('id', array_values($wanted))
            ->pluck('id')
            ->all();
    }

    /**
     * member id => pace unit ('mi' | 'km') to speak to them in.
     *
     * @param string[] $ids
     * @return array<string, string>
     */
    public function unitsFor(Club $club, array $ids): array
    {
        $saved = MemberPreference::where('club_id', $club->id)->whereIn('member_id', $ids)->pluck('pace_unit', 'member_id');
        $units = [];

        foreach ($ids as $id) {
            $units[$id] = $saved->get($id) === 'km' ? 'km' : 'mi';
        }

        return $units;
    }

    /** Going or maybe attendees, confirmed leaders of live groups, and the coordinator. */
    private function sessionAudience(ClubSession $session): array
    {
        $ids = SessionAttendee::where('session_id', $session->id)
            ->whereIn('status', [SessionAttendee::GOING, SessionAttendee::MAYBE])
            ->pluck('member_id')->all();

        $leaders = SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
            ->whereIn('group_id', SessionGroup::where('session_id', $session->id)->pluck('id'))
            ->pluck('member_id')->all();

        return array_merge($ids, $leaders, $session->coordinator_member_id ? [$session->coordinator_member_id] : []);
    }

    /** @return array{0: string, 1: string} title and body */
    private function sessionChangeText(ClubSession $session, string $kind, string $tz, array $before): array
    {
        $day = RunText::day($session->starts_at, $tz);
        $time = RunText::time($session->starts_at, $tz);
        $venue = RunText::venueName($session->venue_id);
        $at = $venue ? " at $venue" : '';

        if ($kind === 'cancelled') {
            $body = "{$session->title} at $time has been cancelled.";

            if ($session->cancel_reason) {
                $body .= ' ' . trim($session->cancel_reason);
            }

            return ["Run cancelled: $day", RunText::clip($body)];
        }

        if ($kind === 'restored') {
            return ["Run back on: $day", RunText::clip("{$session->title} is on after all: $time$at.")];
        }

        $oldStart = $before['starts_at'] ?? null;
        $dateMoved = $oldStart && RunText::local($oldStart, $tz)->format('Y-m-d') !== RunText::local($session->starts_at, $tz)->format('Y-m-d');
        $now = ($dateMoved ? RunText::local($session->starts_at, $tz)->format('D j M') . ' ' : '') . $time . $at;

        $was = '';
        if ($oldStart) {
            $oldVenue = RunText::venueName($before['venue_id'] ?? null);
            $was = ' Was ' . ($dateMoved ? RunText::local($oldStart, $tz)->format('D j M') . ' ' : '')
                . RunText::time($oldStart, $tz) . ($oldVenue ? " at $oldVenue" : '') . '.';
        }

        $lead = $dateMoved ? "{$session->title} is now" : "{$session->title} on $day is now";

        return ["Run moved: now $now", RunText::clip("$lead $now.$was")];
    }
}
