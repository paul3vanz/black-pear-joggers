<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadState;
use App\Services\LeaderPool;
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

    /** Seconds per km: 2:30 to 15:00. The two ends also mean "open" (see LeaderMessage::OPEN_FAST). */
    const MIN_PACE = LeaderMessage::OPEN_FAST;
    const MAX_PACE = LeaderMessage::OPEN_SLOW;

    /** Most people one ask can name. */
    const MAX_TARGETS = 30;

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
            'askKind' => $deleted ? null : $message->ask_kind,
            'askedMemberIds' => $deleted ? null : $message->ask_member_ids,
            'askedNames' => $deleted || $message->ask_member_ids === null
                ? null
                : array_map(fn ($id) => ($people[$id] ?? ['name' => 'Member'])['name'], $message->ask_member_ids),
            'createdAt' => NotificationPresenter::time($message->created_at),
            'deletedAt' => NotificationPresenter::time($message->deleted_at),
        ];
    }

    /** Authors and the people an ask names, so a message can show both. */
    private function peopleOf(LeaderThreadAccess $thread, $messages): array
    {
        $ids = [];

        foreach ($messages as $message) {
            $ids[] = $message->member_id;

            foreach ($message->ask_member_ids ?? [] as $id) {
                $ids[] = $id;
            }
        }

        return $thread->people($ids);
    }

    private function messages(LeaderThreadAccess $thread, $messages): array
    {
        $people = $this->peopleOf($thread, $messages);

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
     *   summary="Post a message to the leaders thread. Idempotent on id. 409 thread_closed 48 hours after the run ends, 429 over 20 a minute.",
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
     *   summary="Committee/admin only: ask for someone to lead a stretch of the pace axis (fastSPerKm to slowSPerKm, seconds per km, 150 and 900 meaning open ended; both optional for any pace) or a jog/walk group (kind). With memberIds (from the pool) it goes to exactly those people, minus anyone leading, not going or asked in the last day (returned in skipped); without it, to the members who may lead at that pace. Posts an ask message, sends 'leaders needed' and adds them to the thread. Idempotent on id. A day later, if nobody covers it, the people asked who haven't answered are nudged once.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="{ message, notified, skipped: [{memberId, reason: leading|not_going|asked_recently|inactive}] } (200 on a replayed id)"),
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
            'memberIds' => $request->input('memberIds'),
            'kind' => $request->input('kind'),
        ], [
            'id' => 'nullable|uuid',
            'note' => 'nullable|string|max:' . self::MAX_LENGTH,
            'fastSPerKm' => 'nullable|integer|between:' . self::MIN_PACE . ',' . self::MAX_PACE,
            'slowSPerKm' => 'nullable|integer|between:' . self::MIN_PACE . ',' . self::MAX_PACE . '|required_with:fastSPerKm',
            'memberIds' => 'nullable|array|min:1|max:' . self::MAX_TARGETS . '|required_with:kind',
            'memberIds.*' => 'uuid',
            'kind' => 'nullable|in:' . LeaderMessage::ASK_JOG_WALK,
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $jogWalk = $request->input('kind') === LeaderMessage::ASK_JOG_WALK;
        $memberIds = $request->input('memberIds');
        $fast = $jogWalk ? null : $request->input('fastSPerKm');
        $slow = $jogWalk ? null : $request->input('slowSPerKm');

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
            'ask_member_ids' => $memberIds === null ? null : array_values(array_unique($memberIds)),
            'ask_kind' => $jogWalk ? LeaderMessage::ASK_JOG_WALK : null,
        ], true);
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/sessions/{sessionId}/leaders-chat/pool",
     *   summary="Committee/admin only: the members who could be asked to lead this run (those who led its series or weekday before, or chose the day), with how often and when they last led and at what pace. Optional fastSPerKm and slowSPerKm (the stretch being filled; 150 and 900 mean open ended) or kind=jog_walk set fitsRange. This is the only list the ask sheet offers.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ items: [{ memberId, name, reason: chose_day|led_series|led_day|new_leader, ledCount, lastLedOn, lastLed, fitsRange, leadingThisRun, notGoing, askedAt, askedRecently }] }, people who can be asked first, then fitsRange, then ledCount"),
     *   @OA\Response(response=403, description="Not committee/admin"),
     *   @OA\Response(response=404, description="No such run"),
     * )
     */
    public function pool(Request $request, $clubId, $sessionId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $sessionId);

        if (!$thread instanceof LeaderThreadAccess) {
            return $thread;
        }

        if (!$thread->canModerate($member)) {
            return $this->forbidden('Only the committee can see who could lead.');
        }

        $validator = $this->makeValidator([
            'fastSPerKm' => $request->query('fastSPerKm'),
            'slowSPerKm' => $request->query('slowSPerKm'),
            'kind' => $request->query('kind'),
        ], [
            'fastSPerKm' => 'nullable|integer|between:' . self::MIN_PACE . ',' . self::MAX_PACE,
            'slowSPerKm' => 'nullable|integer|between:' . self::MIN_PACE . ',' . self::MAX_PACE . '|required_with:fastSPerKm',
            'kind' => 'nullable|in:' . LeaderMessage::ASK_JOG_WALK,
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $fast = $request->query('fastSPerKm');
        $slow = $request->query('slowSPerKm');
        $stretch = $fast === null ? null : ['fast' => (float) min($fast, $slow), 'slow' => (float) max($fast, $slow)];

        return response()->json([
            'items' => app(LeaderPool::class)->build($club, $thread, $stretch, $request->query('kind') === LeaderMessage::ASK_JOG_WALK, [$member->id]),
        ]);
    }

    /** Shared by store and ask: replay check, closed, rate limit, save, notify. */
    private function save(Request $request, $club, $member, LeaderThreadAccess $thread, array $values, bool $isAsk)
    {
        $id = $request->input('id');

        if ($id && ($existing = LeaderMessage::withTrashed()->find($id))) {
            if ($existing->member_id !== $member->id || $existing->session_id !== $thread->session->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            $json = $this->message($existing, $thread, $this->peopleOf($thread, [$existing]));

            return response()->json($isAsk ? ['message' => $json, 'notified' => 0, 'skipped' => []] : $json, 200);
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
        $skipped = [];

        if ($isAsk) {
            ['sent' => $notified, 'skipped' => $skipped] = $notifier->ask($club, $thread, $message);
        } else {
            $notifier->newMessage($club, $thread, $message);
        }

        $json = $this->message($message, $thread, $this->peopleOf($thread, [$message]));

        return response()->json($isAsk ? ['message' => $json, 'notified' => $notified, 'skipped' => $skipped] : $json, 201);
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
