<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\ClubMember;
use App\Models\ContentReport;
use App\Models\GroupMessage;
use App\Models\LeaderMessage;
use App\Models\MemberBlock;
use App\Models\PostComment;
use App\Services\NotificationCategories;
use App\Services\NotificationPresenter;
use App\Services\NotificationService;
use App\Services\RunNotifier;
use App\Services\RunText;
use App\Services\ThreadAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Report and block (Apple guideline 1.2). Reports go to the committee's inbox;
 * blocks are personal and the app does the hiding. Contract: mobile/docs/api-contract.md.
 */
class AppSafetyController extends Controller
{
    use AppResponses;

    /** Reports one member may send per hour. */
    const REPORT_LIMIT = 10;

    const EXCERPT_MAX = 500;

    /** Display name (first name + initial) of members, keyed by member id. */
    private function names(array $memberIds): array
    {
        if (!$memberIds) {
            return [];
        }

        $rows = DB::table('club_members')
            ->leftJoin('athletes', 'athletes.id', '=', 'club_members.athlete_id')
            ->whereIn('club_members.id', $memberIds)
            ->get(['club_members.id as id', 'athletes.first_name as first', 'athletes.last_name as last']);

        $names = [];
        foreach ($rows as $row) {
            $names[$row->id] = ThreadAccess::shortName($row->first, $row->last);
        }

        return $names;
    }

    private function block(MemberBlock $block, array $names): array
    {
        return [
            'memberId' => $block->blocked_member_id,
            'name' => $names[$block->blocked_member_id] ?? 'Member',
            'createdAt' => NotificationPresenter::time($block->created_at),
        ];
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/blocks",
     *   summary="The members the caller has blocked.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ items: [{ memberId, name, createdAt }] }"),
     * )
     */
    public function index(Request $request, $clubId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $blocks = MemberBlock::where('club_id', $club->id)->where('blocker_member_id', $member->id)
            ->orderBy('created_at')->get();
        $names = $this->names($blocks->pluck('blocked_member_id')->all());

        return response()->json(['items' => $blocks->map(fn ($b) => $this->block($b, $names))->all()]);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/blocks",
     *   summary="Block a member: their messages and profile card are hidden from the caller. Idempotent.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(@OA\JsonContent(@OA\Property(property="memberId", type="string", format="uuid"))),
     *   @OA\Response(response=201, description="{ memberId, name, createdAt } (200 if already blocked)"),
     *   @OA\Response(response=404, description="No such member in this club"),
     *   @OA\Response(response=422, description="Cannot block yourself"),
     * )
     */
    public function store(Request $request, $clubId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $targetId = $request->input('memberId');

        if (!is_string($targetId) || $targetId === '') {
            return $this->validationFailed($this->makeValidator(['memberId' => null], ['memberId' => 'required']));
        }

        if ($targetId === $member->id) {
            return response()->json(['error' => 'validation_failed', 'message' => 'You cannot block yourself.'], 422);
        }

        $target = ClubMember::where('club_id', $club->id)->find($targetId);

        if (!$target) {
            return $this->notFound('No such member.');
        }

        $block = MemberBlock::firstOrCreate(
            ['blocker_member_id' => $member->id, 'blocked_member_id' => $target->id],
            ['club_id' => $club->id]
        );

        return response()->json($this->block($block, $this->names([$target->id])), $block->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/blocks/{memberId}",
     *   summary="Unblock a member. Idempotent.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Unblocked"),
     * )
     */
    public function destroy(Request $request, $clubId, $memberId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        MemberBlock::where('club_id', $club->id)
            ->where('blocker_member_id', $member->id)
            ->where('blocked_member_id', $memberId)
            ->delete();

        return response('', 204);
    }

    /**
     * @OA\Post(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/reports",
     *   summary="Report a message, comment or profile card to the committee. 10 per hour per member.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(@OA\JsonContent(
     *     @OA\Property(property="kind", type="string", enum={"message","leader_message","comment","profile"}),
     *     @OA\Property(property="targetId", type="string", format="uuid", description="The message or comment id; omit for a profile"),
     *     @OA\Property(property="reportedMemberId", type="string", format="uuid"),
     *     @OA\Property(property="reason", type="string", enum={"spam","abusive","inappropriate","other"}),
     *     @OA\Property(property="details", type="string", maxLength=500),
     *   )),
     *   @OA\Response(response=201, description="{ id }"),
     *   @OA\Response(response=404, description="No such member or content"),
     *   @OA\Response(response=422, description="Validation error"),
     *   @OA\Response(response=429, description="too_many_requests"),
     * )
     */
    public function report(Request $request, $clubId)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $details = $request->input('details');

        $validator = $this->makeValidator([
            'kind' => $request->input('kind'),
            'targetId' => $request->input('targetId'),
            'reportedMemberId' => $request->input('reportedMemberId'),
            'reason' => $request->input('reason'),
            'details' => is_string($details) ? trim($details) : $details,
        ], [
            'kind' => 'required|in:' . implode(',', ContentReport::KINDS),
            'targetId' => 'nullable|uuid',
            'reportedMemberId' => 'required|string',
            'reason' => 'required|in:' . implode(',', ContentReport::REASONS),
            'details' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $kind = $request->input('kind');
        $targetId = $request->input('targetId');

        if ($kind !== 'profile' && !$targetId) {
            return response()->json(['error' => 'validation_failed', 'message' => 'Say which message you are reporting.'], 422);
        }

        if ($request->input('reportedMemberId') === $member->id) {
            return response()->json(['error' => 'validation_failed', 'message' => 'You cannot report yourself.'], 422);
        }

        $reported = ClubMember::where('club_id', $club->id)->find($request->input('reportedMemberId'));

        if (!$reported) {
            return $this->notFound('No such member.');
        }

        $recent = ContentReport::where('reporter_member_id', $member->id)
            ->where('created_at', '>=', Carbon::now()->subHour())->count();

        if ($recent >= self::REPORT_LIMIT) {
            return response()->json(['error' => 'too_many_requests', 'message' => 'You have sent a lot of reports. Please try again later.'], 429);
        }

        $excerpt = null;
        $route = null;

        if ($kind !== 'profile') {
            $found = $this->content($kind, $club->id, $reported->id, $targetId);

            if (!$found) {
                return $this->notFound('No such message.');
            }

            [$excerpt, $route] = $found;
        }

        $report = ContentReport::create([
            'club_id' => $club->id,
            'reporter_member_id' => $member->id,
            'reported_member_id' => $reported->id,
            'kind' => $kind,
            'target_id' => $kind === 'profile' ? null : $targetId,
            'reason' => $request->input('reason'),
            'details' => $details !== null && $details !== '' ? $details : null,
            'excerpt' => $excerpt,
        ]);

        $this->tellCommittee($club, $report, $member, $reported, $route);

        return response()->json(['id' => $report->id], 201);
    }

    /**
     * The text and app route of a reported message that was written by $authorId,
     * or null when there is no such message in this club.
     *
     * @return array{0: string, 1: ?string}|null
     */
    private function content(string $kind, int $clubId, string $authorId, string $id): ?array
    {
        if ($kind === 'message') {
            $row = GroupMessage::withTrashed()->where('club_id', $clubId)->where('member_id', $authorId)->find($id);
            $group = $row ? DB::table('session_groups')->where('id', $row->group_id)->first(['id', 'session_id']) : null;
            $route = $group ? "/runs/{$group->session_id}/groups/{$group->id}/chat" : null;
        } elseif ($kind === 'leader_message') {
            $row = LeaderMessage::withTrashed()->where('club_id', $clubId)->where('member_id', $authorId)->find($id);
            $route = $row ? "/runs/{$row->session_id}/leaders-chat" : null;
        } else {
            $row = PostComment::withTrashed()->where('club_id', $clubId)->where('member_id', $authorId)->find($id);
            $route = $row ? "/updates/{$row->post_id}/comments" : null;
        }

        return $row ? [RunText::clip((string) $row->body, self::EXCERPT_MAX), $route] : null;
    }

    /** Puts a line in the inbox of every other committee member and admin. Never fails the report. */
    private function tellCommittee($club, ContentReport $report, ClubMember $reporter, ClubMember $reported, ?string $route): void
    {
        app(RunNotifier::class)->guard('content report', function () use ($club, $report, $reporter, $reported, $route) {
            $managers = ClubMember::where('club_id', $club->id)->where('status', 'active')->get()
                ->filter(fn (ClubMember $m) => $m->hasRole('committee', 'admin'))
                ->pluck('id')->all();
            $ids = app(RunNotifier::class)->activeIds($club, $managers, $reporter->id);

            if (!$ids) {
                return;
            }

            $name = $this->names([$reported->id])[$reported->id] ?? 'a member';
            $what = $report->kind === 'profile' ? "the profile card of $name" : "a message from $name";
            $body = ucfirst($what) . ' was reported as ' . $report->reason . '.'
                . ($report->excerpt ? ' "' . RunText::clip($report->excerpt, 120) . '"' : '');

            app(NotificationService::class)->notifyMembers(
                $club,
                $ids,
                NotificationCategories::CLUB_UPDATES,
                'Content reported',
                $body,
                $route ? ['route' => $route, 'reportId' => $report->id] : ['reportId' => $report->id],
                true,
                ['dedupeKey' => 'report:' . $report->id]
            );
        });
    }
}
