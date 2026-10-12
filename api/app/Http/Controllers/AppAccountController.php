<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Services\AccountDeletion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AppAccountController extends Controller
{
    use AppResponses;

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/account",
     *   summary="Delete the caller's app account: unlinks every login, removes devices and, for members with no login left, all their app data. Not club-scoped. The website login, athlete and membership records stay.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"confirm"},
     *       @OA\Property(property="confirm", type="string", enum={"DELETE"}),
     *     )
     *   ),
     *   @OA\Response(response=204, description="Deleted (also when there was nothing left to delete)"),
     *   @OA\Response(response=409, description="last_admin: the caller is the only admin of a club"),
     *   @OA\Response(response=422, description="confirm is missing or not DELETE"),
     * )
     */
    public function destroy(Request $request, AccountDeletion $deletion)
    {
        $validator = $this->makeValidator($request->all(), [
            'confirm' => 'required|in:DELETE',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $userId = Auth::user()['sub'];

        if ($deletion->lastAdminClubIds($userId)) {
            return response()->json([
                'error' => 'last_admin',
                'message' => 'Make someone else an admin first.',
            ], 409);
        }

        $deletion->delete($userId);

        return response('', 204);
    }
}
