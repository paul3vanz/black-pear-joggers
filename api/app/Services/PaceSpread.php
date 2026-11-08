<?php

namespace App\Services;

use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;

/**
 * The spread of paces the committee aims for on a paced run (D128), the server twin of
 * `buildSpreadTarget` in the app. Both are tested against tests/fixtures/spread_target_cases.json,
 * so change the rule in both places and the fixture together.
 *
 * Groups with a confirmed leader count, at their real pace: a single pace is that pace and a range
 * is its two ends, with no tolerance padding. Nothing is rounded to a minute. The rule:
 *
 *  - gap: two neighbouring groups MAX_GAP_PER_MI or more apart (nearest edge to nearest edge). A new
 *    group would fit FILL_MARGIN_PER_MI inside each edge, so 9:15 and 10:30 leaves "9:30 to 10:15";
 *  - faster end: the fastest group starts later than TARGET_FAST + END_FLEX (8:30);
 *  - slower end: the slowest group ends before TARGET_SLOW - END_FLEX (11:30);
 *  - jog/walk: no led jog/walk group without a pace;
 *  - with no led paced group at all there is one gap over the whole target (empty).
 *
 * Everything is worked in seconds per km internally; the constants are written per mile, which is
 * how the committee thinks of them.
 */
class PaceSpread
{
    const TARGET_FAST_PER_MI = 480;
    const TARGET_SLOW_PER_MI = 720;
    const END_FLEX_PER_MI = 30;
    const MAX_GAP_PER_MI = 45;
    const FILL_MARGIN_PER_MI = 15;

    /** How far a leader's usual pace may sit outside the stretch and still fit it (s/mi). */
    const FIT_FLEX_PER_MI = 30;

    /** s/km for $perMile seconds per mile. */
    public static function km(float $perMile): float
    {
        return $perMile / GroupPresenter::KM_PER_MILE;
    }

    /** Seconds per $unit for s/km. */
    public static function inUnit(float $perKm, string $unit): float
    {
        return $unit === 'mi' ? $perKm * GroupPresenter::KM_PER_MILE : $perKm;
    }

    /**
     * A group's raw band in s/km: [fast, slow], or null with no pace.
     *
     * @return array{0: float, 1: float}|null
     */
    public static function band(?string $unit, $fromS, $toS): ?array
    {
        if ($unit === null || $unit === '' || $fromS === null) {
            return null;
        }

        $from = $unit === 'mi' ? $fromS / GroupPresenter::KM_PER_MILE : (float) $fromS;
        $to = $toS === null ? $from : ($unit === 'mi' ? $toS / GroupPresenter::KM_PER_MILE : (float) $toS);

        return [min($from, $to), max($from, $to)];
    }

    /**
     * @param array<int, array{0: float, 1: float}> $bands the bands (s/km) of the groups that have a leader and a pace
     * @return array{
     *     empty: bool,
     *     gaps: array<int, array{from: float, to: float, fast: float, slow: float}>,
     *     fasterEnd: array{slow: float}|null,
     *     slowerEnd: array{fast: float}|null
     * } gaps and ends are in s/km; from/to are the neighbours' edges, fast/slow the stretch a new group would fit
     */
    public static function analyse(array $bands): array
    {
        $fastEnd = self::km(self::TARGET_FAST_PER_MI + self::END_FLEX_PER_MI);
        $slowEnd = self::km(self::TARGET_SLOW_PER_MI - self::END_FLEX_PER_MI);
        $maxGap = self::km(self::MAX_GAP_PER_MI);
        $margin = self::km(self::FILL_MARGIN_PER_MI);

        if (!$bands) {
            return ['empty' => true, 'gaps' => [], 'fasterEnd' => null, 'slowerEnd' => null];
        }

        usort($bands, fn ($a, $b) => $a[0] <=> $b[0]);

        $gaps = [];
        $edge = $bands[0][1];

        foreach (array_slice($bands, 1) as $band) {
            if ($band[0] - $edge >= $maxGap - 1e-9) {
                $gaps[] = ['from' => $edge, 'to' => $band[0], 'fast' => $edge + $margin, 'slow' => $band[0] - $margin];
            }

            $edge = max($edge, $band[1]);
        }

        return [
            'empty' => false,
            'gaps' => $gaps,
            'fasterEnd' => $bands[0][0] > $fastEnd + 1e-9 ? ['slow' => $fastEnd] : null,
            'slowerEnd' => $edge < $slowEnd - 1e-9 ? ['fast' => $slowEnd] : null,
        ];
    }

    /**
     * The spread of a run: its analysis plus whether a jog/walk group (no pace) has a leader.
     *
     * @return array{empty: bool, gaps: array, fasterEnd: ?array, slowerEnd: ?array, jogWalk: bool}
     */
    public static function forSession(ClubSession $session): array
    {
        $groups = SessionGroup::where('session_id', $session->id)->get();
        $ledIds = array_flip(
            SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
                ->whereIn('group_id', $groups->pluck('id'))->pluck('group_id')->unique()->all()
        );

        $bands = [];
        $jogWalk = false;

        foreach ($groups as $group) {
            if (!isset($ledIds[$group->id])) {
                continue;
            }

            $band = self::band($group->pace_unit, $group->pace_from_s, $group->pace_to_s);

            if ($band !== null) {
                $bands[] = $band;
            } elseif ($group->kind === 'jog_walk') {
                $jogWalk = true;
            }
        }

        return self::analyse($bands) + ['jogWalk' => $jogWalk];
    }

    /** True for run modes the spread applies to: the ones with pace groups. */
    public static function appliesTo(ClubSession $session): bool
    {
        return $session->group_mode === 'paced' && !$session->isEventMode();
    }

    // ---- how a stretch is shown ----------------------------------------------------------------

    /** The stretch of a gap as whole 5 s in $unit, rounded inwards so the stretch named really is open: [from, to]. */
    public static function window(array $gap, string $unit): array
    {
        return [
            (int) (ceil((self::inUnit($gap['fast'], $unit) / 5) - 1e-6) * 5),
            (int) (floor((self::inUnit($gap['slow'], $unit) / 5) + 1e-6) * 5),
        ];
    }

    /** An end's edge, nearest 5 s in $unit (8:30/mi, or 5:15/km for the same stretch). */
    public static function edge(float $perKm, string $unit): int
    {
        return (int) (round(self::inUnit($perKm, $unit) / 5) * 5);
    }

    /** "9:30" for whole seconds. */
    public static function clock(int $seconds): string
    {
        return intdiv($seconds, 60) . ':' . str_pad((string) ($seconds % 60), 2, '0', STR_PAD_LEFT);
    }

    /**
     * What an ask is looking for, from its stretch in s/km: "a group between 9:30 and 10:15/mi",
     * "a group faster than 8:30/mi", "a group slower than 11:30/mi", or '' for any pace.
     */
    public static function stretchPhrase(int $fastSPerKm, int $slowSPerKm, string $unit): string
    {
        $openFast = $fastSPerKm <= LeaderMessage::OPEN_FAST;
        $openSlow = $slowSPerKm >= LeaderMessage::OPEN_SLOW;

        if ($openFast && $openSlow) {
            return '';
        }

        if ($openFast) {
            return 'a group faster than ' . self::clock(self::edge($slowSPerKm, $unit)) . '/' . $unit;
        }

        if ($openSlow) {
            return 'a group slower than ' . self::clock(self::edge($fastSPerKm, $unit)) . '/' . $unit;
        }

        return 'a group between ' . self::clock(self::edge($fastSPerKm, $unit)) . ' and ' . self::clock(self::edge($slowSPerKm, $unit)) . '/' . $unit;
    }

    /** Whether a leader's usual band (s/km) sits within FIT_FLEX of the stretch [fast, slow] (s/km). */
    public static function fits(?array $usual, float $fast, float $slow): bool
    {
        if ($usual === null) {
            return false;
        }

        $flex = self::km(self::FIT_FLEX_PER_MI);

        return $usual[0] - $flex <= $slow && $usual[1] + $flex >= $fast;
    }
}
