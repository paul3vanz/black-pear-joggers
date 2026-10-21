<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\GroupMessage;
use App\Models\GroupThreadState;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Services\GroupMessageNotifier;
use App\Services\LeaderThreadAccess;
use App\Services\NotificationPresenter;
use App\Services\ThreadAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Group chat: one thread per run group (Phase 6). Contract: mobile/docs/api-contract.md.
 * Who may do what is decided by ThreadAccess.
 */
class AppGroupMessageController extends Controller
{
    use AppResponses;

    /** Newest messages returned by a fetch without `since`. */
    const FIRST_PAGE = 100;

    /** Most messages a `since` fetch returns. */
    const SINCE_LIMIT = 500;

    const MAX_LENGTH = 1000;

    /** Messages one member may post per minute. */
    const RATE_LIMIT = 20;

    /** How far back a thread counts as recent for GET /threads. */
    const RECENT_DAYS = 14;

    private function notInGroup()
    {
        return response()->json(['error' => 'not_in_group', 'message' => 'You are not in this group.'], 403);
    }

    /** @return ThreadAccess|\Illuminate\Http\JsonResponse the thread, or the 404 / 403 to return */
    private function open(Request $request, $groupId)
    {
        $thread = ThreadAccess::find($request->attributes->get('club'), $groupId);

        if (!$thread) {
            return $this->notFound('No such group.');
        }

        return $thread->canAccess($request->attributes->get('member')) ? $thread : $this->notInGroup();
    }

    private function state(ThreadAccess $thread, $member): ?GroupThreadState
    {
        return GroupThreadState::where('group_id', $thread->group->id)->where('member_id', $member->id)->first();
    }

    /** Messages by other people after the member's last read, not deleted. */
    private function unreadCount(ThreadAccess $thread, $member, ?GroupThreadState $state): int
    {
        $query = GroupMessage::where('group_id', $thread->group->id)->where('member_id', '!=', $member->id);

        if ($state && $state->last_read_at) {
            $query->where('created_at', '>', $state->last_read_at);
        }

        return $query->count();
    }

    /** @param array<string, array{name: string, role: string}> $people */
    private function message(GroupMessage $message, array $people): array
    {
        $who = $people[$message->member_id] ?? ['name' => 'Member', 'role' => ThreadAccess::ROLE_MEMBER];
        $deleted = $message->deleted_at !== null;

        return [
            'id' => $message->id,
            'groupId' => $message->group_id,
            'memberId' => $message->member_id,
            'authorName' => $who['name'],
            'authorRole' => $who['role'],
            'body' => $deleted ? '' : $message->body,
            'createdAt' => NotificationPresenter::time($message->created_at),
            'deletedAt' => NotificationPresenter::time($message->deleted_at),
        ];
    }

    private function messages(ThreadAccess $thread, $messages): array
    {
        $people = $thread->people($messages->pluck('member_id')->all());

        return $messages->map(function ($message) use ($people) {
            return $this->message($message, $people);
        })->all();
    }

    private function threadClosed(ThreadAccess $thread)
    {
        return response()->json(['error' => 'thread_closed', 'message' => $thread->closedMessage()], 409);
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{groupId}/messages",
     *   summary="A group's chat. Without since: the newest 100, oldest first. With since: everything changed since then (incl. deleted tombstones), up to 500.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: Message[], serverTime, closed, muted }"),
     *   @OA\Response(response=403, description="not_in_group"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=422, description="Invalid since"),
     * )
     */
    public function index(Request $request, $clubId, $groupId)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $groupId);

        if (!$thread instanceof ThreadAccess) {
            return $thread;
        }

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);
        $query = GroupMessage::where('group_id', $thread->group->id);

        if ($since) {
            $items = $query->withTrashed()->where('updated_at', '>=', $since)
                ->orderBy('created_at')->orderBy('id')->limit(self::SINCE_LIMIT)->get();
        } else {
            $items = $query->orderByDesc('created_at')->orderByDesc('id')->limit(self::FIRST_PAGE)->get()->reverse()->values();
        }

        $state = $this->state($thread, $member);

        return response()->json([
            'items' => $this->messages($thread, $items),
            'serverTime' => NotificationPresenter::time($serverTime),
            'closed' => $thread->isClosed(),
            'muted' => $state ? (bool) $state->muted : false,
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{groupId}/messages",
     *   summary="Post a message (1-1000 characters, trimmed). Idempotent on id; 20 per minute per member. Notifies the thread.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(@OA\JsonContent(
     *     @OA\Property(property="id", type="string", format="uuid"),
     *     @OA\Property(property="body", type="string", maxLength=1000),
     *   )),
     *   @OA\Response(response=201, description="The message (200 on a replayed id)"),
     *   @OA\Response(response=403, description="not_in_group"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=409, description="thread_closed | conflict"),
     *   @OA\Response(response=422, description="Validation error"),
     *   @OA\Response(response=429, description="too_many_requests"),
     * )
     */
    public function store(Request $request, $clubId, $groupId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $groupId);

        if (!$thread instanceof ThreadAccess) {
            return $thread;
        }

        $body = $request->input('body');
        $validator = $this->makeValidator([
            'id' => $request->input('id'),
            'body' => is_string($body) ? trim($body) : $body,
        ], [
            'id' => 'nullable|uuid',
            'body' => 'required|string|max:' . self::MAX_LENGTH,
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $id = $request->input('id');

        if ($id && ($existing = GroupMessage::withTrashed()->find($id))) {
            if ($existing->member_id !== $member->id || $existing->group_id !== $thread->group->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            return response()->json($this->message($existing, $thread->people([$member->id])), 200);
        }

        if ($thread->isClosed()) {
            return $this->threadClosed($thread);
        }

        if ($limited = $this->rateLimited($member)) {
            return $limited;
        }

        $message = new GroupMessage(['club_id' => $club->id, 'group_id' => $thread->group->id, 'member_id' => $member->id, 'body' => trim($body)]);

        if ($id) {
            $message->id = $id;
        }

        $message->save();

        app(GroupMessageNotifier::class)->newMessage($club, $thread, $message);

        return response()->json($this->message($message, $thread->people([$member->id])), 201);
    }

    /** A 429 when the member has posted 20 messages in the last minute (deleted ones count), else null. */
    private function rateLimited($member)
    {
        $now = Carbon::now();
        $recent = GroupMessage::withTrashed()->where('member_id', $member->id)
            ->where('created_at', '>', $now->copy()->subMinute())
            ->orderBy('created_at')->pluck('created_at');

        if ($recent->count() < self::RATE_LIMIT) {
            return null;
        }

        $wait = max(1, 60 - $now->diffInSeconds(Carbon::parse($recent->first())));

        return response()->json(
            ['error' => 'too_many_requests', 'message' => 'You are sending messages too quickly. Try again in a moment.'],
            429,
            ['Retry-After' => $wait]
        );
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{groupId}/messages/{id}",
     *   summary="Delete a message (soft). The author, the group's leaders, the coordinator and committee/admin may. Repeating it is fine.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Deleted (or already deleted)"),
     *   @OA\Response(response=403, description="not_in_group | forbidden"),
     *   @OA\Response(response=404, description="No such group or message"),
     * )
     */
    public function destroy(Request $request, $clubId, $groupId, $id)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $groupId);

        if (!$thread instanceof ThreadAccess) {
            return $thread;
        }

        $message = GroupMessage::withTrashed()->where('group_id', $thread->group->id)->find($id);

        if (!$message) {
            return $this->notFound('No such message.');
        }

        if ($message->member_id !== $member->id && !$thread->canModerate($member)) {
            return $this->forbidden('Only the author, the group leaders, the run coordinator or the committee can delete a message.');
        }

        if (!$message->trashed()) {
            $message->delete(); // sets deleted_at and bumps updated_at, so `since` delivers the tombstone
        }

        return response('', 204);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{groupId}/messages/read",
     *   summary="Mark the thread read for the caller, up to now.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Marked read"),
     *   @OA\Response(response=403, description="not_in_group"),
     *   @OA\Response(response=404, description="No such group"),
     * )
     */
    public function markRead(Request $request, $clubId, $groupId)
    {
        $thread = $this->open($request, $groupId);

        if (!$thread instanceof ThreadAccess) {
            return $thread;
        }

        $now = Carbon::now();
        $this->saveState($request, $thread, ['last_read_at' => $now]);

        // The thread's single inbox row (dedupe key group_msg:<id>) is read too.
        Notification::where('member_id', $request->attributes->get('member')->id)
            ->where('dedupe_key', 'group_msg:' . $thread->group->id)
            ->whereNull('read_at')
            ->update(['read_at' => $now, 'updated_at' => $now]);

        return response('', 204);
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/groups/{groupId}/thread",
     *   summary="Mute or unmute the thread's notifications for the caller.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(@OA\JsonContent(@OA\Property(property="muted", type="boolean"))),
     *   @OA\Response(response=200, description="{ muted, unreadCount }"),
     *   @OA\Response(response=403, description="not_in_group"),
     *   @OA\Response(response=404, description="No such group"),
     *   @OA\Response(response=422, description="muted is not a boolean"),
     * )
     */
    public function updateThread(Request $request, $clubId, $groupId)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $groupId);

        if (!$thread instanceof ThreadAccess) {
            return $thread;
        }

        $validator = $this->makeValidator($request->all(), ['muted' => 'required|boolean']);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $state = $this->saveState($request, $thread, ['muted' => $request->boolean('muted')]);

        return response()->json(['muted' => (bool) $state->muted, 'unreadCount' => $this->unreadCount($thread, $member, $state)]);
    }

    private function saveState(Request $request, ThreadAccess $thread, array $values): GroupThreadState
    {
        $member = $request->attributes->get('member');
        $state = $this->state($thread, $member) ?: new GroupThreadState([
            'club_id' => $request->attributes->get('club')->id,
            'group_id' => $thread->group->id,
            'member_id' => $member->id,
        ]);

        $state->fill($values);
        $state->save();

        return $state;
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/threads",
     *   summary="The caller's group chats that have a message from the last 14 days, newest message first, with unread counts.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ items: Thread[], serverTime }"),
     * )
     */
    public function threads(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $serverTime = $this->serverTime();

        $recent = GroupMessage::where('club_id', $club->id)
            ->where('created_at', '>=', Carbon::now()->subDays(self::RECENT_DAYS))
            ->select('group_id')->distinct()->pluck('group_id')->all();

        $groups = $recent
            ? SessionGroup::where('club_id', $club->id)->whereIn('id', $recent)->with('session')->get()
            : collect();

        $staff = $member->hasRole('committee', 'admin');
        $mine = $staff ? [] : array_merge(
            SessionGroupLeader::where('member_id', $member->id)->where('status', SessionGroupLeader::CONFIRMED)->pluck('group_id')->all(),
            SessionAttendee::where('member_id', $member->id)->whereIn('status', [SessionAttendee::GOING, SessionAttendee::MAYBE])
                ->whereNotNull('group_id')->pluck('group_id')->all()
        );

        $unit = MemberPreference::where('club_id', $club->id)->where('member_id', $member->id)->value('pace_unit') === 'km' ? 'km' : 'mi';
        $states = GroupThreadState::where('member_id', $member->id)->whereIn('group_id', $recent ?: [''])->get()->keyBy('group_id');

        $items = [];

        foreach ($groups as $group) {
            $session = $group->session;

            if (!$session || $session->trashed()) {
                continue;
            }

            $thread = new ThreadAccess($group, $session);

            if (!$staff && !in_array($group->id, $mine, true) && !$thread->isCoordinator($member)) {
                continue;
            }

            $last = GroupMessage::where('group_id', $group->id)
                ->where('created_at', '>=', Carbon::now()->subDays(self::RECENT_DAYS))
                ->orderByDesc('created_at')->orderByDesc('id')->first();

            if (!$last) {
                continue; // only deleted messages in the window
            }

            $state = $states->get($group->id);
            $items[] = [
                'sort' => [$last->created_at->getTimestamp(), $last->id],
                'item' => [
                    'groupId' => $group->id,
                    'sessionId' => $session->id,
                    'label' => $thread->label($unit),
                    'sessionTitle' => $session->title,
                    'localDate' => $session->localDateYmd(),
                    'localStartTime' => $session->local_start_time,
                    'lastMessage' => [
                        'authorName' => $thread->people([$last->member_id])[$last->member_id]['name'],
                        'body' => $last->body,
                        'createdAt' => NotificationPresenter::time($last->created_at),
                    ],
                    'unreadCount' => $this->unreadCount($thread, $member, $state),
                    'muted' => $state ? (bool) $state->muted : false,
                    'closed' => $thread->isClosed(),
                ],
            ];
        }

        // D125: the run's leaders threads this member is in, listed with the group chats.
        $items = array_merge($items, LeaderThreadAccess::listFor($club, $member));

        usort($items, function ($a, $b) {
            return $b['sort'] <=> $a['sort'];
        });

        return response()->json([
            'items' => array_map(function ($row) {
                return $row['item'];
            }, $items),
            'serverTime' => NotificationPresenter::time($serverTime),
        ]);
    }
}
