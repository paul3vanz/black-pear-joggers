<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadMember;
use App\Models\LeaderThreadState;
use App\Models\Notification;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;

/**
 * Tells people about the leaders thread of a run (D125).
 *
 *  - a plain message goes to the thread's participants (committee, the run's
 *    leaders, people asked), minus the author and anyone who muted it: one inbox
 *    row per member per run (`leader_msg:<sessionId>`, replaced by the latest) and
 *    at most one push per 5 minutes;
 *  - an ask goes to the members who may lead that run at that pace
 *    (RunNotifier::availableLeaders, the same audience as "leaders needed"), who
 *    are added to the thread so they can answer; the rest of the thread hears it
 *    like a message;
 *  - an ask nobody has covered after a day is repeated once, to the people asked
 *    who haven't answered.
 *
 * Safe to call from a request: failures are logged and swallowed.
 */
class LeaderThreadNotifier
{
    /** Minutes between pushes for the same thread. */
    const REPUSH_MINUTES = 5;

    /** Hours before an unanswered ask is repeated (once). */
    const RENUDGE_AFTER_HOURS = 24;

    /** Local hours (inclusive start, exclusive end) in which a repeat may be sent. */
    const RENUDGE_FROM_HOUR = 8;
    const RENUDGE_TO_HOUR = 21;

    /** Don't repeat an ask for a run starting within this many hours. */
    const RENUDGE_MIN_HOURS_AHEAD = 2;

    public function newMessage(Club $club, LeaderThreadAccess $thread, LeaderMessage $message): void
    {
        $notifier = app(RunNotifier::class);

        $notifier->guard('leader thread message', function () use ($club, $thread, $message, $notifier) {
            $ids = $this->audience($club, $thread, $message->member_id, []);

            if (!$ids) {
                return;
            }

            $author = $thread->people([$message->member_id])[$message->member_id]['name'];
            $session = $thread->session;

            $notifier->notifyByUnit(
                $club,
                $ids,
                NotificationCategories::GROUP_MESSAGES,
                $this->data($session),
                ['dedupeKey' => 'leader_msg:' . $session->id, 'onDuplicate' => 'replace', 'repush' => self::REPUSH_MINUTES],
                function (?string $unit) use ($author, $session, $message) {
                    return [$author . ' · Leaders, ' . $session->title, RunText::clip(LeaderThreadAccess::preview($message, (string) $unit))];
                }
            );
        });
    }

    /**
     * Sends an ask. Returns how many members it was sent to as an ask ("leaders
     * needed" push), which is zero when nobody may lead at that pace.
     */
    public function ask(Club $club, LeaderThreadAccess $thread, LeaderMessage $message): int
    {
        $notifier = app(RunNotifier::class);
        $sent = 0;

        $notifier->guard('leader ask', function () use ($club, $thread, $message, $notifier, &$sent) {
            $session = $thread->session;
            $band = $this->band($message);
            $recipients = $notifier->availableLeaders($club, $session, [$message->member_id], null, $band);
            $sent = count($recipients);

            foreach ($recipients as $id) {
                LeaderThreadMember::firstOrCreate(
                    ['session_id' => $session->id, 'member_id' => $id],
                    ['club_id' => $club->id]
                );
            }

            $tz = $notifier->tz($club);
            $day = RunText::day($session->starts_at, $tz);
            $time = RunText::time($session->starts_at, $tz);
            $note = trim((string) $message->body);

            $notifier->notifyByUnit(
                $club,
                $recipients,
                NotificationCategories::LEADERS_NEEDED,
                $this->data($session),
                ['dedupeKey' => 'leader_ask:' . $message->id, 'onDuplicate' => 'skip'],
                function (?string $unit) use ($message, $day, $time, $note) {
                    $pace = LeaderThreadAccess::paceText($message, (string) $unit);
                    $body = 'Can you lead' . ($pace !== '' ? " $pace" : '') . " at $time on $day?" . ($note !== '' ? " $note" : '');

                    return ["Can you lead on $day?", RunText::clip($body)];
                }
            );

            // The rest of the thread (committee, the run's leaders) hear it as a message.
            $others = $this->audience($club, $thread, $message->member_id, $recipients);
            $notifier->notifyByUnit(
                $club,
                $others,
                NotificationCategories::GROUP_MESSAGES,
                $this->data($session),
                ['dedupeKey' => 'leader_msg:' . $session->id, 'onDuplicate' => 'replace', 'repush' => self::REPUSH_MINUTES],
                function (?string $unit) use ($thread, $message, $session) {
                    $author = $thread->people([$message->member_id])[$message->member_id]['name'];

                    return [$author . ' · Leaders, ' . $session->title, RunText::clip(LeaderThreadAccess::preview($message, (string) $unit))];
                }
            );
        });

        return $sent;
    }

    /**
     * Repeats asks that are a day old and still not covered, once. Called by
     * `app:send-reminders` with an injectable "now".
     *
     * @return int notifications written
     */
    public function renudge(Carbon $now): int
    {
        $notifier = app(RunNotifier::class);
        $written = 0;

        $asks = LeaderMessage::where('kind', LeaderMessage::KIND_ASK)
            ->whereNull('renudged_at')
            ->where('created_at', '<=', $now->copy()->subHours(self::RENUDGE_AFTER_HOURS))
            ->get();

        foreach ($asks as $ask) {
            $notifier->guard('leader ask repeat ' . $ask->id, function () use ($ask, $now, $notifier, &$written) {
                $session = ClubSession::find($ask->session_id);
                $club = $session ? Club::find($session->club_id) : null;

                if (!$session || !$club) {
                    $ask->renudged_at = $now;
                    $ask->save();

                    return;
                }

                $tz = $notifier->tz($club);
                $local = RunText::local($now, $tz);

                // Too late to be useful: the run is on or about to start, or has gone.
                if (!$notifier->isOpen($session) || $session->starts_at->lte($now->copy()->addHours(self::RENUDGE_MIN_HOURS_AHEAD))) {
                    $ask->renudged_at = $now;
                    $ask->save();

                    return;
                }

                // Wait for a sensible hour rather than skipping the repeat.
                if ($local->hour < self::RENUDGE_FROM_HOUR || $local->hour >= self::RENUDGE_TO_HOUR) {
                    return;
                }

                $ask->renudged_at = $now;
                $ask->save();

                if ($this->isCovered($session, $ask)) {
                    return;
                }

                $answered = LeaderMessage::where('session_id', $session->id)
                    ->where('created_at', '>=', $ask->created_at)
                    ->where('kind', LeaderMessage::KIND_MESSAGE)
                    ->pluck('member_id')->all();
                $leading = SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
                    ->whereIn('group_id', SessionGroup::where('session_id', $session->id)->pluck('id'))
                    ->pluck('member_id')->all();
                $asked = LeaderThreadMember::where('session_id', $session->id)->pluck('member_id')->all();
                $ids = $notifier->activeIds($club, array_diff($asked, $answered, $leading), $ask->member_id);
                $day = RunText::day($session->starts_at, $tz);
                $time = RunText::time($session->starts_at, $tz);

                $written += $notifier->notifyByUnit(
                    $club,
                    $ids,
                    NotificationCategories::LEADERS_NEEDED,
                    $this->data($session),
                    ['dedupeKey' => 'leader_ask_repeat:' . $ask->id, 'onDuplicate' => 'skip'],
                    function (?string $unit) use ($ask, $day, $time) {
                        $pace = LeaderThreadAccess::paceText($ask, (string) $unit);

                        return ["Still need a leader on $day", RunText::clip('Can you lead' . ($pace !== '' ? " $pace" : '') . " at $time on $day? Nobody has stepped up yet.")];
                    }
                );
            });
        }

        return $written;
    }

    /** True when a confirmed leader's group already covers the ask's pace (no pace: any led group). */
    public function isCovered(ClubSession $session, LeaderMessage $ask): bool
    {
        $band = $this->band($ask);
        $groups = SessionGroup::where('session_id', $session->id)->get();
        $ledIds = SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
            ->whereIn('group_id', $groups->pluck('id'))->pluck('group_id')->unique()->all();

        foreach ($groups->whereIn('id', $ledIds) as $group) {
            if ($band === null || PaceMatcher::overlaps(PaceMatcher::groupBand($group), $band)) {
                return true;
            }
        }

        return false;
    }

    /** The ask's [fast, slow] band in s/km, or null for an ask with no pace. */
    private function band(LeaderMessage $message): ?array
    {
        if ($message->ask_fast_s_per_km === null) {
            return null;
        }

        $fast = (float) $message->ask_fast_s_per_km;
        $slow = $message->ask_slow_s_per_km === null ? $fast : (float) $message->ask_slow_s_per_km;

        return [min($fast, $slow), max($fast, $slow)];
    }

    /**
     * Participants of the thread to notify: not the author, not muted, active, and not in $exclude.
     *
     * @param string[] $exclude
     * @return string[]
     */
    private function audience(Club $club, LeaderThreadAccess $thread, string $authorId, array $exclude): array
    {
        $muted = LeaderThreadState::where('session_id', $thread->session->id)->where('muted', true)->pluck('member_id')->all();
        $ids = array_values(array_diff($thread->participantIds(), $muted, $exclude));

        return app(RunNotifier::class)->activeIds($club, $ids, $authorId);
    }

    /** The data block of a leaders-thread notification. */
    public function data(ClubSession $session): array
    {
        return [
            'route' => '/runs/' . $session->id . '/leaders-chat',
            'sessionId' => $session->id,
            'groupId' => LeaderThreadAccess::threadId($session),
        ];
    }

    /** Marks a member's inbox rows for this thread read. */
    public function markInboxRead(string $memberId, ClubSession $session, Carbon $now): void
    {
        $keys = array_merge(
            ['leader_msg:' . $session->id],
            LeaderMessage::withTrashed()->where('session_id', $session->id)->where('kind', LeaderMessage::KIND_ASK)
                ->pluck('id')->flatMap(fn ($id) => ['leader_ask:' . $id, 'leader_ask_repeat:' . $id])->all()
        );

        Notification::where('member_id', $memberId)
            ->whereIn('dedupe_key', $keys)
            ->whereNull('read_at')
            ->update(['read_at' => $now, 'updated_at' => $now]);
    }
}
