<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;

class AppDeviceController extends Controller
{
    use AppResponses;

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/devices",
     *   summary="Register (or refresh) the caller's FCM token. A token held by another login moves to the caller.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"token","platform"},
     *       @OA\Property(property="token", type="string"),
     *       @OA\Property(property="platform", type="string", enum={"android","ios"}),
     *       @OA\Property(property="appVersion", type="string", example="1.0.0+1"),
     *     )
     *   ),
     *   @OA\Response(response=204, description="Registered"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function register(Request $request)
    {
        $validator = $this->makeValidator($request->all(), [
            'token' => 'required|string|max:255',
            'platform' => 'required|in:android,ios',
            'appVersion' => 'nullable|string|max:32',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        Device::updateOrCreate(
            ['token' => $request->input('token')],
            [
                'user_id' => Auth::user()['sub'],
                'platform' => $request->input('platform'),
                'app_version' => $request->input('appVersion'),
                'last_seen_at' => Carbon::now(),
            ]
        );

        return response('', 204);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/devices/{token}",
     *   summary="Remove an FCM token, only if it belongs to the caller",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="token", in="path", required=true, @OA\Schema(type="string")),
     *   @OA\Response(response=204, description="Removed (or not the caller's, or unknown)"),
     * )
     */
    public function unregister(Request $request, $token)
    {
        // Lumen leaves percent-escapes in a catch-all segment; FCM tokens never contain a literal '%'.
        $token = rawurldecode($token);

        Device::where('token', $token)
            ->where('user_id', Auth::user()['sub'])
            ->delete();

        return response('', 204);
    }
}
