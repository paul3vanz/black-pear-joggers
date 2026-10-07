<?php

namespace App\Http\Middleware;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\MemberLogin;
use Closure;
use Illuminate\Support\Facades\Auth;

/**
 * Registered as `club`. Runs after `auth` on /app routes that carry {clubId}.
 *
 * Resolves the club from the route and the caller's member row in that club
 * (member_logins: club + token sub), and puts both on the request attributes
 * as `club` and `member`.
 *
 *   club:required  (default) 403 not_a_member unless the caller is linked
 *   club:optional  continues with `member` = null when not linked
 */
class ResolveClub
{
    public function handle($request, Closure $next, $mode = 'required')
    {
        $route = $request->route();
        $clubId = is_array($route) ? ($route[2]['clubId'] ?? null) : null;

        $club = $clubId !== null && ctype_digit((string) $clubId)
            ? Club::find((int) $clubId)
            : null;

        if (!$club) {
            return response()->json([
                'error' => 'club_not_found',
                'message' => 'No such club.',
            ], 404);
        }

        $member = null;
        $login = MemberLogin::where('club_id', $club->id)
            ->where('user_id', Auth::user()['sub'])
            ->first();

        if ($login) {
            // A soft-deleted member counts as not linked.
            $member = ClubMember::where('club_id', $club->id)->find($login->member_id);
        }

        if (!$member && $mode !== 'optional') {
            return response()->json([
                'error' => 'not_a_member',
                'message' => 'Link your membership to use ' . $club->name . '.',
            ], 403);
        }

        $request->attributes->set('club', $club);
        $request->attributes->set('member', $member);

        return $next($request);
    }
}
