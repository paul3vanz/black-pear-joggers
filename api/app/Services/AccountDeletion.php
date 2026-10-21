<?php

namespace App\Services;

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\Device;
use App\Models\MemberLogin;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * "Delete my account" (Phase 7b, decision D72): removes what the app holds for a
 * signed-in Auth0 user. The website login, the athlete and the membership
 * records (users.athleteId included) are never touched.
 *
 * !! Any NEW table that has a member_id (or another reference to club_members)
 * !! must be added to deleteMemberData() below AND to the list in
 * !! tests/AppAccountDeletionTest.php, or deletion will fail on the foreign key
 * !! (MySQL) or leave personal data behind.
 *
 * The queries use the query builder on purpose: soft-deleted rows (messages,
 * members) still hold foreign keys and personal data, so they must really go.
 */
class AccountDeletion
{
    /**
     * Club ids where this user's member is an admin and no other active member of
     * that club is: deleting would leave the club without an admin.
     *
     * @return int[]
     */
    public function lastAdminClubIds(string $userId): array
    {
        $memberIds = MemberLogin::where('user_id', $userId)->pluck('member_id');
        $clubIds = [];

        // Soft-deleted members are skipped by the model's default scope.
        foreach (ClubMember::whereIn('id', $memberIds)->get() as $member) {
            if (!$member->hasRole('admin')) {
                continue;
            }

            $otherAdmin = ClubMember::where('club_id', $member->club_id)
                ->where('id', '!=', $member->id)
                ->where('status', 'active')
                ->get()
                ->contains(fn (ClubMember $other) => $other->hasRole('admin'));

            if (!$otherAdmin) {
                $clubIds[] = (int) $member->club_id;
            }
        }

        return $clubIds;
    }

    /**
     * Unlinks the login, removes its devices, and fully removes every member that
     * has no login left. One transaction. Safe to repeat (nothing left to do).
     *
     * @return array<int, array{memberId: string, clubId: int}> the members removed
     */
    public function delete(string $userId): array
    {
        $removed = DB::transaction(function () use ($userId) {
            $memberIds = DB::table('member_logins')->where('user_id', $userId)->pluck('member_id')->all();

            Device::where('user_id', $userId)->delete();
            DB::table('member_logins')->where('user_id', $userId)->delete();

            if (!$memberIds) {
                return [];
            }

            $stillLinked = DB::table('member_logins')->whereIn('member_id', $memberIds)->pluck('member_id')->all();
            $orphans = array_values(array_diff($memberIds, $stillLinked));
            $removed = [];

            foreach ($orphans as $memberId) {
                $clubId = DB::table('club_members')->where('id', $memberId)->value('club_id');

                if ($clubId === null) {
                    continue;
                }

                $this->deleteMemberData($memberId);
                DB::table('member_link_attempts')->where('user_id', $userId)->where('club_id', $clubId)->delete();

                $removed[] = ['memberId' => $memberId, 'clubId' => (int) $clubId];
            }

            return $removed;
        });

        // Ids only, no names or emails. After the commit, so a failing log sink must not turn a done delete into a 500.
        foreach ($removed as $row) {
            try {
                Log::info('Account deletion: removed member ' . $row['memberId'] . ' of club ' . $row['clubId']);
            } catch (\Throwable $e) {
                // ignore
            }
        }

        return $removed;
    }

    /** Deletes one member's data in foreign-key-safe order, then the member row. */
    private function deleteMemberData(string $memberId): void
    {
        $now = Carbon::now();

        // Chat, including soft-deleted messages.
        DB::table('group_messages')->where('member_id', $memberId)->delete();
        DB::table('group_thread_states')->where('member_id', $memberId)->delete();

        // The leaders threads (messages, including soft-deleted ones, read markers, asks they received).
        DB::table('leader_messages')->where('member_id', $memberId)->delete();
        DB::table('leader_thread_states')->where('member_id', $memberId)->delete();
        DB::table('leader_thread_members')->where('member_id', $memberId)->delete();

        // What they had and read of club updates.
        DB::table('post_receipts')->where('member_id', $memberId)->delete();

        // Runs whose counts or leader lists change (their ?since= feed must see it).
        $sessionIds = DB::table('session_attendees')->where('member_id', $memberId)->pluck('session_id')->all();
        DB::table('session_attendees')->where('member_id', $memberId)->delete();

        $groupIds = DB::table('session_group_leaders')
            ->where('member_id', $memberId)
            ->where('status', SessionGroupLeader::CONFIRMED)
            ->pluck('group_id')
            ->all();
        DB::table('session_group_leaders')->where('member_id', $memberId)->delete();

        // A group that lost its last confirmed leader needs one (no notification is sent).
        foreach (SessionGroup::with('session')->whereIn('id', $groupIds)->get() as $group) {
            $session = $group->session;

            if (!$session || $session->trashed()) {
                continue;
            }

            $remaining = SessionGroupLeader::where('group_id', $group->id)
                ->where('status', SessionGroupLeader::CONFIRMED)
                ->count();

            if ($remaining === 0 && $session->expectsLeaders()) {
                $group->status = SessionGroup::STATUS_NEEDS_LEADER;
                $group->save();
            }

            $sessionIds[] = $session->id;
        }

        // Preferences, inbox, profile.
        DB::table('member_preferences')->where('member_id', $memberId)->delete();
        DB::table('member_series_prefs')->where('member_id', $memberId)->delete();
        DB::table('notification_preferences')->where('member_id', $memberId)->delete();
        DB::table('notifications')->where('member_id', $memberId)->delete();
        DB::table('member_photos')->where('member_id', $memberId)->delete();
        DB::table('member_profiles')->where('member_id', $memberId)->delete();

        // References that stay behind without the member.
        $coordinated = DB::table('sessions')->where('coordinator_member_id', $memberId)->pluck('id')->all();
        DB::table('sessions')->where('coordinator_member_id', $memberId)
            ->update(['coordinator_member_id' => null, 'updated_at' => $now]);
        DB::table('session_groups')->where('created_by_member_id', $memberId)
            ->update(['created_by_member_id' => null]);
        DB::table('posts')->where('author_member_id', $memberId)
            ->update(['author_member_id' => null, 'updated_at' => $now]);

        foreach (ClubSession::whereIn('id', array_unique(array_diff($sessionIds, $coordinated)))->get() as $session) {
            $session->touchForChange();
        }

        // The member row itself (soft-deleted or not).
        DB::table('club_members')->where('id', $memberId)->delete();
    }
}
