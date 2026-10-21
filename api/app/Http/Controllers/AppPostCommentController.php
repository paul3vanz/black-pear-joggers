<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\PostComment;
use App\Models\PostThreadState;
use App\Services\NotificationPresenter;
use App\Services\PostThreadAccess;
use App\Services\PostThreadNotifier;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Comments on a club update (D126): a Q&A thread under each post. Same shapes
 * and rules as a group's chat (AppGroupMessageController); the thread id is
 * `post:<postId>` where a group id would be. Everyone the update is for can read
 * and write; the committee moderates and can close comments on a post (PATCH
 * /posts/{id} with commentsClosed).
 */
class AppPostCommentController extends Controller
{
    use AppResponses;

    const FIRST_PAGE = 100;

    const SINCE_LIMIT = 500;

    const MAX_LENGTH = 1000;

    const RATE_LIMIT = 20;

    /** The thread, or a 404 response (also for a post the caller may not see). */
    private function open(Request $request, $postId)
    {
        $thread = PostThreadAccess::find($request->attributes->get('club'), $postId);

        if (!$thread || !$thread->canAccess($request->attributes->get('member'))) {
            return $this->notFound('No such update.');
        }

        return $thread;
    }

    private function state(PostThreadAccess $thread, $member): ?PostThreadState
    {
        return PostThreadState::where('post_id', $thread->post->id)->where('member_id', $member->id)->first();
    }

    private function message(PostComment $comment, PostThreadAccess $thread, array $people): array
    {
        $who = $people[$comment->member_id] ?? ['name' => 'Member', 'role' => 'member'];
        $deleted = $comment->deleted_at !== null;

        return [
            'id' => $comment->id,
            'groupId' => PostThreadAccess::threadId($thread->post),
            'memberId' => $comment->member_id,
            'authorName' => $who['name'],
            'authorRole' => $who['role'],
            'body' => $deleted ? '' : $comment->body,
            'createdAt' => NotificationPresenter::time($comment->created_at),
            'deletedAt' => NotificationPresenter::time($comment->deleted_at),
        ];
    }

    private function messages(PostThreadAccess $thread, $comments): array
    {
        $people = $thread->people($comments->pluck('member_id')->all());

        return $comments->map(fn ($c) => $this->message($c, $thread, $people))->all();
    }

    private function rateLimited($member)
    {
        $now = Carbon::now();
        $recent = PostComment::withTrashed()->where('member_id', $member->id)
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
     *   path="/app/clubs/{clubId}/posts/{postId}/comments/messages",
     *   summary="The comments on an update: the first page, or with since the changes and tombstones. Anyone the update is for; 404 otherwise.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ items: Comment[], serverTime, closed, muted }; closed is true when the committee closed comments and the caller is not committee"),
     *   @OA\Response(response=404, description="No such update"),
     * )
     */
    public function index(Request $request, $clubId, $postId)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $postId);

        if (!$thread instanceof PostThreadAccess) {
            return $thread;
        }

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);
        $query = PostComment::where('post_id', $thread->post->id);

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
            'closed' => $thread->isClosedFor($member),
            'muted' => $state ? (bool) $state->muted : false,
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{postId}/comments/messages",
     *   summary="Comment on an update. Idempotent on id. 409 comments_closed once the committee closed them (the committee can still reply), 429 over 20 a minute.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=201, description="The comment (200 on a replayed id)"),
     *   @OA\Response(response=404, description="No such update"),
     *   @OA\Response(response=409, description="comments_closed | conflict"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request, $clubId, $postId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $postId);

        if (!$thread instanceof PostThreadAccess) {
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

        if ($id && ($existing = PostComment::withTrashed()->find($id))) {
            if ($existing->member_id !== $member->id || $existing->post_id !== $thread->post->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            return response()->json($this->message($existing, $thread, $thread->people([$member->id])), 200);
        }

        if ($thread->isClosedFor($member)) {
            return response()->json(['error' => 'comments_closed', 'message' => $thread->closedMessage()], 409);
        }

        if ($limited = $this->rateLimited($member)) {
            return $limited;
        }

        $comment = new PostComment(['club_id' => $club->id, 'post_id' => $thread->post->id, 'member_id' => $member->id, 'body' => trim($body)]);

        if ($id) {
            $comment->id = $id;
        }

        $comment->save();

        app(PostThreadNotifier::class)->newComment($club, $thread, $comment);

        return response()->json($this->message($comment, $thread, $thread->people([$member->id])), 201);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{postId}/comments/messages/{id}",
     *   summary="Delete a comment (its author or the committee). Safe to repeat.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Deleted"),
     *   @OA\Response(response=403, description="Not the author or committee"),
     *   @OA\Response(response=404, description="No such comment"),
     * )
     */
    public function destroy(Request $request, $clubId, $postId, $id)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $postId);

        if (!$thread instanceof PostThreadAccess) {
            return $thread;
        }

        $comment = PostComment::withTrashed()->where('post_id', $thread->post->id)->find($id);

        if (!$comment) {
            return $this->notFound('No such comment.');
        }

        if ($comment->member_id !== $member->id && !$thread->canModerate($member)) {
            return $this->forbidden('Only the author or the committee can delete a comment.');
        }

        if (!$comment->trashed()) {
            $comment->delete(); // sets deleted_at and bumps updated_at, so `since` delivers the tombstone
        }

        return response('', 204);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{postId}/comments/messages/read",
     *   summary="Mark the comments read now. Also records that the caller opened the thread, so they hear about replies.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Marked"),
     * )
     */
    public function markRead(Request $request, $clubId, $postId)
    {
        $thread = $this->open($request, $postId);

        if (!$thread instanceof PostThreadAccess) {
            return $thread;
        }

        $now = Carbon::now();
        $this->saveState($request, $thread, ['last_read_at' => $now]);
        app(PostThreadNotifier::class)->markInboxRead($request->attributes->get('member')->id, $thread->post, $now);

        return response('', 204);
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{postId}/comments/thread",
     *   summary="Mute or unmute the comments for the caller. Body { muted: bool }.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ muted, unreadCount }"),
     * )
     */
    public function updateThread(Request $request, $clubId, $postId)
    {
        $member = $request->attributes->get('member');
        $thread = $this->open($request, $postId);

        if (!$thread instanceof PostThreadAccess) {
            return $thread;
        }

        $validator = $this->makeValidator($request->all(), ['muted' => 'required|boolean']);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $state = $this->saveState($request, $thread, ['muted' => $request->boolean('muted')]);

        return response()->json(['muted' => (bool) $state->muted, 'unreadCount' => $thread->unreadCount($member, $state)]);
    }

    private function saveState(Request $request, PostThreadAccess $thread, array $values): PostThreadState
    {
        $member = $request->attributes->get('member');
        $state = $this->state($thread, $member) ?: new PostThreadState([
            'club_id' => $request->attributes->get('club')->id,
            'post_id' => $thread->post->id,
            'member_id' => $member->id,
        ]);

        $state->fill($values);
        $state->save();

        return $state;
    }
}
