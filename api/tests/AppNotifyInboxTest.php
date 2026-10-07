<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\ClubMember;
use App\Models\MemberLogin;
use App\Models\Notification;
use App\Models\NotificationPreference;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Notifying members when a post is published, the inbox endpoints and the
 * notification preferences. The queue is faked: nothing is pushed.
 */
class AppNotifyInboxTest extends AppApiTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function postBody(array $overrides = []): array
    {
        return $overrides + ['title' => 'Hello', 'bodyMd' => 'Some **news**', 'priority' => 'normal', 'audience' => 'all'];
    }

    /** Ids of notifications queued for push, asserting they went on the notifications queue. */
    private function pushedIds(): array
    {
        $ids = [];
        Queue::assertPushed(SendPushNotificationsJob::class, function ($job) use (&$ids) {
            $ids = array_merge($ids, $job->notificationIds());

            return $job->queue === 'notifications';
        });

        return $ids;
    }

    // ---- notify on post ----------------------------------------------------

    public function testNotifyCreatesInboxRowsForActiveAudienceMembersExceptTheAuthor()
    {
        $this->member('u|c', 3, ['committee']);
        $m1 = $this->member('u|1', 1);
        $m2 = $this->member('u|2', 2);
        $leader = $this->member('u|l', 6, ['leader']);
        $this->member('u|lapsed', 5, [], 'lapsed');

        [$status, $post] = $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody([
            'title' => 'Track night', 'bodyMd' => "# Heads up\nThe **track** is closed", 'notify' => true,
        ]));

        $this->assertSame(201, $status);
        $this->assertEqualsCanonicalizing(
            [$m1->id, $m2->id, $leader->id],
            Notification::pluck('member_id')->all()
        );

        $n = Notification::where('member_id', $m1->id)->first();
        $this->assertSame('club_updates', $n->category);
        $this->assertSame('Track night', $n->title);
        $this->assertSame('Heads up The track is closed', $n->body);
        $this->assertSame(['route' => '/updates/' . $post['id']], $n->data);
        $this->assertSame(1, $n->club_id);
        $this->assertNull($n->read_at);

        // One job for the whole call, on the notifications queue.
        Queue::assertPushed(SendPushNotificationsJob::class, 1);
        $this->assertEqualsCanonicalizing(Notification::pluck('id')->all(), $this->pushedIds());
    }

    public function testNotifyRespectsTheAudience()
    {
        $this->member('u|c', 3, ['committee']);
        $this->member('u|1', 1);
        $leader = $this->member('u|l', 6, ['leader']);
        $admin = $this->member('u|a', 7, ['admin']);

        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['audience' => 'leaders', 'notify' => true]));

        $this->assertEqualsCanonicalizing([$leader->id, $admin->id], Notification::pluck('member_id')->all());
    }

    public function testPostWithoutNotifyWritesNoInboxRowsAndNoJob()
    {
        $this->member('u|c', 3, ['committee']);
        $this->member('u|1', 1);

        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody());

        $this->assertSame(0, Notification::count());
        Queue::assertNothingPushed();
    }

    public function testAMemberWhoTurnedClubUpdatesOffGetsAnInboxRowButNoPush()
    {
        $this->member('u|c', 3, ['committee']);
        $off = $this->member('u|off', 1);
        $on = $this->member('u|on', 2);

        [$status] = $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|off', ['club_updates' => false]);
        $this->assertSame(200, $status);

        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['notify' => true]));

        $this->assertSame(2, Notification::count());
        $this->assertSame(1, Notification::where('member_id', $off->id)->count());
        $this->assertSame([Notification::where('member_id', $on->id)->first()->id], $this->pushedIds());
    }

    public function testNoJobWhenNobodyIsPushEligible()
    {
        $this->member('u|c', 3, ['committee']);
        $this->member('u|off', 1);
        $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|off', ['club_updates' => false]);

        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['notify' => true]));

        $this->assertSame(1, Notification::count());
        Queue::assertNothingPushed();
    }

    public function testImportantPostsForcePushEvenWhenTurnedOff()
    {
        $this->member('u|c', 3, ['committee']);
        $off = $this->member('u|off', 1);
        $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|off', ['club_updates' => false]);

        $this->call_('POST', '/app/clubs/1/posts', 'u|c', $this->postBody(['priority' => 'important', 'notify' => true]));

        $this->assertSame([Notification::where('member_id', $off->id)->first()->id], $this->pushedIds());
    }

    // ---- inbox --------------------------------------------------------------

    private function inbox(string $sub, string $query = ''): array
    {
        return $this->call_('GET', '/app/clubs/1/notifications' . $query, $sub);
    }

    private function note(ClubMember $member, string $title, array $extra = []): Notification
    {
        return Notification::create($extra + [
            'club_id' => 1, 'member_id' => $member->id, 'category' => 'club_updates',
            'title' => $title, 'body' => 'b', 'data' => ['route' => '/updates/x'],
        ]);
    }

    public function testInboxShapeAndUnreadCountAreScopedToTheCaller()
    {
        $me = $this->member('u|1', 1);
        $other = $this->member('u|2', 2);
        $this->note($me, 'mine');
        $this->note($me, 'mine read', ['read_at' => Carbon::now()]);
        $this->note($other, 'theirs');

        [$status, $body] = $this->inbox('u|1');

        $this->assertSame(200, $status);
        $this->assertSame(1, $body['unreadCount']);
        $this->assertEqualsCanonicalizing(['mine', 'mine read'], collect($body['items'])->pluck('title')->all());
        $item = collect($body['items'])->firstWhere('title', 'mine');
        $this->assertSame(['id', 'category', 'title', 'body', 'data', 'createdAt', 'readAt'], array_keys($item));
        $this->assertSame(['route' => '/updates/x'], $item['data']);
        $this->assertNull($item['readAt']);
        $this->assertNotNull(collect($body['items'])->firstWhere('title', 'mine read')['readAt']);
        $this->assertArrayHasKey('serverTime', $body);
    }

    public function testInboxSinceReturnsNewAndChangedRows()
    {
        $me = $this->member('u|1', 1);
        $a = $this->note($me, 'a');
        $this->note($me, 'b');
        Notification::query()->update(['updated_at' => Carbon::now()->subDay()]);

        [, $first] = $this->inbox('u|1');
        $since = urlencode($first['serverTime']);

        [, $none] = $this->inbox('u|1', "?since=$since");
        $this->assertSame([], $none['items']);

        $this->call_('POST', '/app/clubs/1/notifications/read', 'u|1', ['ids' => [$a->id]]);
        $this->note($me, 'c');

        [, $delta] = $this->inbox('u|1', "?since=$since");
        $this->assertEqualsCanonicalizing(['a', 'c'], collect($delta['items'])->pluck('title')->all());
        $this->assertSame(2, $delta['unreadCount']); // b and c
    }

    public function testMarkReadByIdsOnlyTouchesTheCallersRows()
    {
        $me = $this->member('u|1', 1);
        $other = $this->member('u|2', 2);
        $mine1 = $this->note($me, '1');
        $mine2 = $this->note($me, '2');
        $theirs = $this->note($other, 'theirs');

        [$status] = $this->call_('POST', '/app/clubs/1/notifications/read', 'u|1', ['ids' => [$mine1->id, $theirs->id]]);

        $this->assertSame(204, $status);
        $this->assertNotNull($mine1->fresh()->read_at);
        $this->assertNull($mine2->fresh()->read_at);
        $this->assertNull($theirs->fresh()->read_at);
    }

    public function testMarkAllRead()
    {
        $me = $this->member('u|1', 1);
        $other = $this->member('u|2', 2);
        $this->note($me, '1');
        $this->note($me, '2');
        $theirs = $this->note($other, 'theirs');

        [$status] = $this->call_('POST', '/app/clubs/1/notifications/read', 'u|1', ['all' => true]);

        $this->assertSame(204, $status);
        $this->assertSame(0, Notification::where('member_id', $me->id)->whereNull('read_at')->count());
        $this->assertNull($theirs->fresh()->read_at);

        [, $body] = $this->inbox('u|1');
        $this->assertSame(0, $body['unreadCount']);
    }

    public function testMarkReadNeedsIdsOrAll()
    {
        $this->member('u|1', 1);

        [$status, $body] = $this->call_('POST', '/app/clubs/1/notifications/read', 'u|1', []);

        $this->assertSame(422, $status);
        $this->assertSame('validation_failed', $body['error']);
    }

    public function testInboxRequiresMembership()
    {
        [$status] = $this->inbox('u|nobody');
        $this->assertSame(403, $status);
    }

    // ---- preferences --------------------------------------------------------

    private function prefs(string $sub): array
    {
        [, $body] = $this->call_('GET', '/app/clubs/1/notification-preferences', $sub);

        return collect($body['categories'])->keyBy('category')->all();
    }

    public function testPreferencesDefaults()
    {
        $this->member('u|1', 1);
        $this->member('u|l', 2, ['leader']);

        $plain = $this->prefs('u|1');

        $this->assertSame(
            ['club_updates', 'run_reminders', 'group_matches', 'my_group_changes', 'leaders_needed', 'group_messages'],
            array_keys($plain)
        );
        $this->assertSame(
            ['category' => 'club_updates', 'label' => 'Club updates', 'description' => $plain['club_updates']['description'], 'pushEnabled' => true, 'locked' => false],
            $plain['club_updates']
        );
        $this->assertTrue($plain['my_group_changes']['locked']);
        $this->assertTrue($plain['my_group_changes']['pushEnabled']);
        $this->assertFalse($plain['leaders_needed']['pushEnabled']);
        $this->assertTrue($this->prefs('u|l')['leaders_needed']['pushEnabled']);
    }

    public function testPutPreferencesSavesIgnoresLockedAndUnknownAndReturnsTheSameShape()
    {
        $member = $this->member('u|1', 1);

        [$status, $body] = $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|1', [
            'club_updates' => false,
            'leaders_needed' => true,
            'my_group_changes' => false,
            'bogus' => false,
        ]);

        $this->assertSame(200, $status);
        $byKey = collect($body['categories'])->keyBy('category');
        $this->assertFalse($byKey['club_updates']['pushEnabled']);
        $this->assertTrue($byKey['leaders_needed']['pushEnabled']);
        $this->assertTrue($byKey['my_group_changes']['pushEnabled']);

        $this->assertEqualsCanonicalizing(
            ['club_updates', 'leaders_needed'],
            NotificationPreference::where('member_id', $member->id)->pluck('category')->all()
        );

        // Updating again changes the row rather than adding one.
        $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|1', ['club_updates' => true]);
        $this->assertSame(2, NotificationPreference::count());
        $this->assertTrue($this->prefs('u|1')['club_updates']['pushEnabled']);
    }

    public function testPutPreferencesRejectsNonBooleans()
    {
        $this->member('u|1', 1);

        [$status] = $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|1', ['club_updates' => 'maybe']);

        $this->assertSame(422, $status);
        $this->assertSame(0, NotificationPreference::count());
    }

    public function testPreferencesAreSharedByAllLoginsOfAMember()
    {
        $member = $this->member('u|1', 1);
        MemberLogin::create(['club_id' => 1, 'member_id' => $member->id, 'user_id' => 'u|1b', 'linked_at' => Carbon::now()]);

        $this->call_('PUT', '/app/clubs/1/notification-preferences', 'u|1', ['run_reminders' => false]);

        $this->assertFalse($this->prefs('u|1b')['run_reminders']['pushEnabled']);
    }
}
