<?php

namespace App\Http\Controllers;

use Illuminate\Support\Carbon;
use App\Models\Athlete;
use App\Models\ClubMember;
use App\Models\MemberLinkAttempt;
use App\Models\MemberLogin;
use App\Models\User;
use App\Services\MemberPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class AppMembershipController extends Controller
{
    /** Failed attempts allowed per login and club in the last hour. */
    const MAX_FAILED_ATTEMPTS = 5;

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/link",
     *   summary="Check urn + dob against athletes and link the caller's login to that club member",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"urn","dob"},
     *       @OA\Property(property="urn", type="integer"),
     *       @OA\Property(property="dob", type="string", format="date"),
     *     )
     *   ),
     *   @OA\Response(response=200, description="The linked membership"),
     *   @OA\Response(response=404, description="No athlete with that URN and date of birth"),
     *   @OA\Response(response=422, description="Validation error"),
     *   @OA\Response(response=429, description="Too many failed attempts"),
     * )
     */
    public function link(Request $request)
    {
        $club = $request->attributes->get('club');
        $userId = Auth::user()['sub'];

        // Validated by hand: the app's exception handler turns a thrown
        // ValidationException into a 500, and the contract promises a 422.
        $validator = Validator::make($request->all(), [
            'urn' => 'required|integer',
            'dob' => 'required|date_format:Y-m-d',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => 'validation_failed',
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors(),
            ], 422);
        }

        $recentFailures = MemberLinkAttempt::where('user_id', $userId)
            ->where('club_id', $club->id)
            ->where('success', false)
            ->where('created_at', '>=', Carbon::now()->subHour())
            ->count();

        if ($recentFailures >= self::MAX_FAILED_ATTEMPTS) {
            return response()->json([
                'error' => 'too_many_attempts',
                'message' => 'Too many failed attempts. Try again in an hour.',
            ], 429);
        }

        $athlete = Athlete::with(['membership', 'payments'])
            ->where('urn', $request->input('urn'))
            ->whereDate('dob', $request->input('dob'))
            ->first();

        if (!$athlete) {
            MemberLinkAttempt::create(['user_id' => $userId, 'club_id' => $club->id, 'success' => false]);

            return response()->json([
                'error' => 'not_found',
                'message' => 'No member found with that URN and date of birth.',
            ], 404);
        }

        $member = DB::transaction(function () use ($club, $athlete, $userId) {
            $member = ClubMember::withTrashed()
                ->where('club_id', $club->id)
                ->where('athlete_id', $athlete->id)
                ->first() ?? new ClubMember(['club_id' => $club->id, 'athlete_id' => $athlete->id]);

            $member->display_name = trim($athlete->first_name . ' ' . $athlete->last_name);
            $member->status = MemberPresenter::statusFor($athlete);
            $member->deleted_at = null;
            $member->save();

            // Moves the login if it was linked to a different member of this club.
            MemberLogin::updateOrCreate(
                ['club_id' => $club->id, 'user_id' => $userId],
                ['member_id' => $member->id, 'linked_at' => Carbon::now()]
            );

            // Keep the web profile (users.athleteId) in step.
            User::updateOrCreate(['id' => $userId], ['athleteId' => $athlete->id]);

            MemberLinkAttempt::create(['user_id' => $userId, 'club_id' => $club->id, 'success' => true]);

            return $member;
        });

        $member->setRelation('club', $club);
        $member->setRelation('athlete', $athlete);

        return response()->json(MemberPresenter::membership($member));
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/link",
     *   summary="Unlink the caller's login from the club (the member row is kept)",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=204, description="Unlinked"),
     * )
     */
    public function unlink(Request $request)
    {
        $club = $request->attributes->get('club');

        MemberLogin::where('club_id', $club->id)
            ->where('user_id', Auth::user()['sub'])
            ->delete();

        return response('', 204);
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/profile",
     *   summary="Get the caller's own athlete details and membership status for a club",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     *   @OA\Response(response=404, description="Club or athlete not found"),
     * )
     */
    public function profile(Request $request)
    {
        $member = $request->attributes->get('member');

        $athlete = Athlete::with(['membership', 'payments'])->find($member->athlete_id);

        if (!$athlete) {
            return response()->json([
                'error' => 'athlete_not_found',
                'message' => 'The athlete record for this member no longer exists.',
            ], 404);
        }

        $status = MemberPresenter::statusFor($athlete);

        if ($member->status !== $status) {
            $member->status = $status;
            $member->save();
        }

        return response()->json(MemberPresenter::profile($member, $athlete));
    }
}
