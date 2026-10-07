<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\ClubMember;
use App\Models\Post;
use App\Services\NotificationCategories;
use App\Services\NotificationPresenter;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class AppPostController extends Controller
{
    use AppResponses;

    /** Roles that may create, edit and delete posts. */
    const MANAGER_ROLES = ['committee', 'admin'];

    private function rules(bool $creating): array
    {
        $required = $creating ? 'required' : 'sometimes|required';

        return [
            'id' => 'nullable|uuid',
            'title' => $required . '|string|max:255',
            'bodyMd' => $required . '|string',
            'priority' => 'nullable|in:' . implode(',', Post::PRIORITIES),
            'audience' => 'nullable|in:' . implode(',', Post::AUDIENCES),
            'pinnedUntil' => 'nullable|date',
            'notify' => 'nullable|boolean',
        ];
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts",
     *   summary="Club updates the caller's roles allow them to see. With since: changes and tombstones.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="since", in="query", required=false, @OA\Schema(type="string", format="date-time")),
     *   @OA\Response(response=200, description="{ items: Post[], serverTime }"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     * )
     */
    public function index(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$this->sinceIsValid($request)) {
            return $this->invalidSince();
        }

        $serverTime = $this->serverTime();
        $since = $this->since($request);

        $query = Post::where('club_id', $club->id)
            ->whereIn('audience', $member->audiences())
            ->with('author')
            ->orderBy('updated_at')
            ->orderBy('id');

        if ($since) {
            $query->withTrashed()->where('updated_at', '>=', $since);
        }

        return response()->json([
            'items' => $query->get()->map(function ($post) {
                return NotificationPresenter::post($post);
            })->all(),
            'serverTime' => NotificationPresenter::time($serverTime),
        ]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts",
     *   summary="Publish a club update (committee/admin). Idempotent on the client id.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"title","bodyMd"},
     *       @OA\Property(property="id", type="string", format="uuid"),
     *       @OA\Property(property="title", type="string"),
     *       @OA\Property(property="bodyMd", type="string"),
     *       @OA\Property(property="priority", type="string", enum={"normal","important"}),
     *       @OA\Property(property="audience", type="string", enum={"all","leaders","committee"}),
     *       @OA\Property(property="pinnedUntil", type="string", format="date-time", nullable=true),
     *       @OA\Property(property="notify", type="boolean"),
     *     )
     *   ),
     *   @OA\Response(response=201, description="The post (200 when the id was already used)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=409, description="The id belongs to another club's post"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function store(Request $request, NotificationService $notifications)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$member->hasRole(...self::MANAGER_ROLES)) {
            return $this->forbidden('Only the committee can publish club updates.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(true));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $id = $request->input('id');

        if ($id && ($existing = Post::withTrashed()->find($id))) {
            if ((int) $existing->club_id !== (int) $club->id) {
                return response()->json(['error' => 'conflict', 'message' => 'That id is already in use.'], 409);
            }

            // A replay of an earlier create: return it, don't notify again.
            return response()->json(NotificationPresenter::post($existing->load('author')), 200);
        }

        $post = new Post([
            'club_id' => $club->id,
            'author_member_id' => $member->id,
            'title' => $request->input('title'),
            'body_md' => $request->input('bodyMd'),
            'priority' => $request->input('priority', 'normal'),
            'audience' => $request->input('audience', 'all'),
            'published_at' => Carbon::now(),
            'pinned_until' => $request->input('pinnedUntil') ? Carbon::parse($request->input('pinnedUntil')) : null,
        ]);

        if ($id) {
            $post->id = $id;
        }

        $post->save();

        if ($request->boolean('notify')) {
            $this->notifyAudience($notifications, $club, $post, $member);
        }

        return response()->json(NotificationPresenter::post($post->load('author')), 201);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{id}",
     *   summary="Edit a club update (committee/admin). Accepts the same fields as create except notify.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="The updated post"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such post"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$member->hasRole(...self::MANAGER_ROLES)) {
            return $this->forbidden('Only the committee can edit club updates.');
        }

        $post = Post::where('club_id', $club->id)->find($id);

        if (!$post) {
            return $this->notFound('No such post.');
        }

        $validator = $this->makeValidator($request->all(), $this->rules(false));

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        foreach (['title' => 'title', 'bodyMd' => 'body_md', 'priority' => 'priority', 'audience' => 'audience'] as $key => $column) {
            if ($request->filled($key)) {
                $post->{$column} = $request->input($key);
            }
        }

        if ($request->has('pinnedUntil')) {
            $post->pinned_until = $request->input('pinnedUntil') ? Carbon::parse($request->input('pinnedUntil')) : null;
        }

        $post->save();

        return response()->json(NotificationPresenter::post($post->load('author')));
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{id}",
     *   summary="Soft-delete a club update (committee/admin). Safe to repeat.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=204, description="Deleted"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     * )
     */
    public function destroy(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$member->hasRole(...self::MANAGER_ROLES)) {
            return $this->forbidden('Only the committee can delete club updates.');
        }

        Post::where('club_id', $club->id)->find($id)?->delete();

        return response('', 204);
    }

    /** Inbox + push for the active members the post is meant for (not the author). */
    private function notifyAudience(NotificationService $notifications, $club, Post $post, ClubMember $author): void
    {
        $audience = ClubMember::where('club_id', $club->id)
            ->where('status', 'active')
            ->where('id', '!=', $author->id)
            ->get()
            ->filter(function (ClubMember $m) use ($post) {
                return in_array($post->audience, $m->audiences(), true);
            })
            ->pluck('id');

        $notifications->notifyMembers(
            $club,
            $audience,
            NotificationCategories::CLUB_UPDATES,
            $post->title,
            Str::limit(trim(preg_replace('/[\s#*_`>\[\]]+/', ' ', $post->body_md)), 140),
            ['route' => '/updates/' . $post->id],
            $post->priority === 'important'
        );
    }
}
