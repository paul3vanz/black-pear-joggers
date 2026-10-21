<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\ClubMember;
use App\Models\Notification;
use App\Models\Post;
use App\Models\PostReceipt;
use App\Services\NotificationPresenter;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Delivered / read receipts for club updates (D123). The app reports them for
 * the caller's own copy; only the committee can read them back.
 *
 * "Delivered" is the earlier of: the app saying the update is on the device,
 * and the push for it being accepted by Firebase (`notifications.pushed_at`,
 * found through the `post:<id>` dedupe key). "Read" is the app saying the
 * member opened the update and read it to the end, and implies delivered.
 */
class AppPostReceiptController extends Controller
{
    use AppResponses;

    const MAX_ITEMS = 100;

    const STATES = ['delivered', 'read'];

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/receipts",
     *   summary="Report the caller's own delivered / read state for club updates. Idempotent and never goes backwards. Posts the caller can't see, or wrote, are ignored.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"items"},
     *       @OA\Property(property="items", type="array", maxItems=100, @OA\Items(
     *         required={"postId","state"},
     *         @OA\Property(property="postId", type="string", format="uuid"),
     *         @OA\Property(property="state", type="string", enum={"delivered","read"}),
     *         @OA\Property(property="at", type="string", format="date-time", description="When it happened on the device (defaults to now, never in the future)"),
     *       )),
     *     )
     *   ),
     *   @OA\Response(response=204, description="Recorded"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function report(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        $validator = $this->makeValidator($request->all(), [
            'items' => 'required|array|max:' . self::MAX_ITEMS,
            'items.*.postId' => 'required|uuid',
            'items.*.state' => 'required|in:' . implode(',', self::STATES),
            'items.*.at' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $now = Carbon::now();
        $items = $request->input('items');
        $posts = Post::where('club_id', $club->id)
            ->whereIn('id', array_column($items, 'postId'))
            ->whereIn('audience', $member->audiences())
            ->where(function ($q) use ($member) {
                $q->whereNull('author_member_id')->orWhere('author_member_id', '!=', $member->id);
            })
            ->get()
            ->keyBy('id');

        foreach ($items as $item) {
            if (!$posts->has($item['postId'])) {
                continue;
            }

            $at = isset($item['at']) ? Carbon::parse($item['at']) : $now;
            // A device clock that runs ahead must not put a time in the future.
            $at = $at->greaterThan($now) ? $now : $at;

            $receipt = PostReceipt::firstOrNew(['post_id' => $item['postId'], 'member_id' => $member->id]);
            $receipt->club_id = $club->id;

            if ($receipt->delivered_at === null || $at->lessThan($receipt->delivered_at)) {
                $receipt->delivered_at = $at;
            }

            if ($item['state'] === 'read' && $receipt->read_at === null) {
                $receipt->read_at = $at;
            }

            $receipt->save();
        }

        return response('', 204);
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/posts/{id}/receipts",
     *   summary="Who has had and read an update (committee/admin). Counts and every member the update was for (not its author), with their state.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="string", format="uuid")),
     *   @OA\Response(response=200, description="{ postId, audienceCount, deliveredCount, readCount, members: [{ memberId, displayName, state: none|delivered|read, deliveredAt, readAt }] } (deliveredCount includes read)"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     *   @OA\Response(response=404, description="No such post"),
     * )
     */
    public function show(Request $request, $clubId, $id)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        if (!$member->hasRole(...AppPostController::MANAGER_ROLES)) {
            return $this->forbidden('Only the committee can see who has read an update.');
        }

        $post = Post::where('club_id', $club->id)->find($id);

        if (!$post) {
            return $this->notFound('No such post.');
        }

        $receipts = PostReceipt::where('post_id', $post->id)->get()->keyBy('member_id');
        $pushed = Notification::where('club_id', $club->id)
            ->where('dedupe_key', 'post:' . $post->id)
            ->whereNotNull('pushed_at')
            ->get()
            ->keyBy('member_id');

        $rows = ClubMember::where('club_id', $club->id)
            ->where('status', 'active')
            ->where('id', '!=', $post->author_member_id ?? '')
            ->get()
            ->filter(fn (ClubMember $m) => in_array($post->audience, $m->audiences(), true))
            ->map(function (ClubMember $m) use ($receipts, $pushed) {
                $receipt = $receipts->get($m->id);
                $delivered = collect([$receipt?->delivered_at, $pushed->get($m->id)?->pushed_at])
                    ->filter()
                    ->sort()
                    ->first();
                $read = $receipt?->read_at;
                // A read update was delivered, whatever else was reported.
                $delivered = $delivered ?? $read;

                return [
                    'memberId' => $m->id,
                    'displayName' => $m->display_name,
                    'state' => $read ? 'read' : ($delivered ? 'delivered' : 'none'),
                    'deliveredAt' => $delivered ? NotificationPresenter::time($delivered) : null,
                    'readAt' => $read ? NotificationPresenter::time($read) : null,
                ];
            })
            ->sortBy(fn ($row) => mb_strtolower((string) $row['displayName']))
            ->values();

        return response()->json([
            'postId' => $post->id,
            'audienceCount' => $rows->count(),
            'deliveredCount' => $rows->where('state', '!=', 'none')->count(),
            'readCount' => $rows->where('state', 'read')->count(),
            'members' => $rows->all(),
        ]);
    }
}
