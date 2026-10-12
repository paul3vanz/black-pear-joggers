<?php

require_once __DIR__ . '/AppProfilesBase.php';

use App\Models\ClubMember;
use App\Models\MemberLogin;
use App\Models\MemberPhoto;
use App\Models\MemberProfile;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Phase 6.5a: another member's profile, the committee clear, and the member-cards list.
 * Default roles: leaderB leader, committee committee, admin admin; plain, leaderA and
 * coord have none. "Now" is 2026-10-12 09:00 UTC.
 */
class AppMemberCardsTest extends AppProfilesBase
{
    private function profileOf(ClubMember $m, ?string $sub = 'plain'): array
    {
        return $this->api('GET', "/members/{$m->id}/profile", $sub);
    }

    private function cards(?string $sub = 'plain'): array
    {
        return $this->api('GET', '/member-cards', $sub);
    }

    private function cardIds(?string $sub = 'plain'): array
    {
        return array_column($this->cards($sub)[1]['items'], 'memberId');
    }

    /** A run with no coordinator, $days from today (negative = past). */
    private function runOn(int $days, array $extra = [])
    {
        return $this->session($extra + ['date' => Carbon::now()->addDays($days)->format('Y-m-d'), 'coordinator_member_id' => null]);
    }

    // ---- other member's profile ------------------------------------------------------

    public function testShowsTheVisibleFieldsOnly()
    {
        $this->api('PUT', '/member-profile', 'leaderA', ['bio' => 'Hello there', 'goals' => 'Secret goal']);
        [, $card] = $this->upload('leaderA', $this->jpeg());

        [$status, $body] = $this->profileOf($this->leaderA);

        $this->assertSame(200, $status);
        $this->assertSame(
            ['bio', 'displayName', 'goals', 'isYou', 'memberId', 'photoPath', 'roles'],
            collect(array_keys($body))->sort()->values()->all()
        );
        $this->assertSame($this->leaderA->id, $body['memberId']);
        $this->assertSame('Lee L.', $body['displayName'], 'first name and surname initial, like chat');
        $this->assertSame('Hello there', $body['bio']);
        $this->assertSame($card['photoPath'], $body['photoPath']);
        $this->assertFalse($body['isYou']);
        $this->assertNull($body['goals'], 'goals are private unless shared');
        $this->assertSame([], $body['roles']);
    }

    public function testGoalsAreShownOnlyWhenSharedOrYourOwn()
    {
        $this->api('PUT', '/member-profile', 'leaderA', ['goals' => 'Run a marathon', 'goalsVisible' => false]);

        $this->assertNull($this->profileOf($this->leaderA)[1]['goals']);
        $own = $this->profileOf($this->leaderA, 'leaderA')[1];
        $this->assertSame('Run a marathon', $own['goals'], 'you always see your own');
        $this->assertTrue($own['isYou']);

        $this->api('PUT', '/member-profile', 'leaderA', ['goalsVisible' => true]);
        $this->assertSame('Run a marathon', $this->profileOf($this->leaderA)[1]['goals']);
        $this->assertSame('Run a marathon', $this->profileOf($this->leaderA, 'committee')[1]['goals']);

        $this->api('PUT', '/member-profile', 'leaderA', ['goalsVisible' => false]);
        $this->assertNull($this->profileOf($this->leaderA)[1]['goals']);
        $this->assertNull($this->profileOf($this->leaderA, 'committee')[1]['goals'], 'committee do not see private goals either');
    }

    public function testAMemberWithNothingSavedGetsNullsAndNoRowIsCreated()
    {
        [$status, $body] = $this->profileOf($this->coord);

        $this->assertSame(200, $status);
        $this->assertNull($body['bio']);
        $this->assertNull($body['goals']);
        $this->assertNull($body['photoPath']);
        $this->assertSame('Cory L.', $body['displayName']);
        $this->assertSame(0, MemberProfile::count());
    }

    public function testRolesListOnlyLeaderCommitteeAndAdminInThatOrder()
    {
        $multi = $this->member('multi', 301, ['admin', 'bogus', 'leader', 'committee'], 'active', 'Max');
        $this->assertSame(['leader', 'committee', 'admin'], $this->profileOf($multi)[1]['roles']);
        $this->assertSame(['leader'], $this->profileOf($this->leaderB)[1]['roles']);
        $this->assertSame(['admin'], $this->profileOf($this->admin)[1]['roles']);
    }

    public function testNameFallsBackToMemberWhenThereIsNoAthlete()
    {
        $ghost = ClubMember::create(['club_id' => 1, 'athlete_id' => 99999, 'display_name' => 'Real Name', 'roles' => [], 'status' => 'active']);

        $this->assertSame('Member', $this->profileOf($ghost)[1]['displayName']);
    }

    public function testOnlyActiveMembersOfThisClubAreVisible()
    {
        $lapsed = $this->member('lapsed', 302, [], 'lapsed');
        $this->seedProfile($lapsed, ['bio' => 'Hidden']);
        [$status, $body] = $this->profileOf($lapsed);
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);

        $gone = $this->member('gone', 303);
        $gone->delete();
        $this->assertSame(404, $this->profileOf($gone)[0]);

        $this->otherClub();
        $foreign = ClubMember::create(['club_id' => 2, 'athlete_id' => 304, 'display_name' => 'Far Away', 'roles' => ['admin']]);
        $this->assertSame(404, $this->profileOf($foreign)[0]);

        [$status] = $this->api('GET', '/members/' . $this->uuid() . '/profile', 'plain');
        $this->assertSame(404, $status);
        [$status] = $this->api('GET', '/members/not-a-uuid/profile', 'plain');
        $this->assertSame(404, $status);
    }

    public function testAnInactiveCallerStillLinkedMayLookButNeedsAClubLink()
    {
        $lapsed = $this->member('lapsed', 302, [], 'lapsed');
        $this->assertSame(200, $this->profileOf($this->leaderA, 'lapsed')[0]);

        [$status] = $this->profileOf($this->leaderA, null);
        $this->assertSame(401, $status);

        [$status, $body] = $this->profileOf($this->leaderA, 'unlinked');
        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);
    }

    public function testNoPersonalDataBeyondTheCardIsExposed()
    {
        $this->api('PUT', '/member-profile', 'leaderA', ['bio' => 'Hi']);
        $this->profileOf($this->leaderA);
        $json = $this->response->getContent();

        foreach (['urn', 'dob', 'email', 'pace', 'athlete_id', '1000202', '1980-01-01', 'Last202'] as $leak) {
            $this->assertStringNotContainsString($leak, $json);
        }
    }

    // ---- committee clear -------------------------------------------------------------

    private function fullCard(string $sub, ClubMember $m): void
    {
        $this->api('PUT', '/member-profile', $sub, ['bio' => 'Bio', 'goals' => 'Goals', 'goalsVisible' => true]);
        $this->upload($sub, $this->jpeg());
    }

    public function testOnlyCommitteeOrAdminMayClear()
    {
        $this->fullCard('plain', $this->plain);

        foreach (['plain', 'leaderA', 'leaderB', 'coord'] as $sub) {
            [$status, $body] = $this->api('DELETE', "/members/{$this->plain->id}/profile", $sub);
            $this->assertSame(403, $status, $sub);
            $this->assertSame('forbidden', $body['error']);
        }

        $this->assertSame('Bio', $this->profile($this->plain)->bio, 'nothing was cleared');
        $this->assertSame(1, MemberPhoto::count());

        [$status] = $this->api('DELETE', "/members/{$this->plain->id}/profile", null);
        $this->assertSame(401, $status);
    }

    public function testClearingRemovesPhotoBioAndGoalsAndHidesGoals()
    {
        $this->fullCard('plain', $this->plain);
        $this->fullCard('leaderA', $this->leaderA);
        $before = $this->profile($this->plain)->updated_at;
        $this->tick(300);

        [$status, $content] = $this->call_('DELETE', "/app/clubs/1/members/{$this->plain->id}/profile", 'committee');
        $this->assertSame(204, $status);
        $this->assertSame('', $this->response->getContent());

        $row = $this->profile($this->plain);
        $this->assertNull($row->bio);
        $this->assertNull($row->goals);
        $this->assertFalse((bool) $row->goals_visible);
        $this->assertNull($row->photo_version);
        $this->assertNull($row->photo_updated_at);
        $this->assertTrue($row->updated_at->gt($before), 'a write bumps updated_at');
        $this->assertSame(0, MemberPhoto::where('member_id', $this->plain->id)->count(), 'the blob is deleted');

        // Others are untouched, and the member can add content again.
        $this->assertSame('Bio', $this->profile($this->leaderA)->bio);
        $this->assertSame(1, MemberPhoto::count());
        $card = $this->api('GET', '/member-profile', 'plain')[1];
        $this->assertSame([null, null, false, null], [$card['bio'], $card['goals'], $card['goalsVisible'], $card['photoPath']]);
        $this->assertSame('Again', $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Again'])[1]['bio']);
        $this->assertSame(200, $this->upload('plain', $this->jpeg())[0]);
    }

    public function testAdminMayClearToo()
    {
        $this->fullCard('plain', $this->plain);

        $this->assertSame(204, $this->api('DELETE', "/members/{$this->plain->id}/profile", 'admin')[0]);
        $this->assertNull($this->profile($this->plain)->bio);
    }

    public function testClearingIsIdempotentAndCreatesNoRow()
    {
        $this->assertSame(204, $this->api('DELETE', "/members/{$this->plain->id}/profile", 'committee')[0]);
        $this->assertSame(0, MemberProfile::count());

        $this->fullCard('plain', $this->plain);
        $this->assertSame(204, $this->api('DELETE', "/members/{$this->plain->id}/profile", 'committee')[0]);
        $this->assertSame(204, $this->api('DELETE', "/members/{$this->plain->id}/profile", 'committee')[0]);
        $this->assertSame(1, MemberProfile::count());
    }

    public function testClearingCanReachAnInactiveMemberButNotAnotherClubsOrAnUnknownOne()
    {
        $lapsed = $this->member('lapsed', 302, [], 'lapsed');
        $this->seedProfile($lapsed, ['bio' => 'Old'], true);
        $this->assertSame(204, $this->api('DELETE', "/members/{$lapsed->id}/profile", 'committee')[0]);
        $this->assertNull($this->profile($lapsed)->bio);
        $this->assertSame(0, MemberPhoto::count());

        $this->otherClub();
        $foreign = ClubMember::create(['club_id' => 2, 'athlete_id' => 304, 'display_name' => 'Far Away', 'roles' => []]);
        $this->seedProfile($foreign, ['bio' => 'Theirs']);
        $this->assertSame(404, $this->api('DELETE', "/members/{$foreign->id}/profile", 'committee')[0]);
        $this->assertSame('Theirs', MemberProfile::where('member_id', $foreign->id)->value('bio'));

        $this->assertSame(404, $this->api('DELETE', '/members/' . $this->uuid() . '/profile', 'committee')[0]);
    }

    public function testPermissionIsCheckedBeforeExistence()
    {
        $this->assertSame(403, $this->api('DELETE', '/members/' . $this->uuid() . '/profile', 'plain')[0]);
    }

    // ---- member cards ----------------------------------------------------------------

    public function testCardShapeAndRelativePhotoPath()
    {
        $this->api('PUT', '/member-profile', 'leaderB', ['bio' => 'Loves hills']);
        [, $mine] = $this->upload('leaderB', $this->jpeg());

        [$status, $body] = $this->cards();

        $this->assertSame(200, $status);
        $this->assertSame(['items', 'serverTime'], array_keys($body));
        $this->assertSame('2026-10-12T09:00:00.000Z', $body['serverTime']);

        $card = collect($body['items'])->firstWhere('memberId', $this->leaderB->id);
        $this->assertSame(['displayName', 'hasBio', 'memberId', 'photoPath', 'roles'], collect(array_keys($card))->sort()->values()->all());
        $this->assertSame('Lou L.', $card['displayName']);
        $this->assertSame(['leader'], $card['roles']);
        $this->assertTrue($card['hasBio']);
        $this->assertSame($mine['photoPath'], $card['photoPath']);
        $this->assertStringStartsWith('/app/clubs/1/members/', $card['photoPath'], 'relative: the app adds the base URL');
        $this->assertStringNotContainsString('http', $card['photoPath']);

        $admin = collect($body['items'])->firstWhere('memberId', $this->admin->id);
        $this->assertNull($admin['photoPath']);
        $this->assertFalse($admin['hasBio']);
    }

    public function testRoleHoldersAreListedAndPlainMembersAreNot()
    {
        $ids = $this->cardIds();

        $this->assertEqualsCanonicalizing([$this->leaderB->id, $this->committee->id, $this->admin->id], $ids);
        $this->assertNotContains($this->plain->id, $ids);
        $this->assertNotContains($this->leaderA->id, $ids);
        $this->assertNotContains($this->coord->id, $ids);
    }

    public function testAnyMemberOfTheClubMayCallIt()
    {
        $this->assertSame(200, $this->cards('plain')[0]);
        $this->assertSame(200, $this->cards('committee')[0]);
        $this->assertSame(401, $this->cards(null)[0]);
        $this->assertSame(403, $this->cards('unlinked')[0]);
    }

    public function testGroupLeadersWithinNinetyDaysOrInTheFutureAreListed()
    {
        $recent = $this->member('recent', 311, [], 'active', 'Rae');
        $edge = $this->member('edge', 312, [], 'active', 'Ed');
        $old = $this->member('old', 313, [], 'active', 'Olly');
        $future = $this->member('future', 314, [], 'active', 'Fay');
        $withdrawn = $this->member('withdrawn', 315, [], 'active', 'Wes');
        $deletedRun = $this->member('deletedrun', 316, [], 'active', 'Dee');
        $deletedGroup = $this->member('deletedgroup', 317, [], 'active', 'Dom');

        $this->group($this->runOn(-60), [$recent]);
        $this->group($this->runOn(-89), [$edge]);
        $this->group($this->runOn(-95), [$old]);
        $this->group($this->runOn(40), [$future]);
        $g = $this->group($this->runOn(1), [$withdrawn]);
        SessionGroupLeader::where('member_id', $withdrawn->id)->update(['status' => 'withdrawn']);
        $run = $this->runOn(2);
        $this->group($run, [$deletedRun]);
        $run->delete();
        $this->group($this->runOn(3), [$deletedGroup])->delete();

        $ids = $this->cardIds();

        $this->assertContains($recent->id, $ids);
        $this->assertContains($edge->id, $ids);
        $this->assertContains($future->id, $ids);
        $this->assertNotContains($old->id, $ids, '95 days ago is outside the window');
        $this->assertNotContains($withdrawn->id, $ids, 'only confirmed leaders');
        $this->assertNotContains($deletedRun->id, $ids);
        $this->assertNotContains($deletedGroup->id, $ids);
    }

    public function testCoordinatorsWithinTheWindowAreListed()
    {
        $new = $this->member('coordnew', 321, [], 'active', 'Cal');
        $old = $this->member('coordold', 322, [], 'active', 'Cat');

        $this->runOn(5, ['coordinator_member_id' => $new->id]);
        $this->runOn(-100, ['coordinator_member_id' => $old->id]);

        $ids = $this->cardIds();

        $this->assertContains($new->id, $ids);
        $this->assertNotContains($old->id, $ids);
    }

    public function testPhotoOrBioAloneIsEnoughButGoalsAloneAreNot()
    {
        $photo = $this->member('photo', 331, [], 'active', 'Pia');
        $bio = $this->member('bio', 332, [], 'active', 'Bo');
        $goals = $this->member('goals', 333, [], 'active', 'Gus');
        $empty = $this->member('empty', 334, [], 'active', 'Eve');
        $cleared = $this->member('cleared', 335, [], 'active', 'Cleo');

        $this->upload('photo', $this->jpeg());
        $this->api('PUT', '/member-profile', 'bio', ['bio' => 'Hi']);
        $this->api('PUT', '/member-profile', 'goals', ['goals' => 'Go', 'goalsVisible' => true]);
        $this->api('PUT', '/member-profile', 'empty', ['bio' => '   ']);
        $this->api('PUT', '/member-profile', 'cleared', ['bio' => 'Hi']);
        $this->api('PUT', '/member-profile', 'cleared', ['bio' => null]);

        $items = collect($this->cards()[1]['items']);

        $this->assertNotNull($items->firstWhere('memberId', $photo->id)['photoPath']);
        $this->assertFalse($items->firstWhere('memberId', $photo->id)['hasBio']);
        $this->assertTrue($items->firstWhere('memberId', $bio->id)['hasBio']);
        $this->assertNull($items->firstWhere('memberId', $goals->id), 'goals alone do not list a member');
        $this->assertNull($items->firstWhere('memberId', $empty->id));
        $this->assertNull($items->firstWhere('memberId', $cleared->id));
        $this->assertStringNotContainsString('Go', json_encode($items->all()), 'goals never appear here');
    }

    public function testInactiveAndRemovedMembersAreNeverListed()
    {
        $lapsed = $this->member('lapsed', 341, ['leader'], 'lapsed', 'Len');
        $this->seedProfile($lapsed, ['bio' => 'Hi'], true);
        $this->group($this->runOn(1), [$lapsed]);
        $gone = $this->member('gone', 342, ['committee'], 'active', 'Gil');
        $this->seedProfile($gone, ['bio' => 'Hi']);
        $gone->delete();

        $ids = $this->cardIds();

        $this->assertNotContains($lapsed->id, $ids);
        $this->assertNotContains($gone->id, $ids);
    }

    public function testOtherClubsAreNeverMixedIn()
    {
        $this->otherClub();
        $foreign = ClubMember::create(['club_id' => 2, 'athlete_id' => 351, 'display_name' => 'Far Away', 'roles' => ['admin', 'leader']]);
        DB::table('athletes')->insert(['id' => 351, 'urn' => 1, 'athlete_id' => 351, 'first_name' => 'Far', 'last_name' => 'Away', 'gender' => 'M', 'dob' => '1980-01-01']);
        $this->seedProfile($foreign, ['bio' => 'Hello', 'club_id' => 2], false);
        MemberLogin::create(['club_id' => 2, 'member_id' => $foreign->id, 'user_id' => 'foreign', 'linked_at' => Carbon::now()]);

        $this->assertNotContains($foreign->id, $this->cardIds());

        [$status, $body] = $this->call_('GET', '/app/clubs/2/member-cards', 'foreign');
        $this->assertSame(200, $status);
        $this->assertSame([$foreign->id], array_column($body['items'], 'memberId'), 'club 2 sees only its own member');

        // A club 1 member who led in club 2's run is not pulled in either.
        $this->assertNotContains($this->plain->id, array_column($body['items'], 'memberId'));
    }

    public function testOrderedByNameThenId()
    {
        $this->member('zed', 361, ['leader'], 'active', 'Zed');
        $this->member('abe', 362, ['leader'], 'active', 'abe');
        $this->member('bea', 363, ['leader'], 'active', 'Bea');
        $twins = [$this->member('sam1', 364, ['leader'], 'active', 'Sam'), $this->member('sam2', 365, ['leader'], 'active', 'Sam')];
        DB::table('athletes')->whereIn('id', [364, 365])->update(['last_name' => 'Same']);

        $items = $this->cards()[1]['items'];

        $this->assertSame(
            ['abe L.', 'Ada L.', 'Bea L.', 'Cam L.', 'Lou L.', 'Sam S.', 'Sam S.', 'Zed L.'],
            array_column($items, 'displayName'),
            'case-insensitive by display name'
        );

        $sameIds = [$twins[0]->id, $twins[1]->id];
        sort($sameIds);
        $this->assertSame($sameIds, [$items[5]['memberId'], $items[6]['memberId']], 'ties break by member id');
    }

    public function testRolesInCardsAreFilteredToThePublicOnes()
    {
        $this->member('multi', 371, ['admin', 'bogus', 'leader'], 'active', 'Mel');

        $card = collect($this->cards()[1]['items'])->firstWhere('displayName', 'Mel L.');

        $this->assertSame(['leader', 'admin'], $card['roles']);
    }

    public function testTheListDoesNotGrowQueriesPerMember()
    {
        $count = function () {
            DB::connection()->enableQueryLog();
            DB::connection()->flushQueryLog();
            $this->cards();
            $n = count(DB::connection()->getQueryLog());
            DB::connection()->disableQueryLog();

            return $n;
        };

        $small = $count();

        for ($i = 0; $i < 25; $i++) {
            $m = $this->member("bulk$i", 400 + $i, $i % 2 ? ['leader'] : [], 'active', "Bulk$i");
            $this->seedProfile($m, ['bio' => "Bio $i"], $i % 3 === 0);
            $this->group($this->runOn(1 + $i), [$m]);
        }

        $this->assertGreaterThan(25, count($this->cardIds()));
        $this->assertSame($small, $count(), 'same number of queries for 4 or 30 members');
        $this->assertLessThanOrEqual(7, $small, 'three for the club middleware plus the list itself');
    }
}
