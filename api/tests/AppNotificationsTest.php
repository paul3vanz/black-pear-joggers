<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\ClubMember;
use App\Models\Device;
use App\Models\MemberLogin;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\Post;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 2 endpoints: devices, posts, notification inbox and preferences, and
 * the NotificationService. Pushes are never sent: the queue is faked.
 */
class AppNotificationsTest extends AppApiTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    protected const UUID_A = '11111111-1111-4111-8111-111111111111';
    protected const UUID_B = '22222222-2222-4222-8222-222222222222';

    // ---- devices ---------------------------------------------------------

    public function testDevicesRequireAuth()
    {
        [$status] = $this->call_('POST', '/app/devices', null, ['token' => 't', 'platform' => 'android']);

        $this->assertSame(401, $status);
    }

    public function testRegisterDeviceUpsertsByToken()
    {
        [$status] = $this->call_('POST', '/app/devices', 'u|1', ['token' => 'tok:1', 'platform' => 'android', 'appVersion' => '1.0.0+1']);
        $this->assertSame(204, $status);

        [$status] = $this->call_('POST', '/app/devices', 'u|1', ['token' => 'tok:1', 'platform' => 'ios', 'appVersion' => '1.0.1+2']);
        $this->assertSame(204, $status);

        $this->assertSame(1, Device::count());
        $device = Device::first();
        $this->assertSame('u|1', $device->user_id);
        $this->assertSame('ios', $device->platform);
        $this->assertSame('1.0.1+2', $device->app_version);
        $this->assertNotNull($device->last_seen_at);
    }

    public function testRegisteringATokenHeldByAnotherLoginMovesIt()
    {
        $this->call_('POST', '/app/devices', 'u|1', ['token' => 'shared', 'platform' => 'android']);
        $this->call_('POST', '/app/devices', 'u|2', ['token' => 'shared', 'platform' => 'android']);

        $this->assertSame(1, Device::count());
        $this->assertSame('u|2', Device::first()->user_id);
    }

    public function testRegisterDeviceValidates()
    {
        [$status, $body] = $this->call_('POST', '/app/devices', 'u|1', ['platform' => 'windows']);

        $this->assertSame(422, $status);
        $this->assertArrayHasKey('token', $body['errors']);
        $this->assertArrayHasKey('platform', $body['errors']);
        $this->assertSame(0, Device::count());
    }

    public function testDeleteDeviceOnlyRemovesTheCallersToken()
    {
        $this->call_('POST', '/app/devices', 'u|1', ['token' => 'tok-1', 'platform' => 'android']);

        [$status] = $this->call_('DELETE', '/app/devices/tok-1', 'u|2');
        $this->assertSame(204, $status);
        $this->assertSame(1, Device::count());

        [$status] = $this->call_('DELETE', '/app/devices/tok-1', 'u|1');
        $this->assertSame(204, $status);
        $this->assertSame(0, Device::count());

        [$status] = $this->call_('DELETE', '/app/devices/tok-1', 'u|1');
        $this->assertSame(204, $status);
    }

    public function testDeleteDeviceWorksForTokensWithColonsAndEncodedChars()
    {
        $token = 'cX9a-_b:APA91bH_k-Z0';
        $this->call_('POST', '/app/devices', 'u|1', ['token' => $token, 'platform' => 'android']);

        $this->call_('DELETE', '/app/devices/' . $token, 'u|1');
        $this->assertSame(0, Device::count());

        $this->call_('POST', '/app/devices', 'u|1', ['token' => $token, 'platform' => 'android']);
        $this->call_('DELETE', '/app/devices/' . rawurlencode($token), 'u|1');
        $this->assertSame(0, Device::count());
    }

    // ---- posts -----------------------------------------------------------

    private function postBody(array $overrides = []): array
    {
        return $overrides + ['title' => 'Hello', 'bodyMd' => 'Some **news**', 'priority' => 'normal', 'audience' => 'all'];
    }

    public function testPostsRequireMembership()
    {
        [$status, $body] = $this->call_('GET', '/app/clubs/1/posts', 'u|1');

        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);

        [$status, $body] = $this->call_('GET', '/app/clubs/99/posts', 'u|1');
        $this->assertSame(404, $status);
    }

    public function testPlainMemberCannotWritePosts()
    {
        $this->member('u|1', 1);
        $this->member('u|leader', 2, ['leader']);
        $committee = $this->member('u|c', 3, ['committee']);
        $post = Post::create(['club_id' => 1, 'author_member_id' => $committee->id, 'title' => 't', 'body_md' => 'b', 'published_at' => Carbon::now()]);

        foreach (['u|1', 'u|leader'] as $sub) {
            [$status, $body] = $this->call_('POST', '/app/clubs/1/posts', $sub, $this->postBody());
            $this->assertSame(403, $status);
            $this->assertSame('forbidden', $body['error']);

            [$status] = $this->call_('PATCH', "/app/clubs/1/posts/{$post->id}", $sub, ['title' => 'x']);
            $this->assertSame(403, $status);

            [$status] = $this->call_('DELETE', "/app/clubs/1/posts/{$post->id}", $sub);
            $this->assertSame(403, $status);
        }

        $this->assertSame(1, Post::count());
        $this->assertSame('t', Post::first()->title);
    }

    public function testCommitteeAndAdminCanCreateAPostAndItHasTheContractShape()
    {
        $this->member('u|c', 3, ['committee'], 'active', 'Cath');
        $this->member('u|a', 4, ['admin']);

        [$status, $body] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['pinnedUntil' => '2030-01-01T00:00:00Z']));

        $this->assertSame(201, $status);
        $this->assertSame(
            ['id', 'title', 'bodyMd', 'priority', 'audience', 'publishedAt', 'pinnedUntil', 'author', 'updatedAt', 'deletedAt'],
            array_keys($body)
        );
        $this->assertSame('Some **news**', $body['bodyMd']);
        $this->assertSame('Cath Last3', $body['author']['displayName']);
        $this->assertSame(ClubMember::where('athlete_id', 3)->first()->id, $body['author']['memberId']);
        $this->assertSame('2030-01-01T00:00:00.000Z', $body['pinnedUntil']);
        $this->assertNull($body['deletedAt']);
        $this->assertMatchesRegularExpression('/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/', $body['publishedAt']);

        [$status] = $this->call_('POST', '/app/clubs/1/posts', 'u|a', $this->postBody());
        $this->assertSame(201, $status);
        $this->assertSame(2, Post::count());
    }

    public function testCreatePostValidatesAndDefaults()
    {
        $this->member('u|c', 3, ['committee']);

        [$status, $body] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', ['priority' => 'urgent', 'audience' => 'everyone']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('title', $body['errors']);
        $this->assertArrayHasKey('bodyMd', $body['errors']);
        $this->assertArrayHasKey('priority', $body['errors']);
        $this->assertArrayHasKey('audience', $body['errors']);

        [$status, $body] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', ['title' => 'T', 'bodyMd' => 'B']);
        $this->assertSame(201, $status);
        $this->assertSame('normal', $body['priority']);
        $this->assertSame('all', $body['audience']);
        $this->assertNull($body['pinnedUntil']);
    }

    public function testCreatePostIsIdempotentOnTheClientId()
    {
        $this->member('u|c', 3, ['committee']);
        $this->member('u|1', 1);

        [$status, $first] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['id' => self::UUID_A, 'notify' => true]));
        [$status2, $second] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['id' => self::UUID_A, 'title' => 'Changed', 'notify' => true]));

        $this->assertSame(201, $status);
        $this->assertSame(200, $status2);
        $this->assertSame(self::UUID_A, $first['id']);
        $this->assertSame($first, $second);
        $this->assertSame(1, Post::count());
        $this->assertSame(1, Notification::count(), 'a replay must not notify again');
        Queue::assertPushed(SendPushNotificationsJob::class, 1);
    }

    public function testGetPostsFiltersByAudience()
    {
        $c = $this->member('u|c', 3, ['committee']);
        $this->member('u|a', 4, ['admin']);
        $this->member('u|l', 2, ['leader']);
        $this->member('u|1', 1);

        foreach (['all', 'leaders', 'committee'] as $audience) {
            Post::create(['club_id' => 1, 'author_member_id' => $c->id, 'title' => $audience, 'body_md' => 'b', 'audience' => $audience, 'published_at' => Carbon::now()]);
        }

        $titles = function (string $sub) {
            [, $body] = $this->call_('GET', '/app/clubs/1/posts', $sub);

            return collect($body['items'])->pluck('title')->sort()->values()->all();
        };

        $this->assertSame(['all'], $titles('u|1'));
        $this->assertSame(['all', 'leaders'], $titles('u|l'));
        $this->assertSame(['all', 'committee', 'leaders'], $titles('u|c'));
        $this->assertSame(['all', 'committee', 'leaders'], $titles('u|a'));
    }

    public function testGetPostsIsScopedToTheClub()
    {
        $c = $this->member('u|c', 3, ['committee']);
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other', 'slug' => 'other', 'created_at' => Carbon::now(), 'updated_at' => Carbon::now()]);
        Post::create(['club_id' => 2, 'author_member_id' => $c->id, 'title' => 'elsewhere', 'body_md' => 'b', 'published_at' => Carbon::now()]);

        [, $body] = $this->call_('GET', '/app/clubs/1/posts', 'u|c');

        $this->assertSame([], $body['items']);
    }

    public function testSinceReturnsOnlyChangesAndTombstones()
    {
        $this->member('u|c', 3, ['committee']);
        $this->member('u|1', 1);
        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['id' => self::UUID_A, 'title' => 'old']));
        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['id' => self::UUID_B, 'title' => 'doomed']));
        Post::query()->update(['updated_at' => Carbon::now()->subDay()]);

        [, $full] = $this->call_('GET', '/app/clubs/1/posts', 'u|1');
        $this->assertCount(2, $full['items']);
        $since = $full['serverTime'];
        $this->assertMatchesRegularExpression('/Z$/', $since);

        [, $none] = $this->call_('GET', '/app/clubs/1/posts?since=' . urlencode($since), 'u|1');
        $this->assertSame([], $none['items']);

        $this->call_('PATCH', '/app/clubs/1/posts/' . self::UUID_A, 'u|c', ['title' => 'edited']);
        $this->call_('DELETE', '/app/clubs/1/posts/' . self::UUID_B, 'u|c');

        [, $delta] = $this->call_('GET', '/app/clubs/1/posts?since=' . urlencode($since), 'u|1');
        $byId = collect($delta['items'])->keyBy('id');
        $this->assertCount(2, $byId);
        $this->assertSame('edited', $byId[self::UUID_A]['title']);
        $this->assertNull($byId[self::UUID_A]['deletedAt']);
        $this->assertNotNull($byId[self::UUID_B]['deletedAt']);

        // Deleted posts vanish from a full fetch.
        [, $full] = $this->call_('GET', '/app/clubs/1/posts', 'u|1');
        $this->assertSame(['edited'], collect($full['items'])->pluck('title')->all());

        [$status, $body] = $this->call_('GET', '/app/clubs/1/posts?since=not-a-date', 'u|1');
        $this->assertSame(422, $status);
    }

    public function testPatchAndDeleteBehaviour()
    {
        $this->member('u|c', 3, ['committee']);
        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['id' => self::UUID_A, 'pinnedUntil' => '2030-01-01T00:00:00Z']));

        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/posts/' . self::UUID_A, 'u|c', ['priority' => 'important', 'pinnedUntil' => null]);
        $this->assertSame(200, $status);
        $this->assertSame('important', $body['priority']);
        $this->assertNull($body['pinnedUntil']);
        $this->assertSame('Hello', $body['title']);

        [$status, $body] = $this->call_('PATCH', '/app/clubs/1/posts/' . self::UUID_A, 'u|c', ['audience' => 'nobody']);
        $this->assertSame(422, $status);

        [$status] = $this->call_('PATCH', '/app/clubs/1/posts/' . self::UUID_B, 'u|c', ['title' => 'x']);
        $this->assertSame(404, $status);

        [$status] = $this->call_('DELETE', '/app/clubs/1/posts/' . self::UUID_A, 'u|c');
        $this->assertSame(204, $status);
        $this->assertSame(0, Post::count());
        $this->assertSame(1, Post::withTrashed()->count());

        [$status] = $this->call_('DELETE', '/app/clubs/1/posts/' . self::UUID_A, 'u|c');
        $this->assertSame(204, $status);

        [$status] = $this->call_('PATCH', '/app/clubs/1/posts/' . self::UUID_A, 'u|c', ['title' => 'x']);
        $this->assertSame(404, $status);
    }


    // ---- app:member-role -------------------------------------------------------

    public function testMemberRoleCommandGrantsAndRevokesRoles()
    {
        $member = $this->member('u|1', 123);

        $code = $this->app['Illuminate\Contracts\Console\Kernel']->call('app:member-role', ['clubId' => 1, 'athleteId' => 123, 'role' => 'committee']);
        $this->assertSame(0, $code);
        $this->assertSame(['committee'], $member->fresh()->roles);

        $this->app['Illuminate\Contracts\Console\Kernel']->call('app:member-role', ['clubId' => 1, 'athleteId' => 123, 'role' => 'committee']);
        $this->app['Illuminate\Contracts\Console\Kernel']->call('app:member-role', ['clubId' => 1, 'athleteId' => 123, 'role' => 'leader']);
        $this->assertSame(['committee', 'leader'], $member->fresh()->roles);

        $this->app['Illuminate\Contracts\Console\Kernel']->call('app:member-role', ['clubId' => 1, 'athleteId' => 123, 'role' => 'committee', '--remove' => true]);
        $this->assertSame(['leader'], $member->fresh()->roles);

        // It takes effect in the API straight away.
        [, $me] = $this->call_('GET', '/app/me', 'u|1');
        $this->assertSame(['leader'], $me['memberships'][0]['roles']);
    }

    public function testMemberRoleCommandRejectsBadInput()
    {
        $this->member('u|1', 123);
        $kernel = $this->app['Illuminate\Contracts\Console\Kernel'];

        $this->assertSame(1, $kernel->call('app:member-role', ['clubId' => 1, 'athleteId' => 123, 'role' => 'superuser']));
        $this->assertSame(1, $kernel->call('app:member-role', ['clubId' => 1, 'athleteId' => 999, 'role' => 'admin']));
    }
}
