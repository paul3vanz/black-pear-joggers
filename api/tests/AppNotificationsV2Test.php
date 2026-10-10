<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\Club;
use App\Models\ClubMember;
use App\Models\Device;
use App\Models\MemberPreference;
use App\Models\MemberSeriesPref;
use App\Models\Notification;
use App\Models\SessionAttendee;
use App\Models\SessionSeries;
use App\Services\FcmClient;
use App\Services\NotificationPresenter;
use App\Services\NotificationService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 5a: NotificationService dedupe keys and daily cap, the settings
 * endpoints, the unauthenticated notification-actions endpoint, FCM data-only
 * messages and app:send-test-push. "Now" is pinned to Monday 2026-10-12 09:00
 * UTC (see AppGroupsBase). The queue is faked: nothing is pushed for real.
 */
class AppNotificationsV2Test extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    protected function tearDown(): void
    {
        $this->setActionButtonsFlag(null);

        parent::tearDown();
    }

    private function service(): NotificationService
    {
        return app(NotificationService::class);
    }

    /** One notifyMembers call for $member with sensible defaults. */
    private function notify(ClubMember $member, array $o = []): array
    {
        $o += [
            'category' => 'club_updates', 'title' => 'Title', 'body' => 'Body', 'data' => ['route' => '/x'],
            'force' => false, 'options' => [],
        ];

        return $this->service()->notifyMembers(Club::find(1), [$member->id], $o['category'], $o['title'], $o['body'], $o['data'], $o['force'], $o['options']);
    }

    private function jobs(): int
    {
        return Queue::pushed(SendPushNotificationsJob::class)->count();
    }

    private function setCap(ClubMember $member, ?int $cap): void
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $member->id, 'push_daily_cap' => $cap]);
    }

    private function setActionButtonsFlag(?string $value): void
    {
        if ($value === null) {
            putenv('FCM_ACTION_BUTTONS');
            unset($_ENV['FCM_ACTION_BUTTONS'], $_SERVER['FCM_ACTION_BUTTONS']);

            return;
        }

        putenv('FCM_ACTION_BUTTONS=' . $value);
        $_ENV['FCM_ACTION_BUTTONS'] = $value;
        $_SERVER['FCM_ACTION_BUTTONS'] = $value;
    }

    // ---- dedupe keys -------------------------------------------------------------

    public function testNotificationsWithoutAKeyAreNeverDeduplicated()
    {
        $this->notify($this->plain);
        $this->notify($this->plain);

        $this->assertSame(2, Notification::count());
    }

    public function testIdenticalContentWithTheSameKeyDoesNothingAtAll()
    {
        $first = $this->notify($this->plain, ['options' => ['dedupeKey' => 'k1']]);
        $this->assertCount(1, $first);
        $this->assertSame('k1', $first[0]->dedupe_key);
        $this->assertSame(1, $this->jobs());

        foreach (['skip', 'replace'] as $mode) {
            $again = $this->notify($this->plain, ['options' => ['dedupeKey' => 'k1', 'onDuplicate' => $mode]]);
            $this->assertSame([], $again);
        }

        $this->assertSame(1, Notification::count());
        $this->assertSame(1, $this->jobs());
    }

    public function testSkipLeavesTheExistingRowAlone()
    {
        $this->notify($this->plain, ['options' => ['dedupeKey' => 'k1']]);

        $again = $this->notify($this->plain, ['body' => 'Different', 'options' => ['dedupeKey' => 'k1']]);

        $this->assertSame([], $again);
        $this->assertSame(1, Notification::count());
        $this->assertSame('Body', Notification::first()->body);
        $this->assertSame(1, $this->jobs());
    }

    public function testTheSameKeyIsPerMember()
    {
        $this->notify($this->plain, ['options' => ['dedupeKey' => 'k1']]);
        $this->notify($this->leaderA, ['options' => ['dedupeKey' => 'k1']]);

        $this->assertSame(2, Notification::count());
    }

    public function testReplaceUpdatesTheRowInPlaceAndMakesItUnread()
    {
        $row = $this->notify($this->plain, ['options' => ['dedupeKey' => 'k1', 'onDuplicate' => 'replace']])[0];
        $row->forceFill(['read_at' => Carbon::now(), 'pushed_at' => Carbon::now()])->save();
        $firstUpdated = $row->fresh()->updated_at;

        Carbon::setTestNow(Carbon::now()->addMinutes(5));
        $again = $this->notify($this->plain, [
            'title' => 'New title', 'body' => 'New body', 'data' => ['route' => '/y'],
            'options' => ['dedupeKey' => 'k1', 'onDuplicate' => 'replace'],
        ]);

        $this->assertCount(1, $again);
        $this->assertSame(1, Notification::count());

        $fresh = Notification::first();
        $this->assertSame($row->id, $fresh->id);
        $this->assertSame('New title', $fresh->title);
        $this->assertSame('New body', $fresh->body);
        $this->assertSame(['route' => '/y'], $fresh->data);
        $this->assertNull($fresh->read_at);
        $this->assertTrue($fresh->updated_at->gt($firstUpdated));
    }

    public function testReplaceRepushesOnlyAfterTheRepushWindow()
    {
        $opts = ['dedupeKey' => 'k1', 'onDuplicate' => 'replace'];
        $this->notify($this->plain, ['options' => $opts]);
        $this->assertSame(1, $this->jobs());

        // 30 minutes later: inside the default 60 minute window, so no push.
        Carbon::setTestNow(Carbon::now()->addMinutes(30));
        $this->notify($this->plain, ['body' => 'v2', 'options' => $opts]);
        $this->assertSame(1, $this->jobs());
        $this->assertSame('v2', Notification::first()->body);

        // 61 minutes after the push: pushed again, and pushed_at is cleared for the job.
        Notification::query()->update(['pushed_at' => Carbon::now()->subMinutes(30)]);
        Carbon::setTestNow(Carbon::now()->addMinutes(31));
        $this->notify($this->plain, ['body' => 'v3', 'options' => $opts]);
        $this->assertSame(2, $this->jobs());
        $this->assertNull(Notification::first()->pushed_at);
        $this->assertCount(1, Notification::all());
    }

    public function testRepushOptionOverridesTheWindow()
    {
        $opts = ['dedupeKey' => 'k1', 'onDuplicate' => 'replace', 'repush' => 10];
        $this->notify($this->plain, ['options' => $opts]);

        Carbon::setTestNow(Carbon::now()->addMinutes(5));
        $this->notify($this->plain, ['body' => 'v2', 'options' => $opts]);
        $this->assertSame(1, $this->jobs());

        Carbon::setTestNow(Carbon::now()->addMinutes(6));
        $this->notify($this->plain, ['body' => 'v3', 'options' => $opts]);
        $this->assertSame(2, $this->jobs());
    }

    public function testLockedCategoriesRepushOnEveryReplace()
    {
        $opts = ['dedupeKey' => 'session_change:1', 'onDuplicate' => 'replace'];
        $this->notify($this->plain, ['category' => 'my_group_changes', 'title' => 'Cancelled', 'options' => $opts]);
        $this->notify($this->plain, ['category' => 'my_group_changes', 'title' => 'Restored', 'options' => $opts]);
        $this->notify($this->plain, ['category' => 'my_group_changes', 'title' => 'Cancelled again', 'options' => $opts]);

        $this->assertSame(3, $this->jobs());
        $this->assertSame(1, Notification::count());
        $this->assertSame('Cancelled again', Notification::first()->title);
    }

    public function testAReplacedRowIsNotPushedWhenThePushIsOff()
    {
        \App\Models\NotificationPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'category' => 'club_updates', 'push_enabled' => false]);
        $opts = ['dedupeKey' => 'k1', 'onDuplicate' => 'replace', 'repush' => 0];

        $this->notify($this->plain, ['options' => $opts]);
        $this->notify($this->plain, ['body' => 'v2', 'options' => $opts]);

        $this->assertSame(0, $this->jobs());
        $this->assertSame('v2', Notification::first()->body); // the inbox still updates
    }

    public function testDedupeKeyIsTruncatedTo80Characters()
    {
        $row = $this->notify($this->plain, ['options' => ['dedupeKey' => str_repeat('a', 120)]])[0];

        $this->assertSame(80, strlen($row->fresh()->dedupe_key));
    }

    // ---- daily cap ---------------------------------------------------------------

    private function sendMany(ClubMember $member, int $n, array $o = []): void
    {
        for ($i = 1; $i <= $n; $i++) {
            $this->notify($member, ['title' => "T$i"] + $o);
        }
    }

    public function testTheDefaultCapIsSixPushesInARolling24Hours()
    {
        $this->sendMany($this->plain, 8);

        $this->assertSame(8, Notification::count()); // the inbox always gets the row
        $this->assertSame(6, Notification::whereNotNull('push_requested_at')->count());
        $this->assertSame(6, $this->jobs());
        $this->assertSame(0, Notification::where('title', 'T7')->whereNotNull('push_requested_at')->count());
    }

    public function testTheCapWindowRollsForwardHourByHour()
    {
        $this->sendMany($this->plain, 6);
        $this->notify($this->plain, ['title' => 'blocked']);
        $this->assertNull(Notification::where('title', 'blocked')->first()->push_requested_at);

        Carbon::setTestNow(Carbon::now()->addHours(25));
        $this->notify($this->plain, ['title' => 'next day']);

        $this->assertNotNull(Notification::where('title', 'next day')->first()->push_requested_at);
        $this->assertSame(7, $this->jobs());
    }

    public function testTheCapReadsThePerMemberSetting()
    {
        $this->setCap($this->plain, 2);
        $this->sendMany($this->plain, 4);
        $this->assertSame(2, Notification::whereNotNull('push_requested_at')->count());

        // Another member keeps the default.
        $this->sendMany($this->leaderA, 4);
        $this->assertSame(4, Notification::where('member_id', $this->leaderA->id)->whereNotNull('push_requested_at')->count());
    }

    public function testACapOfZeroMeansNoLimit()
    {
        $this->setCap($this->plain, 0);
        $this->sendMany($this->plain, 9);

        $this->assertSame(9, Notification::whereNotNull('push_requested_at')->count());
    }

    public function testAMemberWithPreferencesButNoCapUsesTheDefault()
    {
        $this->setCap($this->plain, null);
        $this->sendMany($this->plain, 7);

        $this->assertSame(6, Notification::whereNotNull('push_requested_at')->count());
    }

    public function testLockedCategoriesIgnoreTheCapAndDoNotCountTowardsIt()
    {
        $this->setCap($this->plain, 1);
        $this->sendMany($this->plain, 3, ['category' => 'my_group_changes']);

        $this->assertSame(3, $this->jobs());
        $this->assertSame(0, Notification::whereNotNull('push_requested_at')->count());

        // The cap is still free for a capped category.
        $this->notify($this->plain, ['title' => 'capped 1']);
        $this->notify($this->plain, ['title' => 'capped 2']);
        $this->assertSame(1, Notification::whereNotNull('push_requested_at')->count());
        $this->assertSame(4, $this->jobs());
    }

    public function testForceIgnoresTheCapAndDoesNotCountTowardsIt()
    {
        $this->setCap($this->plain, 1);
        $this->notify($this->plain, ['title' => 'normal']);
        $this->sendMany($this->plain, 3, ['force' => true]);

        $this->assertSame(4, $this->jobs());
        $this->assertSame(1, Notification::whereNotNull('push_requested_at')->count());

        // ...and forced pushes did not use up anything: the cap is still just the one normal push.
        Carbon::setTestNow(Carbon::now()->addHours(25));
        $this->notify($this->plain, ['title' => 'tomorrow']);
        $this->assertSame(5, $this->jobs());
    }

    public function testAMemberWhoTurnedPushOffDoesNotUseTheCap()
    {
        \App\Models\NotificationPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'category' => 'club_updates', 'push_enabled' => false]);
        $this->sendMany($this->plain, 3);

        $this->assertSame(0, Notification::whereNotNull('push_requested_at')->count());
    }

    public function testRepushingTheSameRowIsNotBlockedByItsOwnCount()
    {
        $this->setCap($this->plain, 1);
        $opts = ['dedupeKey' => 'k1', 'onDuplicate' => 'replace', 'repush' => 0];

        $this->notify($this->plain, ['options' => $opts]);
        $this->notify($this->plain, ['body' => 'v2', 'options' => $opts]);

        $this->assertSame(2, $this->jobs());
        $this->assertSame(1, Notification::whereNotNull('push_requested_at')->count());
    }

    // ---- presenter -----------------------------------------------------------------

    public function testThePresenterHidesTheActionToken()
    {
        $row = $this->notify($this->plain, ['data' => ['route' => '/runs/1', 'actions' => ['going'], 'actionToken' => 'secret']])[0];

        $shape = NotificationPresenter::notification($row->fresh());
        $this->assertSame(['route' => '/runs/1', 'actions' => ['going']], (array) $shape['data']);

        [$status, $body] = $this->call_('GET', '/app/clubs/1/notifications', 'plain');
        $this->assertSame(200, $status);
        $this->assertStringNotContainsString('secret', json_encode($body));
        $this->assertStringNotContainsString('actionToken', json_encode($body));

        $this->assertSame('secret', $row->fresh()->data['actionToken']); // still stored for the push
    }

    // ---- settings ------------------------------------------------------------------

    private function makeSeries(string $title, int $weekday, string $time, array $o = []): SessionSeries
    {
        return SessionSeries::create($o + [
            'club_id' => 1, 'title' => $title, 'weekday' => $weekday, 'start_time' => $time, 'duration_min' => 60,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'group_mode' => 'paced',
        ]);
    }

    public function testSettingsRequireAuthAndMembership()
    {
        [$status] = $this->call_('GET', '/app/clubs/1/notification-settings', null);
        $this->assertSame(401, $status);

        [$status] = $this->call_('GET', '/app/clubs/1/notification-settings', 'stranger');
        $this->assertSame(403, $status);

        [$status] = $this->call_('PUT', '/app/clubs/1/notification-settings', 'stranger', ['dailyPushCap' => 3]);
        $this->assertSame(403, $status);
    }

    public function testSettingsDefaultsAndSeriesOrder()
    {
        $thu = $this->makeSeries('Thursday', 4, '19:00');
        $tueLate = $this->makeSeries('Tuesday late', 2, '20:00');
        $tue = $this->makeSeries('Tuesday run', 2, '19:00');
        $gone = $this->makeSeries('Deleted', 3, '19:00');
        $gone->delete();

        [$status, $body] = $this->call_('GET', '/app/clubs/1/notification-settings', 'plain');

        $this->assertSame(200, $status);
        $this->assertSame(6, $body['dailyPushCap']);
        $this->assertSame(6, $body['defaultDailyPushCap']);
        $this->assertSame([$tue->id, $tueLate->id, $thu->id], array_column($body['series'], 'seriesId'));
        $this->assertSame(
            ['seriesId' => $tue->id, 'title' => 'Tuesday run', 'weekday' => 2, 'localStartTime' => '19:00', 'reminders' => 'auto'],
            $body['series'][0]
        );
    }

    public function testPutSavesTheCapAndSeriesOverridesAndAutoDeletesTheRow()
    {
        $tue = $this->makeSeries('Tuesday run', 2, '19:00');
        $thu = $this->makeSeries('Thursday', 4, '19:00');

        [$status, $body] = $this->call_('PUT', '/app/clubs/1/notification-settings', 'plain', [
            'dailyPushCap' => 12, 'series' => [$tue->id => 'off', $thu->id => 'on'],
        ]);

        $this->assertSame(200, $status);
        $this->assertSame(12, $body['dailyPushCap']);
        $this->assertSame(['off', 'on'], array_column($body['series'], 'reminders'));
        $this->assertSame(12, MemberPreference::first()->push_daily_cap);
        $this->assertSame(2, MemberSeriesPref::count());

        // GET returns the same; other members are unaffected.
        [, $again] = $this->call_('GET', '/app/clubs/1/notification-settings', 'plain');
        $this->assertSame($body, $again);
        [, $other] = $this->call_('GET', '/app/clubs/1/notification-settings', 'leaderA');
        $this->assertSame(6, $other['dailyPushCap']);
        $this->assertSame(['auto', 'auto'], array_column($other['series'], 'reminders'));

        // Partial update: only a series; auto deletes the row and the cap is kept.
        [, $body] = $this->call_('PUT', '/app/clubs/1/notification-settings', 'plain', ['series' => [$tue->id => 'auto']]);
        $this->assertSame(12, $body['dailyPushCap']);
        $this->assertSame(['auto', 'on'], array_column($body['series'], 'reminders'));
        $this->assertSame(1, MemberSeriesPref::count());

        // Updating an override replaces it rather than adding a row.
        $this->call_('PUT', '/app/clubs/1/notification-settings', 'plain', ['series' => [$thu->id => 'off']]);
        $this->assertSame(1, MemberSeriesPref::count());
        $this->assertSame('off', MemberSeriesPref::first()->reminders);
    }

    public function testPutZeroMeansNoLimitAndKeepsPacePreferences()
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->plain->id, 'pace_unit' => 'km', 'pace_from_s' => 300]);

        [$status, $body] = $this->call_('PUT', '/app/clubs/1/notification-settings', 'plain', ['dailyPushCap' => 0]);

        $this->assertSame(200, $status);
        $this->assertSame(0, $body['dailyPushCap']);
        $pref = MemberPreference::first();
        $this->assertSame('km', $pref->pace_unit);
        $this->assertSame(300, (int) $pref->pace_from_s);
        $this->assertSame(1, MemberPreference::count());
    }

    public function testPutRejectsBadValuesAndSavesNothing()
    {
        $tue = $this->makeSeries('Tuesday run', 2, '19:00');
        $gone = $this->makeSeries('Deleted', 3, '19:00');
        $gone->delete();

        $bad = [
            ['dailyPushCap' => 51],
            ['dailyPushCap' => -1],
            ['dailyPushCap' => 'lots'],
            ['series' => 'nope'],
            ['series' => [$tue->id => 'sometimes']],
            ['series' => [$tue->id => 'off', 'f0f0f0f0-0000-4000-8000-000000000000' => 'on']],
            ['series' => [$gone->id => 'on']],
            ['dailyPushCap' => 3, 'series' => [$tue->id => 'sometimes']],
        ];

        foreach ($bad as $payload) {
            [$status, $body] = $this->call_('PUT', '/app/clubs/1/notification-settings', 'plain', $payload);

            $this->assertSame(422, $status, json_encode($payload));
            $this->assertSame('validation_failed', $body['error']);
            $this->assertNotEmpty($body['errors']);
        }

        $this->assertSame(0, MemberPreference::count());
        $this->assertSame(0, MemberSeriesPref::count());
    }

    // ---- notification actions -------------------------------------------------------

    private function reminder(ClubMember $member, $session, array $data = []): Notification
    {
        return Notification::create([
            'club_id' => 1, 'member_id' => $member->id, 'category' => 'run_reminders',
            'title' => 'Tonight', 'body' => 'Are you coming?',
            'data' => $data + [
                'route' => '/runs/' . $session->id, 'sessionId' => $session->id,
                'actions' => ['going', 'not_going'], 'actionToken' => str_repeat('ab', 16),
            ],
        ]);
    }

    private function act(Notification $n, array $o = []): array
    {
        return $this->call_('POST', '/app/notification-actions', null, $o + [
            'notificationId' => $n->id, 'token' => str_repeat('ab', 16), 'action' => 'going',
        ]);
    }

    public function testGoingFromAReminderWritesAttendanceAndMarksItRead()
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s);

        [$status, $body] = $this->act($n);

        $this->assertSame(200, $status);
        $this->assertSame(['status' => 'going', 'sessionId' => $s->id], $body);
        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->plain->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertNotNull($n->fresh()->read_at);

        // It is the same state PUT .../attendance reads back.
        [, $mine] = $this->api('GET', "/sessions/{$s->id}/attendance", 'plain');
        $this->assertSame('going', $mine['status']);
    }

    public function testGoingKeepsTheChosenGroupAndPaceAndNotGoingClearsTheGroup()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);
        $this->attend($s, $this->plain, 'maybe', $g, ['pace_unit' => 'km', 'pace_from_s' => 300, 'pace_to_s' => 330]);
        $n = $this->reminder($this->plain, $s);

        [$status] = $this->act($n);
        $this->assertSame(200, $status);
        $row = SessionAttendee::where('member_id', $this->plain->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertSame($g->id, $row->group_id);
        $this->assertSame(300, (int) $row->pace_from_s);

        [$status, $body] = $this->act($n, ['action' => 'not_going']);
        $this->assertSame(200, $status);
        $this->assertSame('not_going', $body['status']);
        $row = SessionAttendee::where('member_id', $this->plain->id)->first();
        $this->assertSame('not_going', $row->status);
        $this->assertNull($row->group_id);
        $this->assertSame(1, SessionAttendee::count());
    }

    public function testAnActionBumpsTheSessionSoSyncDeliversIt()
    {
        $s = $this->session();
        Carbon::setTestNow(Carbon::now()->addMinutes(10));

        $this->act($this->reminder($this->plain, $s));

        $this->assertTrue($s->fresh()->updated_at->equalTo(Carbon::now()));
    }

    public function testRepliesAreIdempotent()
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s);

        $this->assertSame(200, $this->act($n)[0]);
        $this->assertSame(200, $this->act($n)[0]);
        $this->assertSame(1, SessionAttendee::count());
    }

    public function testAWrongTokenIsNotFoundAndChangesNothing()
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s);

        [$status, $body] = $this->act($n, ['token' => str_repeat('cd', 16)]);

        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);
        $this->assertSame(0, SessionAttendee::count());
        $this->assertNull($n->fresh()->read_at);
    }

    public function testAnActionOutsideTheNotificationsActionsIsNotFound()
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s, ['actions' => ['going']]);

        $this->assertSame(404, $this->act($n, ['action' => 'not_going'])[0]);
        $this->assertSame(404, $this->act($n, ['action' => 'maybe'])[0]);
        $this->assertSame(0, SessionAttendee::count());
    }

    public function testNotificationsWithoutATokenOrUnknownIdsAreNotFound()
    {
        $s = $this->session();
        $plainNotification = Notification::create([
            'club_id' => 1, 'member_id' => $this->plain->id, 'category' => 'club_updates',
            'title' => 'x', 'body' => 'y', 'data' => ['route' => '/x', 'sessionId' => $s->id, 'actions' => ['going']],
        ]);

        $this->assertSame(404, $this->act($plainNotification)[0]);
        $this->assertSame(404, $this->call_('POST', '/app/notification-actions', null, [
            'notificationId' => 'f0f0f0f0-0000-4000-8000-000000000000', 'token' => 'x', 'action' => 'going',
        ])[0]);
        $this->assertSame(0, SessionAttendee::count());
    }

    public function testMalformedBodiesAre422()
    {
        [$status, $body] = $this->call_('POST', '/app/notification-actions', null, ['action' => 'going']);

        $this->assertSame(422, $status);
        $this->assertSame('validation_failed', $body['error']);
    }

    public function testACancelledOrFinishedRunIsClosed()
    {
        $cancelled = $this->session(['status' => 'cancelled']);
        [$status, $body] = $this->act($this->reminder($this->plain, $cancelled));
        $this->assertSame(409, $status);
        $this->assertSame('session_closed', $body['error']);

        $past = $this->pastSession();
        $this->assertSame(409, $this->act($this->reminder($this->plain, $past))[0]);
        $this->assertSame(0, SessionAttendee::count());
    }

    public function testADeletedRunIsNotFound()
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s);
        $s->delete();

        $this->assertSame(404, $this->act($n)[0]);
    }

    public function testTheActionsEndpointIsThrottledPerIp()
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s);
        $wrong = ['token' => 'wrong'];

        for ($i = 0; $i < 30; $i++) {
            $this->assertSame(404, $this->act($n, $wrong)[0], "request $i");
        }

        [$status, $body] = $this->act($n, $wrong);
        $this->assertSame(429, $status);
        $this->assertSame('too_many_requests', $body['error']);

        // Even the right token is refused while limited; the window then rolls over.
        $this->assertSame(429, $this->act($n)[0]);
        Carbon::setTestNow(Carbon::now()->addMinutes(2));
        \Illuminate\Support\Facades\Cache::flush(); // the array store ignores faked time
        $this->assertSame(200, $this->act($n)[0]);
    }

    public function testExistingAttendanceEndpointStillBehavesTheSame()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', [
            'status' => 'going', 'groupId' => $g->id, 'paceUnit' => 'km', 'paceFromS' => 300, 'paceToS' => 330,
        ]);

        $this->assertSame(200, $status);
        $this->assertSame(['sessionId' => $s->id, 'status' => 'going', 'groupId' => $g->id, 'paceUnit' => 'km', 'paceFromS' => 300, 'paceToS' => 330], array_diff_key($body, ['updatedAt' => 1]));

        [, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'not_going', 'groupId' => $g->id]);
        $this->assertNull($body['groupId']);
        $this->assertNull($body['paceFromS']);
    }

    // ---- FCM message shape ----------------------------------------------------------

    private function fcm(): FcmClient
    {
        return new FcmClient(new \GuzzleHttp\Client(), new \App\Services\GoogleAccessToken(new \GuzzleHttp\Client(), '/no/such/file.json', sys_get_temp_dir() . '/bpj-none'));
    }

    private function actionNotification(): array
    {
        $s = $this->session();
        $n = $this->reminder($this->plain, $s);
        $n->update(['dedupe_key' => 'reminder:' . $s->id]);
        $device = Device::create(['user_id' => 'plain', 'token' => 'tok-a', 'platform' => 'android']);

        return [$s, $n->fresh(), $device];
    }

    public function testNotificationsWithActionsGoOutAsDataOnlyMessages()
    {
        [$s, $n, $device] = $this->actionNotification();

        $message = $this->fcm()->buildMessage($device, $n)['message'];

        $this->assertSame([
            'token' => 'tok-a',
            'data' => [
                'notificationId' => $n->id,
                'clubId' => '1',
                'userId' => 'plain',
                'category' => 'run_reminders',
                'route' => '/runs/' . $s->id,
                'title' => 'Tonight',
                'body' => 'Are you coming?',
                'sessionId' => $s->id,
                'actions' => 'going,not_going',
                'actionToken' => str_repeat('ab', 16),
                'tag' => 'reminder:' . $s->id,
            ],
            'android' => ['priority' => 'high'],
            'apns' => ['payload' => ['aps' => [
                'alert' => ['title' => 'Tonight', 'body' => 'Are you coming?'],
                'sound' => 'default',
                'category' => 'BPJ_RUN_REMINDER',
            ]]],
        ], $message);
        $this->assertArrayNotHasKey('notification', $message);
    }

    public function testTheFlagTurnsActionButtonsOffAndOtherNotificationsAreUnchanged()
    {
        [, $n, $device] = $this->actionNotification();
        $this->setActionButtonsFlag('false');

        $message = $this->fcm()->buildMessage($device, $n)['message'];

        $this->assertSame(['title' => 'Tonight', 'body' => 'Are you coming?'], $message['notification']);
        $this->assertSame(['notification' => ['channel_id' => 'run_reminders']], $message['android']);
        $this->assertArrayNotHasKey('title', $message['data']);
        $this->assertArrayNotHasKey('actionToken', $message['data']);

        // Any other spelling of "on" keeps data-only mode.
        $this->setActionButtonsFlag('true');
        $this->assertArrayNotHasKey('notification', $this->fcm()->buildMessage($device, $n)['message']);

        // A plain notification is never data-only.
        $plain = $this->notify($this->plain)[0];
        $this->assertArrayHasKey('notification', $this->fcm()->buildMessage($device, $plain)['message']);
    }

    public function testActionTokensAreRandom32Hex()
    {
        $a = NotificationService::newActionToken();
        $b = NotificationService::newActionToken();

        $this->assertMatchesRegularExpression('/^[0-9a-f]{32}$/', $a);
        $this->assertNotSame($a, $b);
    }

    // ---- app:send-test-push ----------------------------------------------------------

    /** A mocked FcmClient: configured, and "accepting" every notification it is given. */
    private function mockFcm(bool $configured = true): FcmClient
    {
        $mock = $this->createMock(FcmClient::class);
        $mock->method('isConfigured')->willReturn($configured);
        $mock->method('send')->willReturnCallback(function (array $pairs) {
            $delivered = [];
            foreach ($pairs as [$device, $notification]) {
                $delivered[$notification->id] = true;
            }

            return $delivered;
        });
        $this->app->instance(FcmClient::class, $mock);

        return $mock;
    }

    private function runTestPush(array $args): array
    {
        $kernel = $this->app['Illuminate\Contracts\Console\Kernel'];
        $code = $kernel->call('app:send-test-push', $args);

        return [$code, $kernel->output()];
    }

    public function testTestPushSendsAClubUpdatesNotificationSynchronously()
    {
        Device::create(['user_id' => 'plain', 'token' => 'tok-a', 'platform' => 'android']);
        $this->mockFcm();

        [$code, $out] = $this->runTestPush(['clubId' => 1, 'athleteId' => 201]);

        $this->assertSame(0, $code);
        $n = Notification::first();
        $this->assertSame('club_updates', $n->category);
        $this->assertSame('Test push', $n->title);
        $this->assertNotNull($n->pushed_at);
        $this->assertStringContainsString('1 device(s)', $out);
        $this->assertStringContainsString('FCM configured: yes', $out);
        $this->assertStringContainsString('pushed_at: 20', $out);
    }

    public function testTestPushWithActionsWritesAReminderWithATokenAndRoute()
    {
        Device::create(['user_id' => 'plain', 'token' => 'tok-a', 'platform' => 'android']);
        $this->mockFcm();
        $s = $this->session();

        [$code] = $this->runTestPush(['clubId' => 1, 'athleteId' => 201, '--actions' => true, '--session' => $s->id]);

        $this->assertSame(0, $code);
        $n = Notification::first();
        $this->assertSame('run_reminders', $n->category);
        $this->assertSame('/runs/' . $s->id, $n->data['route']);
        $this->assertSame($s->id, $n->data['sessionId']);
        $this->assertSame(['going', 'not_going'], $n->data['actions']);
        $this->assertMatchesRegularExpression('/^[0-9a-f]{32}$/', $n->data['actionToken']);
        $this->assertNotNull($n->pushed_at);

        // The token it wrote works against the unauthenticated endpoint.
        [$status] = $this->call_('POST', '/app/notification-actions', null, ['notificationId' => $n->id, 'token' => $n->data['actionToken'], 'action' => 'going']);
        $this->assertSame(200, $status);
    }

    public function testTestPushReportsWhenNothingWasPushed()
    {
        $this->mockFcm(false);

        [$code, $out] = $this->runTestPush(['clubId' => 1, 'athleteId' => 201]);

        $this->assertSame(1, $code);
        $this->assertSame(1, Notification::count()); // the inbox row is still written
        $this->assertNull(Notification::first()->pushed_at);
        $this->assertStringContainsString('0 device(s)', $out);
        $this->assertStringContainsString('FCM configured: no', $out);
        $this->assertStringContainsString('pushed_at: not set', $out);
    }

    public function testTestPushIgnoresTheDailyCap()
    {
        Device::create(['user_id' => 'plain', 'token' => 'tok-a', 'platform' => 'android']);
        $this->mockFcm();
        $this->setCap($this->plain, 1);
        $this->sendMany($this->plain, 2);

        [$code] = $this->runTestPush(['clubId' => 1, 'athleteId' => 201]);

        $this->assertSame(0, $code);
        $this->assertNotNull(Notification::where('title', 'Test push')->first()->pushed_at);
    }

    public function testTestPushRejectsBadInput()
    {
        $this->mockFcm();
        $s = $this->session();

        $this->assertSame(1, $this->runTestPush(['clubId' => 9, 'athleteId' => 201])[0]);
        $this->assertSame(1, $this->runTestPush(['clubId' => 1, 'athleteId' => 999])[0]);
        $this->assertSame(1, $this->runTestPush(['clubId' => 1, 'athleteId' => 201, '--actions' => true])[0]);
        $this->assertSame(1, $this->runTestPush(['clubId' => 1, 'athleteId' => 201, '--actions' => true, '--session' => 'f0f0f0f0-0000-4000-8000-000000000000'])[0]);
        $this->assertSame(0, Notification::count());
    }
}
