<?php

require_once __DIR__ . '/AppProfilesBase.php';

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\Device;
use App\Models\GroupMessage;
use App\Models\GroupThreadState;
use App\Models\MemberLinkAttempt;
use App\Models\MemberPhoto;
use App\Models\MemberPreference;
use App\Models\MemberProfile;
use App\Models\MemberSeriesPref;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\Post;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Services\AccountDeletion;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * DELETE /app/account (Phase 7b, decision D72).
 *
 * !! When you add a table that references club_members (member_id or similar),
 * !! add it to AccountDeletion::deleteMemberData() AND to populate() below.
 * !! testEveryTableThatReferencesAMemberIsCovered fails until you do both.
 */
class AppAccountDeletionTest extends AppProfilesBase
{
    private $victim;
    private $series;

    protected function setUp(): void
    {
        parent::setUp();

        $this->series = SessionSeries::create([
            'club_id' => 1, 'title' => 'Monday club run', 'weekday' => 1, 'start_time' => '19:00',
            'duration_min' => 90, 'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'group_mode' => 'paced',
        ]);
        $this->victim = $this->member('victim', 401, [], 'active', 'Vic');
    }

    private function del(?string $sub, ?array $body = ['confirm' => 'DELETE']): array
    {
        return $this->call_('DELETE', '/app/account', $sub, $body ?? []);
    }

    private function rowsFor(string $table, string $column, string $id): int
    {
        return DB::table($table)->where($column, $id)->count();
    }

    private function clubSession(int $clubId, ?ClubMember $coordinator = null, string $mode = 'paced', string $date = '2026-10-19'): ClubSession
    {
        return ClubSession::create([
            'club_id' => $clubId,
            'title' => 'Run',
            'group_mode' => $mode,
            'coordinator_member_id' => $coordinator ? $coordinator->id : null,
        ] + SessionGenerator::times($date, '19:00', 90, 'Europe/London'));
    }

    private function clubGroup(int $clubId, ClubSession $session, array $leaders = []): SessionGroup
    {
        $group = SessionGroup::create([
            'club_id' => $clubId, 'session_id' => $session->id, 'status' => $leaders ? 'active' : 'needs_leader',
        ]);

        foreach ($leaders as $leader) {
            SessionGroupLeader::create(['club_id' => $clubId, 'group_id' => $group->id, 'member_id' => $leader->id]);
        }

        return $group;
    }

    /**
     * Fills EVERY table that references a member, for this member.
     * Keep in step with AccountDeletion::deleteMemberData().
     */
    private function populate(ClubMember $m, string $sub, ClubSession $session, SessionGroup $group): void
    {
        $c = $m->club_id;

        MemberPreference::create(['club_id' => $c, 'member_id' => $m->id]);
        MemberSeriesPref::create(['club_id' => $c, 'member_id' => $m->id, 'series_id' => $this->series->id, 'reminders' => true]);
        NotificationPreference::create(['club_id' => $c, 'member_id' => $m->id, 'category' => 'club_updates', 'push_enabled' => false]);
        Notification::create(['club_id' => $c, 'member_id' => $m->id, 'category' => 'club_updates', 'title' => 't', 'body' => 'b']);
        MemberProfile::create(['club_id' => $c, 'member_id' => $m->id, 'bio' => 'About me']);
        MemberPhoto::create(['club_id' => $c, 'member_id' => $m->id, 'image' => $this->jpeg()]);

        $message = GroupMessage::create(['club_id' => $c, 'group_id' => $group->id, 'member_id' => $m->id, 'body' => 'hi']);
        $gone = GroupMessage::create(['club_id' => $c, 'group_id' => $group->id, 'member_id' => $m->id, 'body' => 'oops']);
        $gone->delete(); // soft-deleted rows still hold the foreign key
        GroupThreadState::create(['club_id' => $c, 'group_id' => $group->id, 'member_id' => $m->id, 'muted' => true]);

        SessionAttendee::firstOrCreate(['session_id' => $session->id, 'member_id' => $m->id], ['club_id' => $c, 'status' => 'going']);
        SessionGroupLeader::firstOrCreate(['group_id' => $group->id, 'member_id' => $m->id], ['club_id' => $c]);
        MemberLinkAttempt::create(['user_id' => $sub, 'club_id' => $c, 'success' => true]);

        // References that stay behind with a null.
        DB::table('sessions')->where('id', $session->id)->update(['coordinator_member_id' => $m->id]);
        DB::table('session_groups')->where('id', $group->id)->update(['created_by_member_id' => $m->id]);
        \App\Models\LeaderMessage::create(['club_id' => $c, 'session_id' => $session->id, 'member_id' => $m->id, 'body' => 'asking']);
        \App\Models\LeaderMessage::create(['club_id' => $c, 'session_id' => $session->id, 'member_id' => $m->id, 'body' => 'oops'])->delete(); // tombstones hold the key too
        \App\Models\LeaderThreadState::create(['club_id' => $c, 'session_id' => $session->id, 'member_id' => $m->id, 'muted' => true]);
        \App\Models\LeaderThreadMember::create(['club_id' => $c, 'session_id' => $session->id, 'member_id' => $m->id]);

        $post = Post::create(['club_id' => $c, 'author_member_id' => $m->id, 'title' => 'News', 'body_md' => 'x', 'published_at' => Carbon::now()]);
        \App\Models\PostReceipt::create(['club_id' => $c, 'post_id' => $post->id, 'member_id' => $m->id, 'delivered_at' => Carbon::now()]);
    }

    /** [table, column] pairs of every foreign key to club_members in the test schema. */
    private function memberReferences(): array
    {
        $pairs = [];

        foreach (DB::select("select name from sqlite_master where type = 'table' and name not like 'sqlite_%'") as $table) {
            foreach (DB::select('pragma foreign_key_list("' . $table->name . '")') as $fk) {
                if ($fk->table === 'club_members') {
                    $pairs[] = [$table->name, $fk->from];
                }
            }
        }

        return $pairs;
    }

    private function runsAsCommittee(ClubSession $session): array
    {
        return $this->api('GET', "/sessions/{$session->id}/plan", 'committee');
    }

    // ---- request rules -------------------------------------------------

    public function testUnauthenticatedIs401()
    {
        [$status] = $this->del(null);

        $this->assertSame(401, $status);
        $this->assertSame(1, ClubMember::where('id', $this->victim->id)->count());
    }

    public function testConfirmMissingOrWrongIs422AndChangesNothing()
    {
        Device::create(['user_id' => 'victim', 'token' => 'tok', 'platform' => 'android']);

        foreach ([[], ['confirm' => 'delete'], ['confirm' => 'yes'], ['confirm' => true], ['confirm' => ''], ['confirm' => ['DELETE']]] as $body) {
            [$status, $json] = $this->del('victim', $body);

            $this->assertSame(422, $status, json_encode($body));
            $this->assertSame('validation_failed', $json['error']);
            $this->assertArrayHasKey('confirm', $json['errors']);
        }

        $this->assertSame(1, ClubMember::where('id', $this->victim->id)->count());
        $this->assertSame(1, $this->rowsFor('member_logins', 'user_id', 'victim'));
        $this->assertSame(1, Device::where('user_id', 'victim')->count());
    }

    // ---- last admin ----------------------------------------------------

    public function testLastAdminIs409AndChangesNothing()
    {
        Device::create(['user_id' => 'admin', 'token' => 'tok-a', 'platform' => 'android']);

        [$status, $json] = $this->del('admin');

        $this->assertSame(409, $status);
        $this->assertSame('last_admin', $json['error']);
        $this->assertSame('Make someone else an admin first.', $json['message']);
        $this->assertSame(1, ClubMember::where('id', $this->admin->id)->count());
        $this->assertSame(1, $this->rowsFor('member_logins', 'user_id', 'admin'));
        $this->assertSame(1, Device::where('user_id', 'admin')->count());
    }

    public function testAnAdminMayDeleteWhenAnotherActiveAdminExists()
    {
        $this->member('admin2', 402, ['admin'], 'active', 'Ann');

        [$status] = $this->del('admin');

        $this->assertSame(204, $status);
        $this->assertSame(0, ClubMember::withTrashed()->where('id', $this->admin->id)->count());
    }

    public function testAnInactiveOrOtherClubAdminDoesNotCount()
    {
        $this->otherClub();
        $this->member('inactiveAdmin', 402, ['admin'], 'lapsed', 'Ian');
        ClubMember::create(['club_id' => 2, 'athlete_id' => 206, 'display_name' => 'Elsewhere', 'roles' => ['admin']]);

        [$status, $json] = $this->del('admin');

        $this->assertSame(409, $status);
        $this->assertSame('last_admin', $json['error']);
    }

    public function testBeingLastAdminOfAnyOneClubBlocks()
    {
        $this->otherClub();
        $second = ClubMember::create(['club_id' => 2, 'athlete_id' => 206, 'display_name' => 'Ada Two', 'roles' => ['admin']]);
        \App\Models\MemberLogin::create(['club_id' => 2, 'member_id' => $second->id, 'user_id' => 'admin', 'linked_at' => Carbon::now()]);
        $this->member('admin2', 402, ['admin'], 'active', 'Ann'); // club 1 has a spare admin, club 2 does not

        [$status, $json] = $this->del('admin');

        $this->assertSame(409, $status);
        $this->assertSame('last_admin', $json['error']);
    }

    // ---- full removal --------------------------------------------------

    public function testSingleLoginMemberIsFullyRemoved()
    {
        $coordinator = $this->coord;
        $session = $this->clubSession(1, $coordinator);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);
        Device::create(['user_id' => 'victim', 'token' => 'tok-v', 'platform' => 'android']);
        $id = $this->victim->id;

        [$status, $body] = $this->del('victim');

        $this->assertSame(204, $status);
        $this->assertSame('', (string) $this->response->getContent());

        foreach (['member_preferences', 'member_series_prefs', 'notification_preferences', 'notifications', 'member_profiles',
            'member_photos', 'post_receipts', 'leader_messages', 'leader_thread_states', 'leader_thread_members', 'group_messages', 'group_thread_states', 'session_attendees', 'session_group_leaders'] as $table) {
            $this->assertSame(0, $this->rowsFor($table, 'member_id', $id), $table);
        }

        $this->assertSame(0, ClubMember::withTrashed()->where('id', $id)->count());
        $this->assertSame(0, $this->rowsFor('member_logins', 'user_id', 'victim'));
        $this->assertSame(0, $this->rowsFor('member_link_attempts', 'user_id', 'victim'));
        $this->assertSame(0, Device::where('user_id', 'victim')->count());

        // Posts stay, with no author; the run keeps existing without a coordinator.
        $this->assertSame(1, Post::count());
        $this->assertNull(Post::first()->author_member_id);
        $this->assertNull(ClubSession::find($session->id)->coordinator_member_id);
        $this->assertNull(SessionGroup::find($group->id)->created_by_member_id);
    }

    public function testNullingTheCoordinatorAndAuthorBumpsUpdatedAt()
    {
        $session = $this->clubSession(1, $this->victim);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);
        $before = $this->sessionUpdatedAt($session);
        $postBefore = (string) Post::first()->getRawOriginal('updated_at');
        $this->tick(120);

        $this->del('victim');

        $this->assertNotSame($before, $this->sessionUpdatedAt($session));
        $this->assertNotSame($postBefore, (string) Post::first()->getRawOriginal('updated_at'));
    }

    public function testMemberWithTwoLoginsKeepsDataUntilTheSecondLoginDeletes()
    {
        $session = $this->clubSession(1);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);
        \App\Models\MemberLogin::create(['club_id' => 1, 'member_id' => $this->victim->id, 'user_id' => 'victim-phone2', 'linked_at' => Carbon::now()]);
        Device::create(['user_id' => 'victim', 'token' => 'tok-1', 'platform' => 'android']);
        Device::create(['user_id' => 'victim-phone2', 'token' => 'tok-2', 'platform' => 'ios']);
        $id = $this->victim->id;

        [$status] = $this->del('victim');

        $this->assertSame(204, $status);
        $this->assertSame(1, ClubMember::where('id', $id)->count());
        $this->assertSame(0, $this->rowsFor('member_logins', 'user_id', 'victim'));
        $this->assertSame(1, $this->rowsFor('member_logins', 'user_id', 'victim-phone2'));
        $this->assertSame(0, Device::where('user_id', 'victim')->count());
        $this->assertSame(1, Device::where('user_id', 'victim-phone2')->count());

        foreach (['member_preferences', 'member_series_prefs', 'notification_preferences', 'notifications', 'member_profiles',
            'member_photos', 'post_receipts', 'leader_thread_states', 'leader_thread_members', 'group_thread_states', 'session_attendees', 'session_group_leaders'] as $table) {
            $this->assertSame(1, $this->rowsFor($table, 'member_id', $id), $table);
        }
        $this->assertSame(2, $this->rowsFor('group_messages', 'member_id', $id));
        $this->assertSame(2, $this->rowsFor('leader_messages', 'member_id', $id));
        $this->assertSame($id, Post::first()->author_member_id);
        $this->assertSame('active', SessionGroup::find($group->id)->status);

        [$status] = $this->del('victim-phone2');

        $this->assertSame(204, $status);
        $this->assertSame(0, ClubMember::withTrashed()->where('id', $id)->count());
        $this->assertSame(0, $this->rowsFor('group_messages', 'member_id', $id));
        $this->assertSame(0, $this->rowsFor('leader_messages', 'member_id', $id));
        $this->assertSame(0, $this->rowsFor('session_attendees', 'member_id', $id));
        $this->assertSame(0, Device::count());
    }

    // ---- groups and sessions -------------------------------------------

    public function testGroupsThatLoseTheirLastLeaderNeedOneAndTheRunIsTouched()
    {
        $solo = $this->clubSession(1);
        $shared = $this->clubSession(1, null, 'paced', '2026-10-26');
        $soloGroup = $this->clubGroup(1, $solo, [$this->victim]);
        $sharedGroup = $this->clubGroup(1, $shared, [$this->victim, $this->leaderB]);
        $untouched = $this->clubSession(1, null, 'paced', '2026-11-02');
        $this->clubGroup(1, $untouched, [$this->leaderB]);
        $soloBefore = $this->sessionUpdatedAt($solo);
        $sharedBefore = $this->sessionUpdatedAt($shared);
        $untouchedBefore = $this->sessionUpdatedAt($untouched);
        $this->tick(120);

        $this->del('victim');

        $this->assertSame('needs_leader', SessionGroup::find($soloGroup->id)->status);
        $this->assertNotSame($soloBefore, $this->sessionUpdatedAt($solo));
        $this->assertSame('active', SessionGroup::find($sharedGroup->id)->status);
        $this->assertNotSame($sharedBefore, $this->sessionUpdatedAt($shared), 'the leader list changed');
        $this->assertSame($untouchedBefore, $this->sessionUpdatedAt($untouched));
        $this->assertSame(1, SessionGroupLeader::where('group_id', $sharedGroup->id)->count());
    }

    public function testAGroupThatAlreadyLostItsLeaderToAWithdrawalIsNotCountedAsLeading()
    {
        $session = $this->clubSession(1);
        $group = $this->clubGroup(1, $session, [$this->victim, $this->leaderB]);
        SessionGroupLeader::where('group_id', $group->id)->where('member_id', $this->leaderB->id)
            ->update(['status' => 'withdrawn']);

        $this->del('victim');

        $this->assertSame('needs_leader', SessionGroup::find($group->id)->status);
    }

    public function testRunsThatDoNotExpectLeadersKeepTheirGroupActive()
    {
        $session = $this->clubSession(1, null, 'open');
        $group = $this->clubGroup(1, $session, [$this->victim]);

        $this->del('victim');

        $this->assertSame('active', SessionGroup::find($group->id)->status);
        $this->assertSame(0, SessionGroupLeader::where('group_id', $group->id)->count());
    }

    public function testEventGroupsTheMemberAddedStayWithNoCreatorAndTheirAttendanceGoes()
    {
        $session = $this->clubSession(1, null, 'events');
        $group = SessionGroup::create([
            'club_id' => 1, 'session_id' => $session->id, 'kind' => 'event', 'label' => 'Worcester parkrun', 'status' => 'active',
            'created_by_member_id' => $this->victim->id,
        ]);
        $this->attend($session, $this->victim, 'going', $group);
        $this->attend($session, $this->plain, 'going', $group);
        $this->tick(120);
        $before = $this->sessionUpdatedAt($session);

        [$status] = $this->del('victim');

        $this->assertSame(204, $status);
        $kept = SessionGroup::find($group->id);
        $this->assertNotNull($kept, 'the event stays for the others');
        $this->assertNull($kept->created_by_member_id);
        $this->assertSame('active', $kept->status);
        $this->assertSame(1, SessionAttendee::where('group_id', $group->id)->count());
        $this->assertNotSame($before, $this->sessionUpdatedAt($session), 'its counts changed');
    }

    public function testNoNotificationIsWritten()
    {
        $session = $this->clubSession(1);
        $group = $this->clubGroup(1, $session, [$this->victim]);
        $this->attend($session, $this->plain, 'going', $group);
        $before = Notification::count();

        $this->del('victim');

        $this->assertSame($before, Notification::count());
    }

    public function testAttendanceCountsUpdateBecauseTheRowsAreGone()
    {
        $session = $this->clubSession(1, $this->coord);
        $this->attend($session, $this->victim, 'going');
        $this->attend($session, $this->plain, 'going');
        $this->attend($session, $this->leaderA, 'maybe');

        [, $before] = $this->runsAsCommittee($session);
        $this->assertSame(2, $before['unassigned']['goingCount']);

        $this->del('victim');

        [, $after] = $this->runsAsCommittee($session);
        $this->assertSame(1, $after['unassigned']['goingCount']);
        $this->assertSame(1, $after['unassigned']['maybeCount']);
    }

    // ---- scope ---------------------------------------------------------

    public function testOtherMembersAndOtherClubsAreUntouched()
    {
        $this->otherClub();
        $session = $this->clubSession(1);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);

        // A bystander in club 1 and a stranger in club 2, fully populated too.
        $session2 = $this->clubSession(2);
        $stranger = ClubMember::create(['club_id' => 2, 'athlete_id' => 450, 'display_name' => 'Stranger']);
        \App\Models\MemberLogin::create(['club_id' => 2, 'member_id' => $stranger->id, 'user_id' => 'stranger', 'linked_at' => Carbon::now()]);
        $group2 = $this->clubGroup(2, $session2, [$stranger]);
        DB::table('athletes')->insert(['id' => 450, 'urn' => 450, 'athlete_id' => 450, 'first_name' => 'S', 'last_name' => 'T', 'gender' => 'M', 'dob' => '1980-01-01']);
        $this->populate($stranger, 'stranger', $session2, $group2);
        $this->attend($session, $this->plain, 'going', $group);

        $this->del('victim');

        $this->assertSame(1, ClubMember::where('id', $stranger->id)->count());
        $this->assertSame(1, $this->rowsFor('member_logins', 'user_id', 'stranger'));
        $this->assertSame(1, $this->rowsFor('member_link_attempts', 'user_id', 'stranger'));
        $this->assertSame(1, $this->rowsFor('member_photos', 'member_id', $stranger->id));
        $this->assertSame(2, $this->rowsFor('group_messages', 'member_id', $stranger->id));
        $this->assertSame($stranger->id, ClubSession::find($session2->id)->coordinator_member_id);
        $this->assertSame('active', SessionGroup::find($group2->id)->status);
        $this->assertSame(1, Post::where('author_member_id', $stranger->id)->count());
        $this->assertSame(1, $this->rowsFor('session_attendees', 'member_id', $this->plain->id));
        $this->assertSame(1, ClubMember::where('id', $this->plain->id)->count());
        $this->assertSame(1, $this->rowsFor('member_logins', 'user_id', 'plain'));
    }

    public function testAMemberInTwoClubsIsRemovedFromBothAndOtherLinkAttemptsOfTheUserGo()
    {
        $this->otherClub();
        $session = $this->clubSession(1);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);

        $second = ClubMember::create(['club_id' => 2, 'athlete_id' => 401, 'display_name' => 'Vic Two']);
        \App\Models\MemberLogin::create(['club_id' => 2, 'member_id' => $second->id, 'user_id' => 'victim', 'linked_at' => Carbon::now()]);
        $session2 = $this->clubSession(2);
        $group2 = $this->clubGroup(2, $session2, [$second]);
        $this->populate($second, 'victim', $session2, $group2);
        MemberLinkAttempt::create(['user_id' => 'victim', 'club_id' => 1, 'success' => false]);

        [$status] = $this->del('victim');

        $this->assertSame(204, $status);
        $this->assertSame(0, ClubMember::withTrashed()->whereIn('id', [$this->victim->id, $second->id])->count());
        $this->assertSame(0, $this->rowsFor('member_link_attempts', 'user_id', 'victim'));
        $this->assertSame('needs_leader', SessionGroup::find($group2->id)->status);
        $this->assertSame('active', SessionGroup::find($group->id)->status);
    }

    public function testLeaderAndAttendeeInSeveralRunsAcrossTwoClubs()
    {
        $this->otherClub();
        $second = ClubMember::create(['club_id' => 2, 'athlete_id' => 401, 'display_name' => 'Vic Two']);
        \App\Models\MemberLogin::create(['club_id' => 2, 'member_id' => $second->id, 'user_id' => 'victim', 'linked_at' => Carbon::now()]);
        $other = ClubMember::create(['club_id' => 2, 'athlete_id' => 460, 'display_name' => 'Other leader']);
        DB::table('athletes')->insert(['id' => 460, 'urn' => 460, 'athlete_id' => 460, 'first_name' => 'O', 'last_name' => 'L', 'gender' => 'M', 'dob' => '1980-01-01']);

        $sole = [];
        $withOther = [];
        $dates = ['2026-10-19', '2026-10-26', '2026-11-02'];

        foreach ([1 => $this->victim, 2 => $second] as $clubId => $member) {
            foreach ($dates as $i => $date) {
                $session = $this->clubSession($clubId, null, 'paced', $date);
                $group = $this->clubGroup($clubId, $session, $i === 0 ? [$member] : [$member, $clubId === 1 ? $this->leaderB : $other]);
                $this->attend($session, $member, 'going', $group, ['club_id' => $clubId]);
                $i === 0 ? $sole[] = $group : $withOther[] = $group;
            }
        }

        [$status] = $this->del('victim');

        $this->assertSame(204, $status);
        $this->assertSame(0, SessionAttendee::whereIn('member_id', [$this->victim->id, $second->id])->count());
        $this->assertSame(0, SessionGroupLeader::whereIn('member_id', [$this->victim->id, $second->id])->count());

        foreach ($sole as $group) {
            $this->assertSame('needs_leader', SessionGroup::find($group->id)->status);
        }
        foreach ($withOther as $group) {
            $this->assertSame('active', SessionGroup::find($group->id)->status);
        }
    }

    // ---- devices, replay, no members -----------------------------------

    public function testUserWithOnlyDevicesIs204AndTheDevicesGo()
    {
        Device::create(['user_id' => 'ghost', 'token' => 'tok-g', 'platform' => 'android']);

        [$status] = $this->del('ghost');

        $this->assertSame(204, $status);
        $this->assertSame(0, Device::where('user_id', 'ghost')->count());
    }

    public function testReplayIs204()
    {
        $this->assertSame(204, $this->del('victim')[0]);
        $this->assertSame(204, $this->del('victim')[0]);
        $this->assertSame(0, ClubMember::withTrashed()->where('id', $this->victim->id)->count());
    }

    public function testTheWebsiteLoginAndAthleteAreUntouched()
    {
        DB::table('users')->insert(['id' => 'victim', 'athleteId' => 401]);
        $this->registerAthlete(1000401);

        $this->del('victim');

        $this->assertSame(401, (int) DB::table('users')->where('id', 'victim')->value('athleteId'));
        $this->assertSame(1, DB::table('athletes')->where('id', 401)->count());
        $this->assertSame(1, DB::table('memberships')->where('urn', 1000401)->count());
    }

    public function testASoftDeletedMemberIsRemovedForGood()
    {
        $session = $this->clubSession(1);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);
        $this->victim->delete(); // tombstoned member, login still there

        [$status] = $this->del('victim');

        $this->assertSame(204, $status);
        $this->assertSame(0, ClubMember::withTrashed()->where('id', $this->victim->id)->count());
    }

    public function testTheServiceReportsWhoWasRemoved()
    {
        $removed = app(AccountDeletion::class)->delete('victim');

        $this->assertSame([['memberId' => $this->victim->id, 'clubId' => 1]], $removed);
        $this->assertSame([], app(AccountDeletion::class)->delete('victim'));
    }

    // ---- safety net ----------------------------------------------------

    /**
     * Walks every foreign key to club_members in the schema (so a table added
     * later is found automatically), checks populate() fills it, then checks a
     * deletion leaves no row pointing at the member. If this fails after you
     * added a table: extend AccountDeletion::deleteMemberData() and populate().
     */
    public function testEveryTableThatReferencesAMemberIsCovered()
    {
        $session = $this->clubSession(1, $this->victim);
        $group = $this->clubGroup(1, $session, [$this->leaderB]);
        $this->populate($this->victim, 'victim', $session, $group);
        $id = $this->victim->id;
        $pairs = $this->memberReferences();

        $this->assertNotEmpty($pairs);
        $tables = array_column($pairs, 0);
        $this->assertContains('member_logins', $tables);
        $this->assertContains('posts', $tables);

        foreach ($pairs as [$table, $column]) {
            if ($table === 'member_logins') {
                continue; // the login is populated by member() and removed first
            }
            $this->assertGreaterThan(0, $this->rowsFor($table, $column, $id), "populate() does not fill $table.$column: add it, and to AccountDeletion");
        }

        [$status] = $this->del('victim');
        $this->assertSame(204, $status, 'a foreign key probably blocked the delete: ' . $this->response->getContent());

        foreach ($pairs as [$table, $column]) {
            $this->assertSame(0, $this->rowsFor($table, $column, $id), "$table.$column still points at the deleted member");
        }
        $this->assertSame(0, ClubMember::withTrashed()->where('id', $id)->count());
    }
}
