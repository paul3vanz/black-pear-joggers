<?php

namespace App\Services;

use App\Models\MemberSeriesPref;
use App\Models\SessionAttendee;

/**
 * The one rule for "is this run followed, and does it show in My runs?" (D117). The reminder job,
 * the group-match notice, the leaders-needed audience and the follows endpoint all call it, and the
 * app's `followResolver` (mobile/lib/features/runs/logic/follow_resolver.dart) is a line-for-line
 * copy checked against the same case table (tests/fixtures/follow_resolver_cases.json), so the
 * feed and the notifications can never disagree again.
 *
 * In order:
 *  1. an RSVP of going or maybe shows the run (and the reminder job reminds it on its own);
 *  2. hide: not followed, not shown;
 *  3. follow: followed and shown;
 *  4. auto: followed and shown only when the member usually comes (D35, `SeriesFollows::usualMemberIds`).
 * A run with no series (a one-off) is never followed, but always shows.
 */
final class FollowResolver
{
    /**
     * @param ?string $rsvp going | maybe | not_going, or null with no answer (leading counts as going)
     * @param ?string $mode follow | auto | hide for the run's series, or null when it has no series
     * @return array{followed: bool, inMine: bool}
     */
    public static function resolve(?string $rsvp, ?string $mode, bool $usuallyComes): array
    {
        $followed = $mode === MemberSeriesPref::FOLLOW
            || ($mode === MemberSeriesPref::AUTO && $usuallyComes);
        $answered = $rsvp === SessionAttendee::GOING || $rsvp === SessionAttendee::MAYBE;

        return [
            'followed' => $followed,
            'inMine' => $answered || $mode === null || $followed,
        ];
    }
}
