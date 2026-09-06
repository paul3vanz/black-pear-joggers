<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function __construct()
    {
    }

    /**
     * @OA\Get(
     *   tags={"User"},
     *   path="/user",
     *   summary="Get the authenticated user",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getUser()
    {
        $id = Auth::user()['sub'];

        $user = User::where('id', $id);

        if ($user) {
            $user = $user->with('athlete')->first();
        }

        return response()->json($user);
    }

    /**
     * @OA\Put(
     *   tags={"User"},
     *   path="/user",
     *   summary="Set the authenticated user's linked athlete",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"athleteId"},
     *       @OA\Property(property="athleteId", type="integer"),
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function setUser(Request $request)
    {
        $this->validate($request, [
            'athleteId' => 'required|integer'
        ]);

        $id = Auth::user()['sub'];

        $user = User::updateOrCreate(['id' => $id], ['athleteId' => $request->athleteId]);

        return response()->json($user);
    }

    /**
     * @OA\Get(
     *   tags={"User"},
     *   path="/user/token",
     *   summary="Get the authenticated user's token",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getToken()
    {
        $user = Auth::user();

        return response()->json($user);
    }
}
