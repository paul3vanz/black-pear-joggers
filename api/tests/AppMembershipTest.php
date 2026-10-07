<?php

require_once __DIR__ . '/AppApiTestCase.php';

use Illuminate\Support\Carbon;
use App\Models\Club;
use App\Models\ClubMember;
use App\Models\MemberLinkAttempt;
use App\Models\MemberLogin;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The /app membership endpoints (me, link, unlink, profile) on in-memory SQLite.
 * Setup and helpers live in AppApiTestCase.
 */
class AppMembershipTest extends AppApiTestCase
{
    public function testRequiresAuthentication()
    {
        [$status] = $this->call_('GET', '/app/me', null);

        $this->assertSame(401, $status);
    }

    public function testBpjIsSeededAsClubOne()
    {
        $club = Club::find(1);

        $this->assertSame('Black Pear Joggers', $club->name);
        $this->assertSame('bpj', $club->slug);
        $this->assertSame(1606, $club->ea_club_id);
        $this->assertSame('Europe/London', $club->timezone);
        $this->assertSame('https://bpj.org.uk/membership', $club->join_url);
    }

    public function testMeWithNoLinks()
    {
        [$status, $body] = $this->call_('GET', '/app/me', 'google-oauth2|1');

        $this->assertSame(200, $status);
        $this->assertSame('google-oauth2|1', $body['userId']);
        $this->assertSame([], $body['memberships']);
        $this->assertSame([[
            'id' => 1,
            'name' => 'Black Pear Joggers',
            'slug' => 'bpj',
            'joinUrl' => 'https://bpj.org.uk/membership',
        ]], $body['clubs']);
    }

    public function testLinkSuccessReturnsTheMembershipShapeAndWritesTheLegacyUser()
    {
        $this->makeAthlete();
        $this->registerAthlete();

        [$status, $body] = $this->link('google-oauth2|1');

        $this->assertSame(200, $status);
        $this->assertSame('active', $body['status']);
        $this->assertSame([], $body['roles']);
        $this->assertSame(1, $body['club']['id']);
        $this->assertSame('bpj', $body['club']['slug']);
        $this->assertSame(
            ['id' => 123, 'firstName' => 'Jo', 'lastName' => 'Bloggs', 'gender' => 'W', 'category' => $body['athlete']['category']],
            $body['athlete']
        );
        $this->assertNotEmpty($body['athlete']['category']);
        $this->assertNotContains('urn', array_keys($body['athlete']));
        $this->assertNotContains('dob', array_keys($body['athlete']));

        $member = ClubMember::first();
        $this->assertSame($member->id, $body['memberId']);
        $this->assertSame('Jo Bloggs', $member->display_name);
        $this->assertSame(123, $member->athlete_id);

        $login = MemberLogin::first();
        $this->assertSame('google-oauth2|1', $login->user_id);
        $this->assertSame($member->id, $login->member_id);

        $this->assertSame(123, User::find('google-oauth2|1')->athleteId);

        // me returns the same item
        [, $me] = $this->call_('GET', '/app/me', 'google-oauth2|1');
        $this->assertSame([$body], $me['memberships']);
    }

    public function testLinkMarksAnAthleteWithNoMembershipOrPaymentAsLapsed()
    {
        $this->makeAthlete();

        [$status, $body] = $this->link('google-oauth2|1');

        $this->assertSame(200, $status);
        $this->assertSame('lapsed', $body['status']);
    }

    public function testLinkWithWrongDetailsIs404AndWritesNothing()
    {
        $this->makeAthlete();

        [$status, $body] = $this->link('google-oauth2|1', 1234567, '1990-05-05');

        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);
        $this->assertSame(0, ClubMember::count());
        $this->assertSame(0, MemberLogin::count());
        $this->assertNull(User::find('google-oauth2|1'));
        $this->assertSame(1, MemberLinkAttempt::where('success', false)->count());
    }

    public function testLinkValidatesTheRequest()
    {
        [$status, $body] = $this->call_('POST', '/app/clubs/1/link', 'google-oauth2|1', ['urn' => 'abc', 'dob' => '01/01/1983']);

        $this->assertSame(422, $status);
        $this->assertArrayHasKey('urn', $body['errors']);
        $this->assertArrayHasKey('dob', $body['errors']);
        $this->assertSame(0, MemberLinkAttempt::count());
    }

    public function testLinkToAnUnknownClubIs404()
    {
        $this->makeAthlete();

        [$status, $body] = $this->link('google-oauth2|1', 1234567, self::DOB, 99);

        $this->assertSame(404, $status);
        $this->assertSame('club_not_found', $body['error']);
    }

    public function testMoreThanFiveFailedAttemptsIsRateLimited()
    {
        $this->makeAthlete();

        for ($i = 0; $i < 5; $i++) {
            [$status] = $this->link('google-oauth2|1', 1234567, '1990-05-05');
            $this->assertSame(404, $status);
        }

        // Even the right details are refused now.
        [$status, $body] = $this->link('google-oauth2|1');
        $this->assertSame(429, $status);
        $this->assertSame('too_many_attempts', $body['error']);
        $this->assertSame(0, MemberLogin::count());

        // Another login is not affected.
        [$status] = $this->link('google-oauth2|2');
        $this->assertSame(200, $status);
    }

    public function testOldFailedAttemptsDoNotCount()
    {
        $this->makeAthlete();

        for ($i = 0; $i < 5; $i++) {
            MemberLinkAttempt::create(['user_id' => 'google-oauth2|1', 'club_id' => 1, 'success' => false]);
        }
        MemberLinkAttempt::query()->update(['created_at' => Carbon::now()->subHours(2)]);

        [$status] = $this->link('google-oauth2|1');

        $this->assertSame(200, $status);
    }

    public function testTwoLoginsLinkingTheSameAthleteShareOneMember()
    {
        $this->makeAthlete();

        [$statusA, $a] = $this->link('google-oauth2|1');
        [$statusB, $b] = $this->link('facebook|2');

        $this->assertSame(200, $statusA);
        $this->assertSame(200, $statusB);
        $this->assertSame($a['memberId'], $b['memberId']);
        $this->assertSame(1, ClubMember::count());
        $this->assertSame(2, MemberLogin::count());
        $this->assertSame(123, User::find('facebook|2')->athleteId);

        [, $profileA] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');
        [, $profileB] = $this->call_('GET', '/app/clubs/1/profile', 'facebook|2');
        $this->assertSame($profileA['memberId'], $profileB['memberId']);
    }

    public function testLinkingAgainWithTheSameDetailsIsIdempotent()
    {
        $this->makeAthlete();

        [, $first] = $this->link('google-oauth2|1');
        [$status, $second] = $this->link('google-oauth2|1');

        $this->assertSame(200, $status);
        $this->assertSame($first['memberId'], $second['memberId']);
        $this->assertSame(1, ClubMember::count());
        $this->assertSame(1, MemberLogin::count());
    }

    public function testRelinkingMovesTheLoginToTheNewMember()
    {
        $this->makeAthlete();
        $this->makeAthlete(['id' => 456, 'urn' => 7654321, 'athlete_id' => 111, 'first_name' => 'Sam', 'last_name' => 'Smith']);

        [, $first] = $this->link('google-oauth2|1');
        [$status, $second] = $this->link('google-oauth2|1', 7654321);

        $this->assertSame(200, $status);
        $this->assertNotSame($first['memberId'], $second['memberId']);
        $this->assertSame(2, ClubMember::count());

        $this->assertSame(1, MemberLogin::count());
        $this->assertSame($second['memberId'], MemberLogin::first()->member_id);
        $this->assertSame(456, User::find('google-oauth2|1')->athleteId);

        [, $me] = $this->call_('GET', '/app/me', 'google-oauth2|1');
        $this->assertCount(1, $me['memberships']);
        $this->assertSame('Sam', $me['memberships'][0]['athlete']['firstName']);
    }

    public function testProfileIs403WhenNotLinked()
    {
        $this->makeAthlete();

        [$status, $body] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');

        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);
        $this->assertArrayHasKey('message', $body);
    }

    public function testProfileForAnUnknownClubIs404()
    {
        [$status, $body] = $this->call_('GET', '/app/clubs/99/profile', 'google-oauth2|1');

        $this->assertSame(404, $status);
        $this->assertSame('club_not_found', $body['error']);
    }

    public function testProfileShape()
    {
        $this->makeAthlete();
        $this->registerAthlete();
        [, $linked] = $this->link('google-oauth2|1');

        [$status, $body] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');

        $this->assertSame(200, $status);
        $this->assertSame($linked['memberId'], $body['memberId']);
        $this->assertSame('active', $body['status']);
        $this->assertSame([], $body['roles']);

        $category = $linked['athlete']['category'];
        $this->assertSame([
            'id' => 123,
            'firstName' => 'Jo',
            'lastName' => 'Bloggs',
            'gender' => 'W',
            'category' => $category,
            'athleteId' => 450606,
            'po10Guid' => 'a1b2c3d4-0000-0000-0000-000000000001',
            'active' => true,
            'affiliated' => true,
        ], $body['athlete']);
        $this->assertSame([
            'competitiveRegStatus' => 'Registered',
            'firstClaimClubName' => 'Black Pear Joggers',
        ], $body['membership']);
        $this->assertSame([
            'results' => 'https://apps.bpj.org.uk/race-results/#/athlete/450606',
            'powerOf10' => 'https://www.powerof10.uk/Home/Athlete/a1b2c3d4-0000-0000-0000-000000000001',
            'claimAward' => 'https://bpj.org.uk/claim-award',
        ], $body['links']);
        $this->assertStringNotContainsString('1234567', $this->response->getContent());
        $this->assertStringNotContainsString(self::DOB, $this->response->getContent());
    }

    public function testProfileWithNoRegistrationHasNullMembershipAndNullLinks()
    {
        $this->makeAthlete(['athlete_id' => null, 'po10_guid' => null]);
        $this->link('google-oauth2|1');

        [, $body] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');

        $this->assertNull($body['membership']);
        $this->assertNull($body['links']['results']);
        $this->assertNull($body['links']['powerOf10']);
        $this->assertNull($body['athlete']['po10Guid']);
        $this->assertFalse($body['athlete']['active']);
        $this->assertSame('lapsed', $body['status']);
    }

    public function testProfileRecalculatesAndSavesStatus()
    {
        $this->makeAthlete();
        $this->link('google-oauth2|1');
        $this->assertSame('lapsed', ClubMember::first()->status);

        $this->registerAthlete();

        [, $body] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');

        $this->assertSame('active', $body['status']);
        $this->assertSame('active', ClubMember::first()->status);

        DB::table('memberships')->update(['competitiveRegStatus' => 'Expired']);

        [, $body] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');

        $this->assertSame('lapsed', $body['status']);
        $this->assertSame('lapsed', ClubMember::first()->status);
    }

    public function testUnlinkReturns204KeepsTheMemberAndIsRepeatable()
    {
        $this->makeAthlete();
        $this->link('google-oauth2|1');
        $this->link('facebook|2');

        [$status] = $this->call_('DELETE', '/app/clubs/1/link', 'google-oauth2|1');

        $this->assertSame(204, $status);
        $this->assertSame(1, ClubMember::count());
        $this->assertSame(['facebook|2'], MemberLogin::pluck('user_id')->all());

        [$status] = $this->call_('GET', '/app/clubs/1/profile', 'google-oauth2|1');
        $this->assertSame(403, $status);

        [$status] = $this->call_('DELETE', '/app/clubs/1/link', 'google-oauth2|1');
        $this->assertSame(204, $status);
    }

    public function testUnlinkFromAnUnknownClubIs404()
    {
        [$status, $body] = $this->call_('DELETE', '/app/clubs/99/link', 'google-oauth2|1');

        $this->assertSame(404, $status);
        $this->assertSame('club_not_found', $body['error']);
    }

    public function testBackfillLinksExistingWebUsersToBpjMembers()
    {
        $this->makeAthlete();
        $this->makeAthlete(['id' => 456, 'urn' => 7654321, 'athlete_id' => 111, 'first_name' => 'Sam', 'last_name' => 'Smith']);
        $this->registerAthlete();

        DB::table('users')->insert([
            ['id' => 'google-oauth2|1', 'athleteId' => 123],
            ['id' => 'facebook|2', 'athleteId' => 123],      // same person, second login
            ['id' => 'auth0|3', 'athleteId' => 456],
            ['id' => 'auth0|4', 'athleteId' => null],        // never linked
            ['id' => 'auth0|5', 'athleteId' => 999],         // athlete no longer exists
        ]);

        $migration = require base_path('database/migrations/2026_10_06_090400_backfill_club_members_from_users.php');
        $migration->up();

        $this->assertSame(2, ClubMember::count());
        $this->assertSame(3, MemberLogin::count());
        $this->assertSame('active', ClubMember::where('athlete_id', 123)->first()->status);
        $this->assertSame('lapsed', ClubMember::where('athlete_id', 456)->first()->status);
        $this->assertSame('Sam Smith', ClubMember::where('athlete_id', 456)->first()->display_name);
        $this->assertSame(
            ClubMember::where('athlete_id', 123)->first()->id,
            MemberLogin::where('user_id', 'facebook|2')->first()->member_id
        );
        $this->assertSame(0, MemberLogin::where('user_id', 'auth0|4')->count());
        $this->assertSame(0, MemberLogin::where('user_id', 'auth0|5')->count());

        // Idempotent.
        $migration->up();
        $this->assertSame(2, ClubMember::count());
        $this->assertSame(3, MemberLogin::count());

        // And the backfilled login works in the app straight away.
        [$status, $body] = $this->call_('GET', '/app/clubs/1/profile', 'auth0|3');
        $this->assertSame(200, $status);
        $this->assertSame('Sam', $body['athlete']['firstName']);
    }

    public function testBackfillIsSkippedWhenTheLegacyTablesDoNotExist()
    {
        Schema::drop('member_logins');
        Schema::drop('club_members');
        Schema::drop('users');

        $migration = require base_path('database/migrations/2026_10_06_090400_backfill_club_members_from_users.php');
        $migration->up();

        $this->assertTrue(true);
    }
}
