<?php

require_once __DIR__ . '/AppMessagesBase.php';

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadMember;
use App\Models\MemberPreference;
use App\Models\Notification;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Models\SessionSeries;
use App\Services\LeaderThreadNotifier;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;

/**
 * D127: the committee picks who to ask. The pool lists the members who could lead a Monday run (led
 * that series before, or chose the day) with how often and at what pace; an ask can name them.
 *
 * "Now" is Monday 2026-10-12 09:00 UTC. The run is the next Monday, 2026-10-19 at 19:00. Anna led it
 * three times at 9:15, Ben once at 10:30, Cara once as a jog/walk group, and Dee only chose Mondays.
 * $this->committee asks; $this->leaderB (Lou, role leader, never led) is not a candidate.
 */
class AppLeaderAsksTest extends AppMessagesBase
{
    /** @var SessionSeries */
    private $series;
    /** @var ClubSession */
    private $monday;
    /** @var array<string, ClubMember> */
    private $m = [];
    private $nextId = 500;

    protected function setUp(): void
    {
        parent::setUp();

        $this->series = SessionSeries::create([
            'club_id' => 1, 'title' => 'Monday club run', 'weekday' => 1, 'start_time' => '19:00', 'duration_min' => 90,
            'interval_weeks' => 1, 'valid_from' => '2026-01-01', 'valid_until' => null, 'group_mode' => 'paced',
        ]);
        $this->monday = $this->runOn('2026-10-19');

        $this->who('anna');
        $this->who('ben');
        $this->who('cara');
        $this->who('dee');
        $this->led($this->m['anna'], '2026-09-14', 555);
        $this->led($this->m['anna'], '2026-09-21', 555);
        $this->led($this->m['anna'], '2026-09-28', 555);
        $this->led($this->m['ben'], '2026-10-05', 630);
        $this->led($this->m['cara'], '2026-10-05', null, null, 'jog_walk');
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->m['dee']->id, 'pace_unit' => 'mi', 'distance_unit' => 'mi', 'lead_days' => '1']);
    }

    private function who(string $key, string $status = 'active'): ClubMember
    {
        return $this->m[$key] = $this->member('sub-' . $key, $this->nextId++, [], $status, ucfirst($key));
    }

    private function runOn(string $date): ClubSession
    {
        return $this->session(['date' => $date, 'series_id' => $this->series->id, 'occurrence_date' => $date]
            + SessionGenerator::times($date, '19:00', 90, 'Europe/London'));
    }

    private function led(ClubMember $member, string $date, ?int $from, ?int $to = null, string $kind = 'run', string $status = 'confirmed'): void
    {
        $session = ClubSession::where('series_id', $this->series->id)->where('occurrence_date', $date)->first() ?: $this->runOn($date);
        $group = $this->group($session, [], [
            'label' => 'Old', 'status' => 'active', 'kind' => $kind,
            'pace_unit' => $from === null ? null : 'mi', 'pace_from_s' => $from, 'pace_to_s' => $to,
        ]);
        SessionGroupLeader::create(['club_id' => 1, 'group_id' => $group->id, 'member_id' => $member->id, 'status' => $status]);
    }

    private function base(): string
    {
        return '/sessions/' . $this->monday->id . '/leaders-chat';
    }

    private function pool(?string $sub, string $query = ''): array
    {
        return $this->api('GET', $this->base() . '/pool' . $query, $sub);
    }

    /** @return array<string, array> pool entries by lower-case first name */
    private function poolByName(string $query = ''): array
    {
        [, $body] = $this->pool('committee', $query);
        $byName = [];

        foreach ($body['items'] as $item) {
            $byName[strtolower(explode(' ', $item['name'])[0])] = $item;
        }

        return $byName;
    }

    private function askPeople(array $keys, array $data = [], ?string $sub = 'committee'): array
    {
        $ids = array_map(fn ($key) => $this->m[$key]->id, $keys);

        return $this->api('POST', $this->base() . '/ask', $sub, ['memberIds' => $ids] + $data);
    }

    // ---- the pool ------------------------------------------------------------------------

    public function testOnlyTheCommitteeSeesThePool()
    {
        $this->assertSame(200, $this->pool('committee')[0]);
        $this->assertSame(200, $this->pool('admin')[0]);
        $this->assertSame(403, $this->pool('leaderA')[0]);
        $this->assertSame(403, $this->pool('plain')[0]);
        $this->assertSame(401, $this->pool(null)[0]);
        $this->assertSame(404, $this->api('GET', '/sessions/' . $this->uuid() . '/leaders-chat/pool', 'committee')[0]);
    }

    public function testThePoolListsWhoMayLeadWithHowOftenAndAtWhatPace()
    {
        $pool = $this->poolByName();

        $this->assertEqualsCanonicalizing(['anna', 'ben', 'cara', 'dee', 'lou', 'lee'], array_keys($pool));
        $this->assertArrayNotHasKey('pat', $pool); // a plain member who never led and chose no day
        $this->assertSame('new_leader', $pool['lou']['reason']); // holds the leader role, never led
        $this->assertSame('led_day', $pool['lee']['reason']); // led a Monday run that has no series

        $anna = $pool['anna'];
        $this->assertSame($this->m['anna']->id, $anna['memberId']);
        $this->assertSame('led_series', $anna['reason']);
        $this->assertSame(3, $anna['ledCount']);
        $this->assertSame('2026-09-28', $anna['lastLedOn']);
        $this->assertSame(555, $anna['lastLed']['paceFromS']);
        $this->assertNull($anna['lastLed']['paceToS']);
        $this->assertSame('mi', $anna['lastLed']['paceUnit']);
        $this->assertSame(345, $anna['lastLed']['paceFromSPerKm']);
        $this->assertSame('jog_walk', $pool['cara']['lastLed']['kind']);

        $dee = $pool['dee'];
        $this->assertSame('chose_day', $dee['reason']);
        $this->assertSame(0, $dee['ledCount']);
        $this->assertNull($dee['lastLed']);

        // The regulars come first.
        $names = array_keys($pool);
        $this->assertSame('anna', $names[0]);
        $this->assertSame(0, $pool[end($names)]['ledCount']);
    }

    public function testThePoolSaysWhoFitsTheStretchBeingFilled()
    {
        // 8:15 to 9:45/mi is 308 to 364 s/km. Anna (9:15) fits; Ben (10:30) is more than 30 s/mi beyond it.
        $pool = $this->poolByName('?fastSPerKm=308&slowSPerKm=364');
        $this->assertTrue($pool['anna']['fitsRange']);
        $this->assertFalse($pool['ben']['fitsRange']);
        $this->assertFalse($pool['cara']['fitsRange']);
        $this->assertFalse($pool['dee']['fitsRange']); // no led pace to go on

        // 9:30 to 10:15 (354 to 382): Anna's 9:15 is within 30 s of 9:30, so she fits too, and Ben's 10:30 is within 30 s of 10:15.
        $pool = $this->poolByName('?fastSPerKm=354&slowSPerKm=382');
        $this->assertTrue($pool['anna']['fitsRange']);
        $this->assertTrue($pool['ben']['fitsRange']);

        // "Slower than 11:30" (429 s/km and up, open ended): nobody's usual pace is near it.
        $pool = $this->poolByName('?fastSPerKm=429&slowSPerKm=900');
        $this->assertSame([], array_keys(array_filter($pool, fn ($e) => $e['fitsRange'])));

        // A jog/walk group is for those whose last group was jog/walk.
        $pool = $this->poolByName('?kind=jog_walk');
        $this->assertTrue($pool['cara']['fitsRange']);
        $this->assertFalse($pool['anna']['fitsRange']);

        // Fitting people are listed before the rest, then the regulars.
        [, $body] = $this->pool('committee', '?fastSPerKm=354&slowSPerKm=382');
        $top = array_map(fn ($e) => explode(' ', $e['name'])[0], array_slice($body['items'], 0, 3));
        $this->assertSame('Anna', $top[0]); // the most led
        $this->assertEqualsCanonicalizing(['Ben', 'Lee'], array_slice($top, 1)); // Lee's 9:00-9:30 group on the 12th fits too
        $this->assertEqualsCanonicalizing([true, true, true], array_map(fn ($e) => $e['fitsRange'], array_slice($body['items'], 0, 3)));
    }

    public function testThePoolFlagsWhoCannotBeAskedAndPutsThemLast()
    {
        $this->group($this->monday, [$this->m['ben']], ['pace_unit' => 'mi', 'pace_from_s' => 630]); // already leading
        $this->attend($this->monday, $this->m['cara'], 'not_going');
        $this->askPeople(['dee']);

        $pool = $this->poolByName();

        $this->assertTrue($pool['ben']['leadingThisRun']);
        $this->assertTrue($pool['cara']['notGoing']);
        $this->assertTrue($pool['dee']['askedRecently']);
        $this->assertNotNull($pool['dee']['askedAt']);
        $this->assertFalse($pool['anna']['leadingThisRun'] || $pool['anna']['notGoing'] || $pool['anna']['askedRecently']);
        $this->assertSame('anna', array_keys($pool)[0]);

        Carbon::setTestNow(Carbon::now()->addHours(25));
        $this->assertFalse($this->poolByName()['dee']['askedRecently']); // a day on, they can be asked again
    }

    public function testThePoolLeavesOutMembersWhoHidTheSeriesAndTheCaller()
    {
        \App\Models\MemberSeriesPref::create(['club_id' => 1, 'member_id' => $this->m['ben']->id, 'series_id' => $this->series->id, 'mode' => 'hide']);
        $this->led($this->committee, '2026-10-05', 600); // the committee member led once: still not listed to themselves

        $pool = $this->poolByName();

        $this->assertArrayNotHasKey('ben', $pool);
        $this->assertArrayNotHasKey('cam', $pool);
    }

    public function testThePoolValidatesItsQuery()
    {
        $this->assertSame(422, $this->pool('committee', '?fastSPerKm=100&slowSPerKm=300')[0]);
        $this->assertSame(422, $this->pool('committee', '?fastSPerKm=300')[0]); // a stretch has two ends
        $this->assertSame(422, $this->pool('committee', '?kind=walk')[0]);
    }

    // ---- asking named people --------------------------------------------------------------

    public function testAnAskCanNameThePeopleItIsFor()
    {
        [$status, $body] = $this->askPeople(['anna', 'ben'], ['fastSPerKm' => 308, 'slowSPerKm' => 364, 'note' => 'Back to the usual']);

        $this->assertSame(201, $status);
        $this->assertSame(2, $body['notified']);
        $this->assertSame([], $body['skipped']);

        $message = $body['message'];
        $this->assertSame('ask', $message['kind']);
        $this->assertSame([$this->m['anna']->id, $this->m['ben']->id], $message['askedMemberIds']);
        $this->assertSame(2, count($message['askedNames']));
        $this->assertStringStartsWith('Anna', $message['askedNames'][0]);
        $this->assertNull($message['askKind']);

        // Only they are asked and brought into the thread; Cara and Dee are not.
        $this->assertEqualsCanonicalizing([$this->m['anna']->id, $this->m['ben']->id], LeaderThreadMember::pluck('member_id')->all());
        $this->assertSame(0, Notification::where('member_id', $this->m['cara']->id)->count());
        $this->assertSame(0, Notification::where('member_id', $this->m['dee']->id)->count());

        $n = Notification::where('member_id', $this->m['anna']->id)->where('category', 'leaders_needed')->first();
        $this->assertSame('/runs/' . $this->monday->id . '/leaders-chat', $n->data['route']);
        $this->assertStringStartsWith('Can you lead on', $n->title);
        $this->assertStringContainsString('Committee asked you: can you lead a group between 8:15 and 9:45/mi at 7pm on', $n->body);
        $this->assertStringContainsString('Back to the usual', $n->body);
    }

    public function testTheStretchIsSpokenInTheMembersOwnUnitAndOpenEndsReadAsFasterOrSlowerThan()
    {
        MemberPreference::create(['club_id' => 1, 'member_id' => $this->m['anna']->id, 'pace_unit' => 'km', 'distance_unit' => 'km']);

        $this->askPeople(['anna', 'ben'], ['fastSPerKm' => 308, 'slowSPerKm' => 364]);
        $this->assertStringContainsString('between 5:10 and 6:05/km', Notification::where('member_id', $this->m['anna']->id)->first()->body);
        $this->assertStringContainsString('between 8:15 and 9:45/mi', Notification::where('member_id', $this->m['ben']->id)->first()->body);

        $this->tick(60 * 60 * 25);
        $this->askPeople(['ben'], ['fastSPerKm' => 150, 'slowSPerKm' => 317]);
        $this->askPeople(['anna'], ['fastSPerKm' => 429, 'slowSPerKm' => 900]);
        $bodies = Notification::whereIn('member_id', [$this->m['ben']->id, $this->m['anna']->id])->pluck('body')->implode(' | ');
        $this->assertStringContainsString('a group faster than 8:30/mi', $bodies);
        $this->assertStringContainsString('a group slower than 7:10/km', $bodies); // 11:30/mi is 7:09/km: the nearest 5 s
    }

    public function testAJogWalkAskNamesNoPace()
    {
        [$status, $body] = $this->askPeople(['cara'], ['kind' => 'jog_walk', 'fastSPerKm' => 300, 'slowSPerKm' => 350]);

        $this->assertSame(201, $status);
        $this->assertSame('jog_walk', $body['message']['askKind']);
        $this->assertNull($body['message']['askFastSPerKm']); // the pace is ignored
        $this->assertStringContainsString('can you lead a jog/walk group at', Notification::where('member_id', $this->m['cara']->id)->first()->body);
    }

    public function testAskingWithNoPaceAsksThemForTheRun()
    {
        [, $body] = $this->askPeople(['anna']);

        $this->assertSame(1, $body['notified']);
        $this->assertStringContainsString('can you lead at 7pm on', Notification::where('member_id', $this->m['anna']->id)->first()->body);
    }

    public function testPeopleWhoCannotBeAskedAreSkippedWithAReason()
    {
        $this->group($this->monday, [$this->m['ben']], ['pace_unit' => 'mi', 'pace_from_s' => 630]);
        $this->attend($this->monday, $this->m['cara'], 'not_going');
        $this->askPeople(['dee']); // Dee is asked now ...
        $this->m['gone'] = $this->member('sub-gone', 600, [], 'lapsed', 'Gone');

        [, $body] = $this->askPeople(['anna', 'ben', 'cara', 'dee', 'gone']);

        $this->assertSame(1, $body['notified']); // only Anna
        $this->assertSame([
            ['memberId' => $this->m['ben']->id, 'reason' => 'leading'],
            ['memberId' => $this->m['cara']->id, 'reason' => 'not_going'],
            ['memberId' => $this->m['dee']->id, 'reason' => 'asked_recently'],
            ['memberId' => $this->m['gone']->id, 'reason' => 'inactive'],
        ], $body['skipped']);
        // The message shows who it really went to.
        $this->assertSame([$this->m['anna']->id], $body['message']['askedMemberIds']);
        // Ben leads a group of the run, so he is in the thread and hears it as a message, but he is not asked.
        $this->assertSame(0, Notification::where('member_id', $this->m['ben']->id)->where('category', 'leaders_needed')->count());
    }

    public function testAskingAgainAfterADayWorksAndBumpsTheAskedTime()
    {
        $this->askPeople(['dee']);
        $first = LeaderThreadMember::where('member_id', $this->m['dee']->id)->first()->updated_at;

        $this->tick(60 * 60 * 25);
        [, $body] = $this->askPeople(['dee']);

        $this->assertSame(1, $body['notified']);
        $this->assertTrue(LeaderThreadMember::where('member_id', $this->m['dee']->id)->first()->updated_at->gt($first));
        $this->assertSame(1, LeaderThreadMember::where('member_id', $this->m['dee']->id)->count());
    }

    public function testTheAskerIsNeverAskedAndOnlyTheCommitteeMayAskByName()
    {
        [, $body] = $this->api('POST', $this->base() . '/ask', 'committee', ['memberIds' => [$this->committee->id, $this->m['anna']->id]]);
        $this->assertSame(1, $body['notified']);
        $this->assertSame([], $body['skipped']);

        $this->assertSame(403, $this->askPeople(['ben'], [], 'leaderA')[0]);
        $this->assertSame(403, $this->askPeople(['ben'], [], 'plain')[0]);
    }

    public function testTheNamedPeopleAreValidated()
    {
        $id = $this->m['anna']->id;

        $this->assertSame(422, $this->api('POST', $this->base() . '/ask', 'committee', ['memberIds' => []])[0]);
        $this->assertSame(422, $this->api('POST', $this->base() . '/ask', 'committee', ['memberIds' => ['nope']])[0]);
        $this->assertSame(422, $this->api('POST', $this->base() . '/ask', 'committee', ['memberIds' => array_fill(0, 31, $id)])[0]);
        $this->assertSame(422, $this->api('POST', $this->base() . '/ask', 'committee', ['kind' => 'jog_walk'])[0]); // a kind needs people
        $this->assertSame(422, $this->askPeople(['anna'], ['kind' => 'walk'])[0]);
        $this->assertSame(0, LeaderMessage::count());
    }

    public function testNamedPeopleOutsideTheClubAreSkippedAsInactive()
    {
        [, $body] = $this->api('POST', $this->base() . '/ask', 'committee', ['memberIds' => [$this->uuid()]]);

        $this->assertSame(0, $body['notified']);
        $this->assertSame('inactive', $body['skipped'][0]['reason']);
    }

    public function testAnAskWithoutNamesStillGoesToTheComputedAudience()
    {
        [, $body] = $this->api('POST', $this->base() . '/ask', 'committee', ['fastSPerKm' => 330, 'slowSPerKm' => 360]);

        $this->assertNull($body['message']['askedMemberIds']);
        $this->assertNull($body['message']['askedNames']);
        $this->assertGreaterThan(0, $body['notified']);
        $this->assertStringNotContainsString('Committee asked you', Notification::where('category', 'leaders_needed')->first()->body);
    }

    public function testReplayingANamedAskChangesNothing()
    {
        $id = $this->uuid();
        [$first, $one] = $this->askPeople(['anna'], ['id' => $id]);
        [$second, $two] = $this->askPeople(['anna'], ['id' => $id]);

        $this->assertSame([201, 200], [$first, $second]);
        $this->assertSame($one['message'], $two['message']);
        $this->assertSame(0, $two['notified']);
        $this->assertSame([], $two['skipped']);
        $this->assertSame(1, LeaderMessage::count());
        $this->assertSame(1, Notification::where('member_id', $this->m['anna']->id)->where('category', 'leaders_needed')->count());
    }

    public function testTheThreadListShowsWhoAnAskNamed()
    {
        $this->askPeople(['anna', 'ben'], ['fastSPerKm' => 308, 'slowSPerKm' => 364]);

        [, $body] = $this->api('GET', $this->base() . '/messages', 'committee');
        $ask = collect($body['items'])->firstWhere('kind', 'ask');

        $this->assertCount(2, $ask['askedNames']);
        $this->assertSame([$this->m['anna']->id, $this->m['ben']->id], $ask['askedMemberIds']);

        // Someone who was asked can read it and see the chips too.
        [$status, $theirs] = $this->api('GET', $this->base() . '/messages', 'sub-anna');
        $this->assertSame(200, $status);
        $this->assertCount(2, $theirs['items'][0]['askedNames']);

        // The rest of the thread hears it in words, not as the older pace text.
        $this->group($this->monday, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 600]);
        $this->tick(60 * 60 * 25);
        $this->askPeople(['dee'], ['fastSPerKm' => 308, 'slowSPerKm' => 364]);
        $heard = Notification::where('member_id', $this->leaderA->id)->where('category', 'group_messages')->first();
        $this->assertStringContainsString('Can anyone lead a group between 8:15 and 9:45/mi?', $heard->body);
    }

    // ---- the repeat -----------------------------------------------------------------------

    private function repeatAt(string $utc): int
    {
        Carbon::setTestNow($now = Carbon::parse($utc, 'UTC'));

        return app(LeaderThreadNotifier::class)->renudge($now);
    }

    private function repeated(string $key): int
    {
        return Notification::where('member_id', $this->m[$key]->id)->where('dedupe_key', 'like', 'leader_ask_repeat:%')->count();
    }

    public function testANamedAskRepeatsOnlyToTheNamedWhoHaveNotAnswered()
    {
        $this->askPeople(['anna', 'ben'], ['fastSPerKm' => 308, 'slowSPerKm' => 364]);
        // Cara was in the thread from an older ask on the same run, but this ask didn't name her.
        LeaderThreadMember::create(['club_id' => 1, 'session_id' => $this->monday->id, 'member_id' => $this->m['cara']->id]);
        $this->api('POST', $this->base() . '/messages', 'sub-ben', ['body' => 'Can\'t this week']);

        $this->assertSame(1, $this->repeatAt('2026-10-13 10:00'));
        $this->assertSame(1, $this->repeated('anna'));
        $this->assertSame(0, $this->repeated('ben')); // answered
        $this->assertSame(0, $this->repeated('cara')); // not named

        $n = Notification::where('member_id', $this->m['anna']->id)->where('dedupe_key', 'like', 'leader_ask_repeat:%')->first();
        $this->assertStringContainsString('Can you lead a group between 8:15 and 9:45/mi', $n->body);
    }

    public function testAJogWalkAskIsNotCoveredByAPacedGroup()
    {
        $this->askPeople(['cara'], ['kind' => 'jog_walk']);
        $this->group($this->monday, [$this->m['ben']], ['pace_unit' => 'mi', 'pace_from_s' => 630]);

        $this->assertSame(1, $this->repeatAt('2026-10-13 10:00')); // a paced group doesn't cover it
    }

    public function testAJogWalkAskIsCoveredOnceAJogWalkGroupHasALeader()
    {
        $this->askPeople(['cara'], ['kind' => 'jog_walk']);
        $this->group($this->monday, [$this->m['ben']], ['kind' => 'jog_walk', 'label' => 'Jog/walk']);

        $this->assertSame(0, $this->repeatAt('2026-10-13 10:00'));
    }

    public function testAStretchAskIsCoveredWhenALedGroupOverlapsIt()
    {
        $this->askPeople(['anna'], ['fastSPerKm' => 308, 'slowSPerKm' => 364]); // 8:15 to 9:45
        $this->group($this->monday, [$this->m['ben']], ['pace_unit' => 'mi', 'pace_from_s' => 540, 'pace_to_s' => 555]);

        $this->assertSame(0, $this->repeatAt('2026-10-13 10:00'));
    }
}
