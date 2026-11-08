<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadMember;
use App\Models\LeaderThreadState;
use App\Models\Notification;
use App\Models\SessionAttendee;
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
     * Sends an ask. An ask that names its people (D127, `ask_member_ids`) goes to exactly those
     * people, minus anyone who can't be asked (leading, not going, asked in the last day, no longer
     * active), and the message is rewritten to hold who it really went to; any other ask goes to the
     * members who may lead that pace (RunNotifier::availableLeaders).
     *
     * @return array{sent: int, skipped: array<int, array{memberId: string, reason: string}>} sent is
     *         how many members got the "leaders needed" push, zero when nobody could be asked
     */
    public function ask(Club $club, LeaderThreadAccess $thread, LeaderMessage $message): array
    {
        $notifier = app(RunNotifier::class);
        $sent = 0;
        $skipped = [];

        $notifier->guard('leader ask', function () use ($club, $thread, $message, $notifier, &$sent, &$skipped) {
            $session = $thread->session;

            if ($message->isTargeted()) {
                [$recipients, $skipped] = $this->targets($club, $thread, $message);
                $message->ask_member_ids = $recipients;
                $message->save();
            } else {
                $recipients = $notifier->availableLeaders($club, $session, [$message->member_id], null, $this->band($message));
            }

            $sent = count($recipients);

            foreach ($recipients as $id) {
                $row = LeaderThreadMember::firstOrCreate(
                    ['session_id' => $session->id, 'member_id' => $id],
                    ['club_id' => $club->id]
                );

                if (!$row->wasRecentlyCreated) {
                    $row->touch(); // "asked in the last day" reads this
                }
            }

            $tz = $notifier->tz($club);
            $day = RunText::day($session->starts_at, $tz);
            $time = RunText::time($session->starts_at, $tz);
            $note = trim((string) $message->body);
            $targeted = $message->isTargeted();

            $notifier->notifyByUnit(
                $club,
                $recipients,
                NotificationCategories::LEADERS_NEEDED,
                $this->data($session),
                ['dedupeKey' => 'leader_ask:' . $message->id, 'onDuplicate' => 'skip'],
                function (?string $unit) use ($message, $day, $time, $note, $targeted) {
                    $pace = LeaderThreadAccess::phrase($message, (string) $unit);
                    $lead = ($targeted ? 'Committee asked you: can you lead' : 'Can you lead') . ($pace !== '' ? " $pace" : '');
                    $body = $lead . " at $time on $day?" . ($note !== '' ? " $note" : '');

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

        return ['sent' => $sent, 'skipped' => $skipped];
    }

    /**
     * Who a targeted ask really goes to, and who was left out and why. The asker is left out silently.
     *
     * @return array{0: string[], 1: array<int, array{memberId: string, reason: string}>}
     */
    private function targets(Club $club, LeaderThreadAccess $thread, LeaderMessage $message): array
    {
        $wanted = array_values(array_unique($message->ask_member_ids ?? []));
        $active = array_flip(app(RunNotifier::class)->activeIds($club, $wanted, $message->member_id));
        $leading = array_flip($thread->leaderIds());
        $notGoing = array_flip(
            SessionAttendee::where('session_id', $thread->session->id)->where('status', SessionAttendee::NOT_GOING)
                ->whereIn('member_id', $wanted)->pluck('member_id')->all()
        );
        $recent = array_flip(
            LeaderThreadMember::where('session_id', $thread->session->id)->whereIn('member_id', $wanted)
                ->where('updated_at', '>', Carbon::now()->subHours(LeaderPool::ASKED_RECENTLY_HOURS))
                ->pluck('member_id')->all()
        );

        $recipients = [];
        $skipped = [];

        foreach ($wanted as $id) {
            if ($id === $message->member_id) {
                continue;
            }

            $reason = isset($leading[$id]) ? 'leading'
                : (isset($notGoing[$id]) ? 'not_going'
                : (isset($recent[$id]) ? 'asked_recently'
                : (!isset($active[$id]) ? 'inactive' : null)));

            if ($reason === null) {
                $recipients[] = $id;
            } else {
                $skipped[] = ['memberId' => $id, 'reason' => $reason];
            }
        }

        return [$recipients, $skipped];
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
                // A targeted ask repeats to the people it named; an older one to everyone asked about the run.
                $asked = $ask->isTargeted()
                    ? $ask->ask_member_ids
                    : LeaderThreadMember::where('session_id', $session->id)->pluck('member_id')->all();
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
                        $pace = LeaderThreadAccess::phrase($ask, (string) $unit);

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
        $jogWalk = $ask->ask_kind === LeaderMessage::ASK_JOG_WALK;
        $groups = SessionGroup::where('session_id', $session->id)->get();
        $ledIds = SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
            ->whereIn('group_id', $groups->pluck('id'))->pluck('group_id')->unique()->all();

        foreach ($groups->whereIn('id', $ledIds) as $group) {
            if ($jogWalk) {
                if ($group->kind === 'jog_walk') {
                    return true;
                }

                continue;
            }

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
