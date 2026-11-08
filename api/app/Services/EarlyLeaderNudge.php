<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\Notification;
use Illuminate\Support\Carbon;

/**
 * A gentle nudge to likely leaders while there is still time (D128). Runs starting between 72 hours
 * and 7 days from now that still have a hole in their spread of paces (PaceSpread) are offered to
 * the previous leaders whose usual pace fits that hole: at most PER_TARGET new people per hole per
 * day, so it climbs down the list across days instead of asking everyone at once. The last 72 hours
 * belong to the existing "leaders needed" alert (RunReminderService).
 *
 * Holes, in order: the runs's red gaps (or, with no led group at all, the whole target). The amber
 * ends and a missing jog/walk group are only asked about once there is no red gap left.
 *
 * Noise controls: one message per member per run (dedupe key `leaders_early:<sessionId>`), one
 * batch per run per day, one early nudge per member in any rolling 7 days, nobody the committee
 * already asked, and the usual `leaders_needed` opt-out and daily push cap.
 */
class EarlyLeaderNudge
{
    /** The existing alert owns the last 72 hours. */
    const MIN_HOURS_AHEAD = 72;
    const MAX_DAYS_AHEAD = 7;

    /** Club-local hours (inclusive start, exclusive end) in which a nudge may go. */
    const FROM_HOUR = 9;
    const TO_HOUR = 19;

    /** New people asked per hole per day. */
    const PER_TARGET = 2;

    /** A member gets at most one early nudge in this many days. */
    const MEMBER_DAYS = 7;

    const KEY = 'leaders_early:';

    /** @return int notifications written */
    public function run(Carbon $now): int
    {
        $notifier = app(RunNotifier::class);
        $written = 0;

        foreach (Club::all() as $club) {
            $tz = $notifier->tz($club);
            $hour = RunText::local($now, $tz)->hour;

            if ($hour < self::FROM_HOUR || $hour >= self::TO_HOUR) {
                continue;
            }

            $sessions = ClubSession::where('club_id', $club->id)
                ->where('status', ClubSession::STATUS_SCHEDULED)
                ->where('starts_at', '>', $now->copy()->utc()->addHours(self::MIN_HOURS_AHEAD))
                ->where('starts_at', '<=', $now->copy()->utc()->addDays(self::MAX_DAYS_AHEAD))
                ->orderBy('starts_at')->get();

            foreach ($sessions as $session) {
                $notifier->guard('early leaders ' . $session->id, function () use ($club, $session, $now, $tz, &$written) {
                    $written += $this->nudge($club, $session, $now, $tz);
                });
            }
        }

        return $written;
    }

    private function nudge(Club $club, ClubSession $session, Carbon $now, string $tz): int
    {
        if (!PaceSpread::appliesTo($session)) {
            return 0;
        }

        $key = self::KEY . $session->id;
        $dayStart = RunText::local($now, $tz)->startOfDay()->utc();

        // One batch per run per day: the 10-minute job must not ask two more each time it runs.
        if (Notification::where('club_id', $club->id)->where('dedupe_key', $key)->where('created_at', '>=', $dayStart)->exists()) {
            return 0;
        }

        $targets = $this->targets(PaceSpread::forSession($session));

        if (!$targets) {
            return 0;
        }

        $thread = new LeaderThreadAccess($session);
        $already = array_flip(Notification::where('club_id', $club->id)->where('dedupe_key', $key)->pluck('member_id')->all());
        $recent = array_flip(
            Notification::where('club_id', $club->id)->where('dedupe_key', 'like', self::KEY . '%')
                ->where('created_at', '>', $now->copy()->subDays(self::MEMBER_DAYS))->pluck('member_id')->all()
        );

        $chosen = [];

        foreach ($targets as $index => $target) {
            $picked = 0;

            foreach (app(LeaderPool::class)->build($club, $thread, $target['stretch'], $target['jogWalk'], [], $now) as $entry) {
                $id = $entry['memberId'];

                if ($picked >= self::PER_TARGET) {
                    break;
                }

                if (!$entry['fitsRange'] || $entry['leadingThisRun'] || $entry['notGoing'] || $entry['askedAt'] !== null
                    || isset($already[$id]) || isset($recent[$id]) || isset($chosen[$id])) {
                    continue;
                }

                $chosen[$id] = $index;
                $picked++;
            }
        }

        $notifier = app(RunNotifier::class);
        $day = RunText::day($session->starts_at, $tz);
        $time = RunText::time($session->starts_at, $tz);
        $written = 0;

        foreach ($targets as $index => $target) {
            $ids = array_keys(array_filter($chosen, fn ($i) => $i === $index));

            $written += $notifier->notifyByUnit(
                $club,
                $ids,
                NotificationCategories::LEADERS_NEEDED,
                $this->data($session, $target),
                ['dedupeKey' => $key, 'onDuplicate' => 'skip'],
                function (?string $unit) use ($session, $day, $time, $target) {
                    $what = $target['phrase']($unit === 'km' ? 'km' : 'mi');

                    return ["Leaders needed: $day", RunText::clip("{$session->title} on $day at $time $what Can you lead?")];
                }
            );
        }

        return $written;
    }

    /**
     * Where the run has holes, most pressing first.
     *
     * @return array<int, array{stretch: ?array, jogWalk: bool, phrase: callable, ask: array}>
     */
    private function targets(array $spread): array
    {
        $targets = [];

        if ($spread['empty']) {
            return [[
                'stretch' => ['fast' => PaceSpread::km(PaceSpread::TARGET_FAST_PER_MI), 'slow' => PaceSpread::km(PaceSpread::TARGET_SLOW_PER_MI)],
                'jogWalk' => false,
                'phrase' => fn (string $unit) => 'has no leader yet.',
                'ask' => [],
            ]];
        }

        foreach ($spread['gaps'] as $gap) {
            $targets[] = [
                'stretch' => ['fast' => $gap['fast'], 'slow' => $gap['slow']],
                'jogWalk' => false,
                'phrase' => function (string $unit) use ($gap) {
                    [$from, $to] = PaceSpread::window($gap, $unit);

                    return 'needs a group between ' . PaceSpread::clock($from) . ' and ' . PaceSpread::clock($to) . "/$unit.";
                },
                'ask' => ['fast' => (int) round($gap['fast']), 'slow' => (int) round($gap['slow'])],
            ];
        }

        if ($targets) {
            return $targets;
        }

        if ($spread['fasterEnd']) {
            $slow = $spread['fasterEnd']['slow'];
            $targets[] = [
                'stretch' => ['fast' => (float) LeaderMessage::OPEN_FAST, 'slow' => $slow],
                'jogWalk' => false,
                'phrase' => fn (string $unit) => 'could use a group faster than ' . PaceSpread::clock(PaceSpread::edge($slow, $unit)) . "/$unit.",
                'ask' => ['fast' => LeaderMessage::OPEN_FAST, 'slow' => (int) round($slow)],
            ];
        }

        if ($spread['slowerEnd']) {
            $fast = $spread['slowerEnd']['fast'];
            $targets[] = [
                'stretch' => ['fast' => $fast, 'slow' => (float) LeaderMessage::OPEN_SLOW],
                'jogWalk' => false,
                'phrase' => fn (string $unit) => 'could use a group slower than ' . PaceSpread::clock(PaceSpread::edge($fast, $unit)) . "/$unit.",
                'ask' => ['fast' => (int) round($fast), 'slow' => LeaderMessage::OPEN_SLOW],
            ];
        }

        if (!$spread['jogWalk']) {
            $targets[] = [
                'stretch' => null,
                'jogWalk' => true,
                'phrase' => fn (string $unit) => 'could use a jog/walk group.',
                'ask' => ['kind' => LeaderMessage::ASK_JOG_WALK],
            ];
        }

        return $targets;
    }

    /** The notification data: the run's lead form, carrying the stretch so the form can say what is wanted. */
    private function data(ClubSession $session, array $target): array
    {
        $query = 'intent=lead';

        if (isset($target['ask']['kind'])) {
            $query .= '&kind=' . $target['ask']['kind'];
        } elseif (isset($target['ask']['fast'])) {
            $query .= '&fast=' . $target['ask']['fast'] . '&slow=' . $target['ask']['slow'];
        }

        $data = RunText::data($session);
        $data['route'] = '/runs/' . $session->id . '/groups/new?' . $query;

        return $data;
    }
}
