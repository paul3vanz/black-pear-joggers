<?php

namespace App\Http\Controllers;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\MemberLogin;
use App\Services\MemberPresenter;
use Illuminate\Support\Facades\Auth;

class AppMeController extends Controller
{
    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/me",
     *   summary="Get the caller's linked club memberships and the clubs they could link to",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="OK",
     *     @OA\JsonContent(
     *       @OA\Property(property="userId", type="string"),
     *       @OA\Property(property="memberships", type="array", @OA\Items(type="object")),
     *       @OA\Property(property="clubs", type="array", @OA\Items(type="object")),
     *     )
     *   ),
     * )
     */
    public function getMe()
    {
        $userId = Auth::user()['sub'];

        $memberIds = MemberLogin::where('user_id', $userId)->pluck('member_id');

        $members = ClubMember::with(['club', 'athlete'])
            ->whereIn('id', $memberIds)
            ->orderBy('club_id')
            ->get();

        return response()->json([
            'userId' => $userId,
            'memberships' => $members->map(fn ($member) => MemberPresenter::membership($member))->values(),
            'clubs' => Club::orderBy('id')->get()->map(fn ($club) => MemberPresenter::club($club))->values(),
        ]);
    }
}
