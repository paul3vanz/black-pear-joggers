<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadState;
use App\Services\LeaderThreadAccess;
use App\Services\LeaderThreadNotifier;
use App\Services\NotificationPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * The leaders thread of a run (D125): a chat between the committee and the
 * people who lead, or have been asked to lead, that run. Same shapes and rules
 * as a group's chat (AppGroupMessageController); the thread id is
 * `leaders:<sessionId>` where a group id would be. Only the committee may start
 * an ask ("can anyone lead 8:25-10:05/mi?").
 */
class AppLeaderThreadController extends Controller
{
    use AppResponses;

    const FIRST_PAGE = 100;

    const SINCE_LIMIT = 500;

    const MAX_LENGTH = 1000;

    const RATE_LIMIT = 20;

    /** Seconds per km: 2:30 to 15:00. */
    const MIN_PACE = 150;
    const MAX_PACE = 900;

    private function notInThread()
    {
        return response()->json(['error' => 'not_in_thread', 'message' => 'You are not in this thread.'], 403);
    }

    /** The thread, or a 404 / 403 response. */
    private function open(Request $request, $sessionId)
    {
        $thread = LeaderThreadAccess::find($request->attributes->get('club'), $sessionId);

        if (!$thread) {
            return $this->notFound('No such run.');
        }

        return $thread->canAccess($request->attributes->get('member')) ? $thread : $this->notInThread();
    }

    private function state(LeaderThreadAccess $thread, $member): ?LeaderThreadState
    {
        return LeaderThreadState::where('session_id', $thread->session->id)->where('member_id', $member->id)->first();
    }

    private function message(LeaderMessage $message, LeaderThreadAccess $thread, array $people): array
    {
        $who = $people[$message->member_id] ?? ['name' => 'Member', 'role' => 'member'];
        $deleted = $message->deleted_at !== null;

        return [
            'id' => $message->id,
            'groupId' => LeaderThreadAccess::threadId($thread->session),
            'memberId' => $message->member_id,
            'authorName' => $who['name'],
            'authorRole' => $who['role'],
            'kind' => $message->kind,
            'body' => $deleted ? '' : $message->body,
            'askFastSPerKm' => $deleted ? null : $message->ask_fast_s_per_km,
            'askSlowSPerKm' => $deleted ? null : $message->ask_slow_s_per_km,
            'createdAt' => NotificationPresenter::time($message->created_at),
            'deletedAt' => NotificationPresenter::time($message->deleted_at),
        ];
    }

    private function messages(LeaderThreadAccess $thread, $messages): array
    {
        $people = $thread->people($messages->pluck('member_id')->all());

        return $messages->map(fn ($m) => $this->message($m, $thread, $people))->all();
    }

    private function threadClosed(LeaderThreadAccess $thread)
    {
        return response()->json(['error' => 'thread_closed', 'message' => $thread->closedMessage()], 409);
    }

    private function rateLimited($member)
    {
        $now = Carbon::now();
        $recent = LeaderMessage::withTrashed()->where('member_id', $member->id)
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
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/messages",
     *   summary="The leaders thread of a run: the first page, or with since the changes and tombstones. Committee/admin, the run's leaders and members an ask went to; others 403 not_in_thread.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ items: Message[], serverTime, closed, muted }; a Message is a group message plus kind (message|ask), askFastSPerKm and askSlowSPerKm"),
     *   @OA\Response(response=403, description="Not in the thread"),
     *   @OA\Response(response=404, description="No such run"),
     * )
     */
    public function index(Request $request, $clubId, $sessionId)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
            return $thread;
        }

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);
        $query = LeaderMessage::where('session_id', $thread->session->id);

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
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/messages",
     *   summary="Post a message to the leaders thread. Idempotent on id. 409 thread_closed 12 hours after the run ends, 429 over 20 a minute.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="The message (200 on a replayed id)"),
     *   @OA\Response(response=403, description="Not in the thread"),
     *   @OA\Response(response=409, description="thread_closed | conflict"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
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

        return $this->save($request, $club, $member, $thread, [
            'kind' => LeaderMessage::KIND_MESSAGE,
            'body' => trim($body),
        ], false);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/ask",
     *   summary="Committee/admin only: ask for someone to lead a pace range (fastSPerKm to slowSPerKm, seconds per km; both optional for any pace). Posts an ask message, sends 'leaders needed' to the members who may lead at that pace and adds them to the thread. Idempotent on id. A day later, if nobody covers that pace, the people asked who haven't answered are nudged once.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="{ message, notified } (200 on a replayed id)"),
     *   @OA\Response(response=403, description="Not committee/admin"),
     *   @OA\Response(response=409, description="thread_closed | conflict"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function ask(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
            return $thread;
        }

        if (!$thread->canModerate($member)) {
            return $this->forbidden('Only the committee can ask for leaders.');
        }

        $note = $request->input('note');
        $validator = $this->makeValidator([
            'id' => $request->input('id'),
            'note' => is_string($note) ? trim($note) : $note,
            'fastSPerKm' => $request->input('fastSPerKm'),
            'slowSPerKm' => $request->input('slowSPerKm'),
        ], [
            'id' => 'nullable|uuid',
            'note' => 'nullable|string|max:' . self::MAX_LENGTH,
            'fastSPerKm' => 'nullable|integer|between:' . self::MIN_PACE . ',' . self::MAX_PACE,
            'slowSPerKm' => 'nullable|integer|between:' . self::MIN_PACE . ',' . self::MAX_PACE . '|required_with:fastSPerKm',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $fast = $request->input('fastSPerKm');
        $slow = $request->input('slowSPerKm');

        if ($fast !== null && (int) $slow < (int) $fast) {
            return response()->json([
                'error' => 'validation_failed',
                'message' => 'slowSPerKm must not be faster than fastSPerKm.',
                'errors' => ['slowSPerKm' => ['slowSPerKm must not be faster than fastSPerKm.']],
            ], 422);
        }

        return $this->save($request, $club, $member, $thread, [
            'kind' => LeaderMessage::KIND_ASK,
            'body' => (string) $note,
            'ask_fast_s_per_km' => $fast === null ? null : (int) $fast,
            'ask_slow_s_per_km' => $fast === null ? null : (int) $slow,
        ], true);
    }

    /** Shared by store and ask: replay check, closed, rate limit, save, notify. */
    private function save(Request $request, $club, $member, LeaderThreadAccess $thread, array $values, bool $isAsk)
    {
        $id = $request->input('id');

        if ($id && ($existing = LeaderMessage::withTrashed()->find($id))) {
            if ($existing->member_id !== $member->id || $existing->session_id !== $thread->session->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            $json = $this->message($existing, $thread, $thread->people([$member->id]));

            return response()->json($isAsk ? ['message' => $json, 'notified' => 0] : $json, 200);
        }

        if ($thread->isClosed()) {
            return $this->threadClosed($thread);
        }

        if ($limited = $this->rateLimited($member)) {
            return $limited;
        }

        $message = new LeaderMessage($values + ['club_id' => $club->id, 'session_id' => $thread->session->id, 'member_id' => $member->id]);

        if ($id) {
            $message->id = $id;
        }

        $message->save();

        $notifier = app(LeaderThreadNotifier::class);
        $notified = 0;

        if ($isAsk) {
            $notified = $notifier->ask($club, $thread, $message);
        } else {
            $notifier->newMessage($club, $thread, $message);
        }

        $json = $this->message($message, $thread, $thread->people([$member->id]));

        return response()->json($isAsk ? ['message' => $json, 'notified' => $notified] : $json, 201);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/messages/{id}",
     *   summary="Delete a message (its author or the committee). Safe to repeat.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Deleted"),
     *   @OA\Response(response=403, description="Not the author or committee"),
     *   @OA\Response(response=404, description="No such message"),
     * )
     */
    public function destroy(Request $request, $clubId, $sessionId, $id)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
            return $thread;
        }

        $message = LeaderMessage::withTrashed()->where('session_id', $thread->session->id)->find($id);

        if (!$message) {
            return $this->notFound('No such message.');
        }

        if ($message->member_id !== $member->id && !$thread->canModerate($member)) {
            return $this->forbidden('Only the author or the committee can delete a message.');
        }

        if (!$message->trashed()) {
            $message->delete(); // sets deleted_at and bumps updated_at, so `since` delivers the tombstone
        }

        return response('', 204);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/messages/read",
     *   summary="Mark the thread read now (also reads its inbox rows).",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Marked"),
     * )
     */
    public function markRead(Request $request, $clubId, $sessionId)
    {
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
            return $thread;
        }

        $now = Carbon::now();
        $this->saveState($request, $thread, ['last_read_at' => $now]);
        app(LeaderThreadNotifier::class)->markInboxRead($request->attributes->get('member')->id, $thread->session, $now);

        return response('', 204);
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/thread",
     *   summary="Mute or unmute the thread for the caller. Body { muted: bool }.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ muted, unreadCount }"),
     * )
     */
    public function updateThread(Request $request, $clubId, $sessionId)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
            return $thread;
        }

        $validator = $this->makeValidator($request->all(), ['muted' => 'required|boolean']);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $state = $this->saveState($request, $thread, ['muted' => $request->boolean('muted')]);

        return response()->json(['muted' => (bool) $state->muted, 'unreadCount' => $thread->unreadCount($member, $state)]);
    }

    private function saveState(Request $request, LeaderThreadAccess $thread, array $values): LeaderThreadState
    {
        $member = $request->attributes->get('member');
        $state = $this->state($thread, $member) ?: new LeaderThreadState([
            'club_id' => $request->attributes->get('club')->id,
            'session_id' => $thread->session->id,
            'member_id' => $member->id,
        ]);

        $state->fill($values);
        $state->save();

        return $state;
    }
}
