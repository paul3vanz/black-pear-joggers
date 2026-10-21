<?php

require_once __DIR__ . '/AppMessagesBase.php';

use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadMember;
use App\Models\Notification;
use App\Services\LeaderThreadNotifier;
use Illuminate\Support\Carbon;

/**
 * The leaders thread of a run (D125): committee, the run's leaders and the
 * people a committee ask went to. "Now" is Monday 2026-10-12 09:00 UTC and the
 * default run is that evening. $this->leaderA (Lee) leads the group, $this->leaderB
 * (Lou) holds the leader role and is free to be asked.
 */
class AppLeaderThreadsTest extends AppMessagesBase
{
    private function base(?ClubSession $session = null): string
    {
        return '/sessions/' . ($session ?: $this->sess)->id . '/leaders-chat';
    }

    private function ask(?string $sub, array $data = [], ?ClubSession $session = null): array
    {
        return $this->api('POST', $this->base($session) . '/ask', $sub, $data + ['fastSPerKm' => 330, 'slowSPerKm' => 360]);
    }

    private function say(?string $sub, string $body, ?ClubSession $session = null, ?string $id = null): array
    {
        return $this->api('POST', $this->base($session) . '/messages', $sub, ['body' => $body] + ($id ? ['id' => $id] : []));
    }

    private function read(?string $sub, string $query = '', ?ClubSession $session = null): array
    {
        return $this->api('GET', $this->base($session) . '/messages' . $query, $sub);
    }

    // ---- who is in it ---------------------------------------------------------------

    public function testOnlyCommitteeLeadersAndPeopleAskedAreIn()
    {
        // Before any ask: committee and the run's leader yes, a free leader and a plain member no.
        $this->assertSame(200, $this->read('committee')[0]);
        $this->assertSame(200, $this->read('admin')[0]);
        $this->assertSame(200, $this->read('leaderA')[0]);

        [$status, $body] = $this->read('leaderB');
        $this->assertSame(403, $status);
        $this->assertSame('not_in_thread', $body['error']);
        $this->assertSame(403, $this->read('plain')[0]);
        $this->assertSame(403, $this->read('going')[0]);

        // Asked: Lou is in, Pat still isn't.
        $this->ask('committee');
        $this->assertSame(200, $this->read('leaderB')[0]);
        $this->assertSame(403, $this->read('plain')[0]);
    }

    public function testUnknownRunIs404AndOtherClubsRunsAreHidden()
    {
        $this->assertSame(404, $this->api('GET', '/sessions/' . $this->uuid() . '/leaders-chat/messages', 'committee')[0]);
        $this->assertSame(401, $this->api('GET', $this->base() . '/messages', null)[0]);
    }

    // ---- asking ---------------------------------------------------------------------

    public function testOnlyTheCommitteeCanAsk()
    {
        [$status] = $this->ask('leaderA');
        $this->assertSame(403, $status);
        $this->assertSame(403, $this->ask('plain')[0]);
        $this->assertSame(0, LeaderMessage::count());
    }

    public function testAnAskIsPostedAndSentToMembersWhoMayLead()
    {
        [$status, $body] = $this->ask('committee', ['note' => 'Thursday group is short']);

        $this->assertSame(201, $status);
        $this->assertSame(1, $body['notified']); // Lou: Lee already leads, Pat isn't a leader
        $m = $body['message'];
        $this->assertSame('ask', $m['kind']);
        $this->assertSame(330, $m['askFastSPerKm']);
        $this->assertSame(360, $m['askSlowSPerKm']);
        $this->assertSame('Thursday group is short', $m['body']);
        $this->assertSame('committee', $m['authorRole']);
        $this->assertSame('leaders:' . $this->sess->id, $m['groupId']);

        $this->assertSame([$this->leaderB->id], LeaderThreadMember::pluck('member_id')->all());

        $n = Notification::where('member_id', $this->leaderB->id)->where('category', 'leaders_needed')->first();
        $this->assertNotNull($n);
        $this->assertSame('/runs/' . $this->sess->id . '/leaders-chat', $n->data['route']);
        $this->assertStringContainsString('Can you lead', $n->body);
        $this->assertStringContainsString('/mi', $n->body); // spoken in miles by default
        $this->assertStringContainsString('Thursday group is short', $n->body);

        // The asker isn't told about their own ask; the run's leader hears it as a thread message.
        $this->assertSame(0, Notification::where('member_id', $this->committee->id)->count());
        $this->assertSame(1, Notification::where('member_id', $this->leaderA->id)->where('category', 'group_messages')->count());
        // Pat isn't in it, so hears nothing.
        $this->assertSame(0, Notification::where('member_id', $this->plain->id)->count());
    }

    public function testAnAskForNobodyAvailableStillPostsAndSaysSo()
    {
        LeaderThreadMember::query()->delete();
        // Lou already leads another group of the run: nobody else may lead.
        $this->group($this->sess, [$this->leaderB], ['pace_unit' => 'mi', 'pace_from_s' => 700]);

        [$status, $body] = $this->ask('committee');

        $this->assertSame(201, $status);
        $this->assertSame(0, $body['notified']);
        $this->assertSame(1, LeaderMessage::count());
    }

    public function testAMemberWhoseUsualPaceDoesNotFitIsNotAsked()
    {
        \App\Models\MemberPreference::create([
            'club_id' => 1, 'member_id' => $this->leaderB->id,
            'pace_unit' => 'mi', 'pace_from_s' => 660, 'pace_to_s' => 720, // 11:00-12:00/mi, far from 5:30-6:00/km
        ]);

        [, $body] = $this->ask('committee');

        $this->assertSame(0, $body['notified']);
    }

    public function testAnAskWithNoPaceAsksForAnyLeader()
    {
        [$status, $body] = $this->api('POST', $this->base() . '/ask', 'committee', []);

        $this->assertSame(201, $status);
        $this->assertNull($body['message']['askFastSPerKm']);
        $this->assertSame(1, $body['notified']);
    }

    public function testAskValidation()
    {
        $this->assertSame(422, $this->ask('committee', ['fastSPerKm' => 100])[0]); // too fast
        $this->assertSame(422, $this->ask('committee', ['slowSPerKm' => 2000])[0]); // too slow
        $this->assertSame(422, $this->ask('committee', ['fastSPerKm' => 400, 'slowSPerKm' => 350])[0]); // backwards
        $this->assertSame(422, $this->api('POST', $this->base() . '/ask', 'committee', ['fastSPerKm' => 330])[0]); // no slow
        $this->assertSame(422, $this->ask('committee', ['id' => 'nope'])[0]);
        $this->assertSame(0, LeaderMessage::count());
    }

    public function testAnAskIsIdempotentOnItsId()
    {
        $id = $this->uuid();
        [$first] = $this->ask('committee', ['id' => $id]);
        [$second, $body] = $this->ask('committee', ['id' => $id]);

        $this->assertSame(201, $first);
        $this->assertSame(200, $second);
        $this->assertSame(1, LeaderMessage::count());
        $this->assertSame($id, $body['message']['id']);
        $this->assertSame(1, Notification::where('member_id', $this->leaderB->id)->where('category', 'leaders_needed')->count());

        // Someone else's id is a conflict.
        $this->assertSame(409, $this->ask('admin', ['id' => $id])[0]);
    }

    // ---- chat -----------------------------------------------------------------------

    public function testMembersPostAndEveryoneInTheThreadHearsAboutIt()
    {
        $this->ask('committee'); // brings Lou in

        [$status, $m] = $this->say('leaderB', 'I can do 9:00 pace');

        $this->assertSame(201, $status);
        $this->assertSame('message', $m['kind']);
        $this->assertSame('member', $m['authorRole']); // asked, not (yet) leading

        [, $body] = $this->read('committee');
        $this->assertSame(['ask', 'message'], array_column($body['items'], 'kind'));

        // Committee, the run's leader and the other committee member hear; the author doesn't.
        foreach ([$this->committee, $this->admin, $this->leaderA] as $who) {
            $this->assertSame(1, Notification::where('dedupe_key', 'leader_msg:' . $this->sess->id)->where('member_id', $who->id)->count());
        }
        $this->assertSame(0, Notification::where('dedupe_key', 'leader_msg:' . $this->sess->id)->where('member_id', $this->leaderB->id)->count());
    }

    public function testMutedMembersAreNotNotified()
    {
        $this->assertSame(200, $this->api('PUT', $this->base() . '/thread', 'leaderA', ['muted' => true])[0]);

        $this->say('committee', 'Who is free?');

        $this->assertSame(0, Notification::where('member_id', $this->leaderA->id)->count());
        $this->assertSame(1, Notification::where('member_id', $this->admin->id)->count());
        [, $body] = $this->read('leaderA');
        $this->assertTrue($body['muted']);
    }

    public function testMessageValidationAndReplay()
    {
        $this->assertSame(422, $this->say('committee', '')[0]);
        $this->assertSame(422, $this->say('committee', str_repeat('x', 1001))[0]);

        $id = $this->uuid();
        $this->assertSame(201, $this->say('committee', 'hello', null, $id)[0]);
        $this->assertSame(200, $this->say('committee', 'hello', null, $id)[0]);
        $this->assertSame(409, $this->say('admin', 'hello', null, $id)[0]);
        $this->assertSame(1, LeaderMessage::count());
    }

    public function testItClosesTwelveHoursAfterTheRunAndWhenCancelled()
    {
        $this->assertSame(201, $this->say('committee', 'now')[0]);

        // The run ends 20:30 London (19:30Z).
        Carbon::setTestNow(Carbon::parse('2026-10-13 07:31:00', 'UTC'));
        [$status, $body] = $this->say('committee', 'too late');
        $this->assertSame(409, $status);
        $this->assertSame('thread_closed', $body['error']);
        $this->assertTrue($this->read('committee')[1]['closed']);

        Carbon::setTestNow(Carbon::parse('2026-10-12 09:00:00', 'UTC'));
        $this->sess->status = 'cancelled';
        $this->sess->save();
        $this->assertSame(409, $this->say('committee', 'cancelled')[0]);
    }

    public function testDeleteAndTombstones()
    {
        $this->ask('committee');
        [, $m] = $this->say('leaderB', 'oops');
        $before = Carbon::now()->toIso8601String();

        // Only the author or the committee.
        $this->assertSame(403, $this->api('DELETE', $this->base() . '/messages/' . $m['id'], 'leaderA')[0]);
        $this->assertSame(404, $this->api('DELETE', $this->base() . '/messages/' . $this->uuid(), 'committee')[0]);

        Carbon::setTestNow(Carbon::now()->addMinute());
        $this->assertSame(204, $this->api('DELETE', $this->base() . '/messages/' . $m['id'], 'leaderB')[0]);
        $this->assertSame(204, $this->api('DELETE', $this->base() . '/messages/' . $m['id'], 'leaderB')[0]); // repeat is fine

        [, $body] = $this->read('committee', '?since=' . urlencode($before));
        $tomb = collect($body['items'])->firstWhere('id', $m['id']);
        $this->assertNotNull($tomb['deletedAt']);
        $this->assertSame('', $tomb['body']);

        [, $fresh] = $this->read('committee');
        $this->assertNotContains($m['id'], array_column($fresh['items'], 'id'));
    }

    // ---- listing and read state -------------------------------------------------------

    public function testTheThreadsListIncludesLeadersThreadsForThoseInThem()
    {
        $this->ask('committee');
        $this->say('leaderB', 'I am in');

        [, $committee] = $this->api('GET', '/threads', 'committee');
        $item = collect($committee['items'])->firstWhere('kind', 'leaders');
        $this->assertNotNull($item);
        $this->assertSame('leaders:' . $this->sess->id, $item['groupId']);
        $this->assertSame($this->sess->id, $item['sessionId']);
        $this->assertSame('Leaders', $item['label']);
        $this->assertSame('I am in', $item['lastMessage']['body']);
        $this->assertSame(1, $item['unreadCount']); // Lou's message; their own ask doesn't count
    }

    public function testUnreadCountsAndMarkRead()
    {
        $this->ask('committee');
        $this->say('leaderB', 'one');
        $this->say('leaderB', 'two');

        $unread = function (string $sub) {
            [, $body] = $this->api('GET', '/threads', $sub);

            return collect($body['items'])->firstWhere('kind', 'leaders')['unreadCount'] ?? null;
        };

        $this->assertSame(2, $unread('committee')); // Lou's two; their own ask doesn't count
        $this->assertSame(3, $unread('leaderA')); // the ask and both
        $this->assertSame(1, Notification::where('member_id', $this->leaderB->id)->whereNull('read_at')->where('category', 'leaders_needed')->count());

        $this->assertSame(204, $this->api('POST', $this->base() . '/messages/read', 'leaderB')[0]);
        $this->assertSame(0, $unread('leaderB'));
        $this->assertSame(0, Notification::where('member_id', $this->leaderB->id)->whereNull('read_at')->count());
        $this->assertSame(2, $unread('committee'));
    }

    public function testPeopleNotInAThreadDoNotSeeItListed()
    {
        $this->ask('committee');

        foreach (['plain', 'going'] as $sub) {
            [, $body] = $this->api('GET', '/threads', $sub);
            $this->assertNull(collect($body['items'])->firstWhere('kind', 'leaders'), $sub);
        }
    }

    // ---- the repeat -------------------------------------------------------------------

    /** A run on Friday 2026-10-16 at 19:00 (club time), with the ask made now. */
    private function futureAsk(): array
    {
        $run = $this->session(['date' => '2026-10-16']);
        [, $body] = $this->ask('committee', [], $run);

        return [$run, $body['message']['id']];
    }

    private function repeatAt(string $utc): int
    {
        Carbon::setTestNow($now = Carbon::parse($utc, 'UTC'));

        return app(LeaderThreadNotifier::class)->renudge($now);
    }

    private function repeats(): int
    {
        return Notification::where('member_id', $this->leaderB->id)->where('dedupe_key', 'like', 'leader_ask_repeat:%')->count();
    }

    public function testAnUnansweredAskIsRepeatedOnceAfterADay()
    {
        [$run, $id] = $this->futureAsk();

        $this->assertSame(0, $this->repeatAt('2026-10-13 08:00')); // 23 hours: too soon
        $this->assertSame(1, $this->repeatAt('2026-10-13 10:00')); // a day on, 11:00 local
        $this->assertSame(1, $this->repeats());
        $this->assertNotNull(LeaderMessage::find($id)->renudged_at);

        $n = Notification::where('dedupe_key', 'leader_ask_repeat:' . $id)->first();
        $this->assertSame('/runs/' . $run->id . '/leaders-chat', $n->data['route']);
        $this->assertSame('leaders_needed', $n->category);

        // Never a second time.
        $this->assertSame(0, $this->repeatAt('2026-10-14 10:00'));
        $this->assertSame(1, $this->repeats());
    }

    public function testNoRepeatOnceSomeoneCoversThePace()
    {
        [$run] = $this->futureAsk();
        // Lou signs up to lead 5:30-6:00/km (about 8:50-9:40/mi) on that run.
        $this->group($run, [$this->leaderB], ['pace_unit' => 'km', 'pace_from_s' => 330, 'pace_to_s' => 360]);

        $this->assertSame(0, $this->repeatAt('2026-10-13 10:00'));
        $this->assertSame(0, $this->repeats());
    }

    public function testNoRepeatToThoseWhoAlreadyAnswered()
    {
        [$run] = $this->futureAsk();
        $this->say('leaderB', 'Sorry, away that night', $run);

        $this->assertSame(0, $this->repeatAt('2026-10-13 10:00'));
    }

    public function testTheRepeatWaitsForASensibleHour()
    {
        [, $id] = $this->futureAsk();

        $this->assertSame(0, $this->repeatAt('2026-10-13 22:30')); // 23:30 local
        $this->assertNull(LeaderMessage::find($id)->renudged_at); // still to come
        $this->assertSame(0, $this->repeatAt('2026-10-14 06:30')); // 07:30 local
        $this->assertSame(1, $this->repeatAt('2026-10-14 07:30')); // 08:30 local
    }

    public function testNoRepeatForARunThatIsAboutToStartOrHasGone()
    {
        [$run, $id] = $this->futureAsk();

        // Two hours before the 19:00 BST start (18:00Z): too late to be useful, and not retried.
        $this->assertSame(0, $this->repeatAt('2026-10-16 16:30'));
        $this->assertNotNull(LeaderMessage::find($id)->renudged_at);
        $this->assertSame(0, $this->repeats());
    }

    public function testPlainMessagesAreNeverRepeated()
    {
        $this->say('committee', 'Anyone free?');

        $this->assertSame(0, $this->repeatAt('2026-10-14 10:00'));
    }
}
