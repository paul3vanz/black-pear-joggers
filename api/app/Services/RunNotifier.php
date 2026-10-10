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
            if (!$this->isOpen($session)) {
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

    // ---- shared helpers -----------------------------------------------------------

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
