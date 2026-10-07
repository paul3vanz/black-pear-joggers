<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesGroups;
use App\Models\ClubMember;
use Illuminate\Http\Request;

/**
 * Committee tools: search members and manage their roles (Phase 4).
 * Never returns urn or date of birth.
 */
class AppMemberController extends Controller
{
    use ManagesGroups;

    const ROLES = ['leader', 'committee', 'admin'];
    const MAX = 50;

    private function item(ClubMember $member): array
    {
        return [
            'memberId' => $member->id,
            'displayName' => $member->display_name,
            'status' => $member->status,
            'roles' => array_values($member->roles ?? []),
        ];
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/members",
     *   summary="Search club members by name (committee/admin). Max 50.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="q", in="query", required=false, @OA\Schema(type="string")),
     *   @OA\Parameter(name="limit", in="query", required=false, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="{ items: [{ memberId, displayName, status, roles }] }"),
     *   @OA\Response(response=403, description="Not a committee member or admin"),
     * )
     */
    public function index(Request $request)
    {
        $club = $request->attributes->get('club');

        if (!$this->isManager($request->attributes->get('member'))) {
            return $this->forbidden('Only the committee can list members.');
        }

        $validator = $this->makeValidator($request->query(), [
            'q' => 'nullable|string|max:100',
            'limit' => 'nullable|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $limit = min(self::MAX, max(1, (int) $request->query('limit', self::MAX)));
        $query = ClubMember::where('club_id', $club->id);
        $q = trim((string) $request->query('q', ''));

        if ($q !== '') {
            $escaped = str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $q);
            $query->where('display_name', 'like', '%' . $escaped . '%');
        }

        return response()->json([
            'items' => $query->orderBy('display_name')->orderBy('id')->limit($limit)->get()
                ->map(function ($member) {
                    return $this->item($member);
                })->all(),
        ]);
    }

    /**
     * @OA\Patch(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/members/{memberId}/roles",
     *   summary="Replace a member's roles. Committee/admin manage leader; only admin manages committee and admin.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(required=true, @OA\JsonContent(@OA\Property(property="roles", type="array", @OA\Items(type="string")))),
     *   @OA\Response(response=200, description="The member item"),
     *   @OA\Response(response=403, description="Not allowed"),
     *   @OA\Response(response=404, description="No such member in this club"),
     *   @OA\Response(response=422, description="Unknown role"),
     * )
     */
    public function updateRoles(Request $request, $clubId, $memberId)
    {
        $club = $request->attributes->get('club');
        $caller = $request->attributes->get('member');

        if (!$this->isManager($caller)) {
            return $this->forbidden('Only the committee can change roles.');
        }

        $target = ClubMember::where('club_id', $club->id)->find($memberId);

        if (!$target) {
            return $this->notFound('No such member.');
        }

        $validator = $this->makeValidator($request->all(), [
            'roles' => 'present|array',
            'roles.*' => 'required|string|in:' . implode(',', self::ROLES),
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $new = array_values(array_unique($request->input('roles')));
        $old = $target->roles ?? [];
        $changed = array_merge(array_diff($new, $old), array_diff($old, $new));

        if (array_intersect($changed, ['committee', 'admin']) && !$caller->hasRole('admin')) {
            return $this->forbidden('Only an admin can grant or remove the committee and admin roles.');
        }

        // Keep a stable order: leader, committee, admin.
        $target->roles = array_values(array_intersect(self::ROLES, $new));
        $target->save();

        return response()->json($this->item($target->fresh()));
    }
}
