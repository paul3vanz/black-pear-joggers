<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\LeaderThreadMember;
use App\Models\SessionAttendee;
use Illuminate\Support\Carbon;

/**
 * The people the committee may ask to lead a run (D127): everyone LeaderAudience says might lead it,
 * with how often and when they last led, at what pace, and whether they can be asked right now. The
 * ask sheet shows exactly this list and nobody else, so a Monday leader is never asked about a
 * Tuesday unless they chose Tuesday.
 *
 * Order: people who can be asked first, then those whose usual pace fits what the committee is
 * looking for, then the regulars (most led runs), then the most recent.
 */
class LeaderPool
{
    /** Hours after an ask during which the same person is not asked again. */
    const ASKED_RECENTLY_HOURS = 24;

    /**
     * @param array{fast: float, slow: float}|null $stretch the pace stretch in s/km the committee is looking for
     * @param bool $jogWalk looking for a jog/walk group instead
     * @param string[] $exclude member ids to leave out (the caller)
     * @return array<int, array>
     */
    public function build(Club $club, LeaderThreadAccess $thread, ?array $stretch, bool $jogWalk, array $exclude = [], ?Carbon $now = null): array
    {
        $now = $now ?: Carbon::now();
        $session = $thread->session;
        $tz = app(RunNotifier::class)->tz($club);
        $audience = app(LeaderAudience::class);

        $members = ClubMember::where('club_id', $club->id)->where('status', 'active')
            ->whereNotIn('id', $exclude)->get();
        $reasons = $audience->reasons($session, $tz, $members);

        if (!$reasons) {
            return [];
        }

        $history = $audience->history($session, $tz);
        $leading = array_flip($thread->leaderIds());
        $notGoing = array_flip(
            SessionAttendee::where('session_id', $session->id)->where('status', SessionAttendee::NOT_GOING)->pluck('member_id')->all()
        );
        $askedAt = LeaderThreadMember::where('session_id', $session->id)->pluck('updated_at', 'member_id');
        $people = $thread->people(array_keys($reasons));

        $entries = [];

        foreach ($reasons as $id => $reason) {
            $stats = $history['series'][$id] ?? $history['day'][$id] ?? null;
            $last = $stats['lastLed'] ?? null;
            $asked = $askedAt->get($id);
            $askedRecently = $asked !== null && Carbon::parse($asked)->gt($now->copy()->subHours(self::ASKED_RECENTLY_HOURS));

            $entries[] = [
                'memberId' => $id,
                'name' => $people[$id]['name'],
                'reason' => $reason,
                'ledCount' => $stats['ledCount'] ?? 0,
                'lastLedOn' => $stats['lastLedOn'] ?? null,
                'lastLed' => $last === null ? null : $this->lastLed($last),
                'fitsRange' => $this->fits($last, $stretch, $jogWalk),
                'leadingThisRun' => isset($leading[$id]),
                'notGoing' => isset($notGoing[$id]),
                'askedAt' => $asked ? NotificationPresenter::time(Carbon::parse($asked)) : null,
                'askedRecently' => $askedRecently,
            ];
        }

        usort($entries, function ($a, $b) {
            $flagged = fn ($e) => (int) ($e['leadingThisRun'] || $e['notGoing'] || $e['askedRecently']);

            return [$flagged($a), (int) !$a['fitsRange'], -$a['ledCount'], $b['lastLedOn'] ?? '']
                <=> [$flagged($b), (int) !$b['fitsRange'], -$b['ledCount'], $a['lastLedOn'] ?? ''];
        });

        return $entries;
    }

    /** The member's usual band in s/km (their last led group), null when it has no pace. */
    public static function usualBand(?array $lastLed): ?array
    {
        return $lastLed === null ? null : PaceSpread::band($lastLed['paceUnit'], $lastLed['paceFromS'], $lastLed['paceToS']);
    }

    /** @param array{fast: float, slow: float}|null $stretch */
    private function fits(?array $last, ?array $stretch, bool $jogWalk): bool
    {
        if ($last === null) {
            return false;
        }

        if ($jogWalk) {
            return $last['kind'] === 'jog_walk';
        }

        return $stretch !== null && PaceSpread::fits(self::usualBand($last), $stretch['fast'], $stretch['slow']);
    }

    private function lastLed(array $last): array
    {
        return [
            'kind' => $last['kind'],
            'label' => $last['label'],
            'paceUnit' => $last['paceUnit'],
            'paceFromS' => $last['paceFromS'],
            'paceToS' => $last['paceToS'],
            'paceFromSPerKm' => GroupPresenter::perKm($last['paceFromS'], $last['paceUnit']),
            'paceToSPerKm' => GroupPresenter::perKm($last['paceToS'], $last['paceUnit']),
            'distanceValue' => $last['distanceValue'] !== null ? (float) $last['distanceValue'] : null,
            'distanceUnit' => $last['distanceUnit'],
        ];
    }
}
