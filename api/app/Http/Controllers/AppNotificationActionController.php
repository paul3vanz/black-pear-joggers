<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\Club;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\Notification;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Services\AttendanceService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Answers a run reminder from its notification button, with no sign-in (D32).
 * The notification's random actionToken is the credential: it is only sent in
 * the push, and it is scoped to one member, one run and the notification's
 * own actions.
 */
class AppNotificationActionController extends Controller
{
    use AppResponses;

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/notification-actions",
     *   summary="Respond going / not_going from a notification button. No bearer token: the notification's actionToken is the credential. Rate limited to 30/min per IP.",
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="notificationId", type="string", format="uuid"),
     *       @OA\Property(property="token", type="string"),
     *       @OA\Property(property="action", type="string", enum={"going","not_going"}),
     *     )
     *   ),
     *   @OA\Response(response=200, description="{ status, sessionId }"),
     *   @OA\Response(response=404, description="Unknown notification, wrong token or action (never says which)"),
     *   @OA\Response(response=409, description="session_closed: the run is cancelled or finished"),
     *   @OA\Response(response=422, description="Missing or malformed fields"),
     *   @OA\Response(response=429, description="too_many_requests"),
     * )
     */
    public function store(Request $request)
    {
        $validator = $this->makeValidator($request->all(), [
            'notificationId' => 'required|uuid',
            'token' => 'required|string|max:200',
            'action' => 'required|string|max:20',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $notification = Notification::find($request->input('notificationId'));
        $data = $notification ? ($notification->data ?? []) : [];
        $action = $request->input('action');

        $stored = $data['actionToken'] ?? null;
        $actions = $data['actions'] ?? [];

        if (!$notification
            || !is_string($stored) || $stored === ''
            || !hash_equals($stored, (string) $request->input('token'))
            || !is_array($actions) || !in_array($action, $actions, true)
            || !in_array($action, [SessionAttendee::GOING, SessionAttendee::NOT_GOING], true)
            || empty($data['sessionId'])) {
            return $this->notFound();
        }

        $club = $notification->club_id;
        $session = ClubSession::where('club_id', $club)->find($data['sessionId']);
        $member = ClubMember::where('club_id', $club)->find($notification->member_id);

        if (!$session || !$member) {
            return $this->notFound();
        }

        if ($session->isCancelled() || $session->hasEnded()) {
            return response()->json(['error' => 'session_closed', 'message' => 'This run is no longer open.'], 409);
        }

        $row = SessionAttendee::where('session_id', $session->id)->where('member_id', $member->id)->first();

        // Like PUT .../attendance: going keeps the group already chosen (if it still exists), not_going clears it.
        $groupId = $row && $row->group_id !== null && $action === SessionAttendee::GOING
            && SessionGroup::where('club_id', $club)->where('session_id', $session->id)->whereKey($row->group_id)->exists()
            ? $row->group_id
            : null;

        app(AttendanceService::class)->set(
            Club::find($club),
            $member,
            $session,
            $action,
            $groupId,
            $row ? $row->pace_unit : null,
            $row ? $row->pace_from_s : null,
            $row ? $row->pace_to_s : null
        );

        $now = Carbon::now();
        Notification::where('id', $notification->id)->update(['read_at' => $now, 'updated_at' => $now]);

        return response()->json(['status' => $action, 'sessionId' => $session->id]);
    }
}
