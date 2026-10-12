<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\Club;
use App\Models\ClubSession;
use App\Models\EventLocation;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionSeries;
use App\Services\ThreadAccess;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

/**
 * Phase 8a: the `events` and `race` group modes, event groups (create, de-duplicate, edit,
 * delete, join), the race's single group, plan names inside an event, and chat participants.
 * "Now" is Monday 2026-10-12 09:00Z; the default run is that evening.
 */
class AppEventGroupsTest extends AppGroupsBase
{
    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();
    }

    private function events(array $overrides = []): ClubSession
    {
        return $this->session(['group_mode' => 'events', 'title' => 'parkrun'] + $overrides);
    }

    private function race(array $overrides = []): ClubSession
    {
        return $this->session(['group_mode' => 'race', 'title' => 'Droitwich 10k'] + $overrides);
    }

    private function location(string $name = 'Worcester parkrun', array $overrides = []): EventLocation
    {
        return EventLocation::create($overrides + [
            'club_id' => 1, 'kind' => 'parkrun', 'name' => $name, 'slug' => strtolower(strtok($name, ' ')), 'source' => 'import',
        ]);
    }

    private function eventGroup(ClubSession $s, array $overrides = []): SessionGroup
    {
        return SessionGroup::create($overrides + [
            'club_id' => 1, 'session_id' => $s->id, 'kind' => 'event', 'label' => 'Worcester parkrun', 'status' => 'active',
            'created_by_member_id' => $this->plain->id,
        ]);
    }

    private function add(string $sub, ClubSession $s, array $data): array
    {
        return $this->api('POST', "/sessions/{$s->id}/groups", $sub, $data);
    }

    // ---- modes ---------------------------------------------------------------------------

    public function testTheModeListsGainEventsAndRace()
    {
        $this->assertSame(['paced', 'single', 'open', 'routes', 'events', 'race'], SessionSeries::GROUP_MODES);
        $this->assertContains('event', SessionGroup::KINDS);
    }

    public function testSeriesAcceptsEventsAndRejectsRace()
    {
        $base = ['title' => 'parkrun', 'weekday' => 6, 'startTime' => '09:00'];

        [$status, $body] = $this->api('POST', '/series', 'committee', $base + ['groupMode' => 'events']);
        $this->assertSame(201, $status);
        $this->assertSame('events', $body['groupMode']);
        $this->assertNull($body['venueId']);

        [$status, $body] = $this->api('POST', '/series', 'committee', $base + ['groupMode' => 'race']);
        $this->assertSame(422, $status);
        $this->assertSame('Races are one-off runs.', $body['errors']['groupMode'][0]);

        [$status, $body] = $this->api('POST', '/series', 'committee', $base + ['groupMode' => 'bogus']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('groupMode', $body['errors']);

        $this->assertSame(1, SessionSeries::count());
    }

    public function testChangingASeriesToRaceIsRejectedToo()
    {
        [, $series] = $this->api('POST', '/series', 'committee', ['title' => 'parkrun', 'weekday' => 6, 'startTime' => '09:00', 'groupMode' => 'events']);

        [$status, $body] = $this->api('PATCH', "/series/{$series['id']}", 'committee', ['groupMode' => 'race']);

        $this->assertSame(422, $status);
        $this->assertArrayHasKey('groupMode', $body['errors']);
        $this->assertSame('events', SessionSeries::find($series['id'])->group_mode);
    }

    public function testAdHocRunsAcceptEveryModeWithoutAVenue()
    {
        foreach (SessionSeries::GROUP_MODES as $mode) {
            [$status, $body] = $this->api('POST', '/sessions', 'committee', [
                'title' => "Run $mode", 'localDate' => '2026-10-17', 'startTime' => '09:00', 'groupMode' => $mode,
            ]);

            $this->assertSame(201, $status, $mode);
            $this->assertSame($mode, $body['groupMode']);
            $this->assertNull($body['venueId']);
        }

        [$status, $body] = $this->api('POST', '/sessions', 'committee', [
            'title' => 'x', 'localDate' => '2026-10-17', 'startTime' => '09:00', 'groupMode' => 'bogus',
        ]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('groupMode', $body['errors']);
    }

    public function testTheGeneratorCopiesTheEventsModeAndCreatesNoGroups()
    {
        $this->api('POST', '/series', 'committee', ['title' => 'parkrun', 'weekday' => 6, 'startTime' => '09:00', 'groupMode' => 'events']);

        $sessions = ClubSession::all();

        $this->assertGreaterThan(3, $sessions->count());
        $this->assertSame(['events'], $sessions->pluck('group_mode')->unique()->values()->all());
        $this->assertSame(0, SessionGroup::count());
    }

    // ---- creating event groups -------------------------------------------------------------

    public function testAnyLinkedMemberAddsAnEventFromALocation()
    {
        $s = $this->events();
        $loc = $this->location();
        $this->tick();
        $before = $this->sessionUpdatedAt($s);

        [$status, $body] = $this->add('plain', $s, ['locationId' => $loc->id]);

        $this->assertSame(201, $status);
        $this->assertSame('event', $body['kind']);
        $this->assertSame('Worcester parkrun', $body['label']);
        $this->assertSame($loc->id, $body['locationId']);
        $this->assertSame($this->plain->id, $body['createdByMemberId']);
        $this->assertSame('active', $body['status']);
        $this->assertSame([], $body['leaders']);
        $this->assertNull($body['paceFromS']);
        $this->assertSame(1, $body['goingCount']);

        $row = SessionAttendee::where('session_id', $s->id)->where('member_id', $this->plain->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertSame($body['id'], $row->group_id);
        $this->assertNotSame($before, $this->sessionUpdatedAt($s));
        $this->assertSame(0, \Illuminate\Support\Facades\DB::table('session_group_leaders')->count());
    }

    public function testTheSameLocationOnTheSameRunReturnsTheExistingGroup()
    {
        $s = $this->events();
        $loc = $this->location();

        [, $first] = $this->add('plain', $s, ['locationId' => $loc->id]);
        [$status, $second] = $this->add('leaderA', $s, ['locationId' => $loc->id, 'label' => 'Ignored']);

        $this->assertSame(200, $status);
        $this->assertSame($first['id'], $second['id']);
        $this->assertSame('Worcester parkrun', $second['label']);
        $this->assertSame(2, $second['goingCount']);
        $this->assertSame(1, SessionGroup::where('session_id', $s->id)->count());

        $row = SessionAttendee::where('member_id', $this->leaderA->id)->first();
        $this->assertSame('going', $row->status);
        $this->assertSame($first['id'], $row->group_id);

        // Another run of the same location has its own group.
        $other = $this->events(['date' => '2026-10-19']);
        [$status, $third] = $this->add('plain', $other, ['locationId' => $loc->id]);
        $this->assertSame(201, $status);
        $this->assertNotSame($first['id'], $third['id']);
    }

    public function testADeletedGroupDoesNotBlockAddingTheLocationAgain()
    {
        $s = $this->events();
        $loc = $this->location();
        [, $first] = $this->add('plain', $s, ['locationId' => $loc->id]);
        $this->api('DELETE', "/groups/{$first['id']}", 'plain');

        [$status, $second] = $this->add('plain', $s, ['locationId' => $loc->id]);

        $this->assertSame(201, $status);
        $this->assertNotSame($first['id'], $second['id']);
    }

    public function testALabelOverridesTheLocationNameAndALongNameIsClipped()
    {
        $s = $this->events();
        $loc = $this->location('Worcester parkrun');
        $long = $this->location(str_repeat('x', 120), ['slug' => 'long']);

        [, $named] = $this->add('plain', $s, ['locationId' => $loc->id, 'label' => '  Worcester (with the dog)  ']);
        [, $clipped] = $this->add('plain', $s, ['locationId' => $long->id]);

        $this->assertSame('Worcester (with the dog)', $named['label']);
        $this->assertSame(80, mb_strlen($clipped['label']));
    }

    public function testAFreeTextEventNeedsOnlyALabelAndIsNotDeduplicated()
    {
        $s = $this->events();

        [$status, $a] = $this->add('plain', $s, ['label' => 'Bushy parkrun', 'description' => 'Meet at the cafe, 2 seats', 'distanceValue' => 5, 'distanceUnit' => 'km']);
        [$status2, $b] = $this->add('leaderA', $s, ['label' => 'Bushy parkrun']);

        $this->assertSame(201, $status);
        $this->assertSame(201, $status2);
        $this->assertNotSame($a['id'], $b['id']);
        $this->assertNull($a['locationId']);
        $this->assertSame('Meet at the cafe, 2 seats', $a['description']);
        $this->assertEquals(5, $a['distanceValue']);
        $this->assertSame(5000, $a['distanceM']);
    }

    public function testAnEventNeedsALocationOrALabel()
    {
        $s = $this->events();

        foreach ([[], ['label' => '  '], ['description' => 'x']] as $data) {
            [$status, $body] = $this->add('plain', $s, $data);
            $this->assertSame(422, $status);
            $this->assertArrayHasKey('label', $body['errors']);
        }

        [$status, $body] = $this->add('plain', $s, ['label' => 'x', 'distanceValue' => 5]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('distanceUnit', $body['errors']);

        $this->assertSame(0, SessionGroup::count());
    }

    public function testALocationMustBeALiveOneOfThisClub()
    {
        $s = $this->events();
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other', 'slug' => 'other', 'timezone' => 'Europe/London', 'created_at' => '2026-01-01', 'updated_at' => '2026-01-01']);
        $foreign = EventLocation::create(['club_id' => 2, 'kind' => 'parkrun', 'name' => 'Bushy parkrun', 'slug' => 'bushy']);
        $deleted = $this->location('Gone parkrun');
        $deleted->delete();

        foreach ([$foreign->id, $deleted->id, '5b1ebc59-3ab4-4f0d-9c4b-111111111111', 'not-a-uuid'] as $id) {
            [$status, $body] = $this->add('plain', $s, ['locationId' => $id, 'label' => 'Fallback']);
            $this->assertSame(422, $status, $id);
            $this->assertArrayHasKey('locationId', $body['errors'], $id);
        }

        $this->assertSame(0, SessionGroup::count());
    }

    public function testPaceFieldsAndLeadAreRejectedOnPaceFromS()
    {
        $s = $this->events();

        foreach ([['paceUnit' => 'mi'], ['paceFromS' => 570], ['paceToS' => 600], ['paceUnit' => 'mi', 'paceFromS' => 570, 'paceToS' => 600], ['lead' => true]] as $extra) {
            [$status, $body] = $this->add('plain', $s, ['label' => 'Worcester parkrun'] + $extra);
            $this->assertSame(422, $status, json_encode($extra));
            $this->assertArrayHasKey('paceFromS', $body['errors'], json_encode($extra));
        }

        // Explicit nulls and lead=false are fine.
        [$status] = $this->add('plain', $s, ['label' => 'Worcester parkrun', 'paceFromS' => null, 'paceUnit' => null, 'lead' => false]);
        $this->assertSame(201, $status);
        $this->assertSame(1, SessionGroup::count());
    }

    public function testTheKindIsForcedToEvent()
    {
        $s = $this->events();

        [$status, $body] = $this->add('plain', $s, ['label' => 'Worcester parkrun', 'kind' => 'route']);

        $this->assertSame(201, $status);
        $this->assertSame('event', $body['kind']);
    }

    public function testEventGroupsOnlyBelongToEventRuns()
    {
        $paced = $this->session();
        [$status, $body] = $this->add('committee', $paced, ['label' => 'x', 'kind' => 'event', 'lead' => true]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('kind', $body['errors']);

        $loc = $this->location();
        [$status, $body] = $this->add('plain', $paced, ['paceUnit' => 'mi', 'paceFromS' => 570, 'lead' => true, 'locationId' => $loc->id]);
        $this->assertSame(201, $status);
        $this->assertNull($body['locationId']); // locationId means nothing on a pace group
        $this->assertSame('run', $body['kind']);
    }

    public function testRaceRunsAndClosedRunsRefuseNewEvents()
    {
        $race = $this->race();
        [$status, $body] = $this->add('plain', $race, ['label' => 'Another']);
        $this->assertSame(409, $status);
        $this->assertSame('race_group_fixed', $body['error']);
        $this->assertSame(0, SessionGroup::where('session_id', $race->id)->count());

        $past = $this->events(['date' => '2026-10-05']);
        [$status, $body] = $this->add('plain', $past, ['label' => 'Worcester parkrun']);
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);

        $cancelled = $this->events(['date' => '2026-10-19', 'status' => 'cancelled']);
        [$status, $body] = $this->add('plain', $cancelled, ['label' => 'Worcester parkrun']);
        $this->assertSame(409, $status);
        $this->assertSame('session_cancelled', $body['error']);

        [$status] = $this->add('plain', $past, ['locationId' => $this->location()->id]);
        $this->assertSame(409, $status, 'a duplicate is not an exception to the closed rule');
        $this->assertSame(0, SessionAttendee::count());
    }

    public function testCreatingTwiceWithTheSameIdIsIdempotent()
    {
        $s = $this->events();
        $id = '7d9f4e5a-1b2c-4d3e-8f90-123456789abc';

        [$first, $a] = $this->add('plain', $s, ['id' => $id, 'label' => 'Worcester parkrun']);
        [$second, $b] = $this->add('plain', $s, ['id' => $id, 'label' => 'Worcester parkrun']);

        $this->assertSame([201, 200], [$first, $second]);
        $this->assertSame($id, $a['id']);
        $this->assertSame($id, $b['id']);
        $this->assertSame(1, SessionGroup::count());

        // Another run cannot claim the id.
        $other = $this->events(['date' => '2026-10-19']);
        [$status, $body] = $this->add('plain', $other, ['id' => $id, 'label' => 'Worcester parkrun']);
        $this->assertSame(409, $status);
        $this->assertSame('conflict', $body['error']);
    }

    public function testAddingAnEventMovesTheCreatorOutOfTheirPreviousEvent()
    {
        $s = $this->events();
        [, $a] = $this->add('plain', $s, ['label' => 'Worcester parkrun']);
        [, $b] = $this->add('plain', $s, ['label' => 'Bushy parkrun']);

        $this->assertSame($b['id'], SessionAttendee::where('member_id', $this->plain->id)->first()->group_id);
        [, $session] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
        $counts = collect($session['items'][0]['groups'])->pluck('goingCount', 'id')->all();
        $this->assertSame([$a['id'] => 0, $b['id'] => 1], $counts);
    }

    public function testTheSessionPayloadCarriesTheNewGroupFields()
    {
        $s = $this->events();
        $loc = $this->location();
        $this->add('plain', $s, ['locationId' => $loc->id]);
        $this->add('leaderA', $s, ['label' => 'Bushy parkrun']);

        [$status, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'coord');

        $this->assertSame(200, $status);
        $groups = $body['items'][0]['groups'];
        $this->assertCount(2, $groups);
        $this->assertSame($loc->id, $groups[0]['locationId']);
        $this->assertSame($this->plain->id, $groups[0]['createdByMemberId']);
        $this->assertNull($groups[1]['locationId']);
        $this->assertSame($this->leaderA->id, $groups[1]['createdByMemberId']);
        $this->assertSame(2, $body['items'][0]['summary']['goingCount']);
        $this->assertSame(2, $body['items'][0]['summary']['groupCount']);
    }

    // ---- race runs ---------------------------------------------------------------------------

    public function testCreatingARaceCreatesItsSingleGroup()
    {
        $id = '11111111-2222-4333-8444-555555555555';
        [$status, $body] = $this->api('POST', '/sessions', 'committee', [
            'id' => $id, 'title' => 'Droitwich 10k', 'localDate' => '2026-10-18', 'startTime' => '10:00', 'groupMode' => 'race',
        ]);

        $this->assertSame(201, $status);
        $this->assertCount(1, $body['groups']);
        $group = $body['groups'][0];
        $this->assertSame('event', $group['kind']);
        $this->assertSame('Droitwich 10k', $group['label']);
        $this->assertSame('active', $group['status']);
        $this->assertSame([], $group['leaders']);
        $this->assertNull($group['locationId']);
        $this->assertSame(0, $group['goingCount']);
        $this->assertSame($id, $group['sessionId']);

        // A replay of the same id does not add a second group.
        [$status, $replay] = $this->api('POST', '/sessions', 'committee', [
            'id' => $id, 'title' => 'Droitwich 10k', 'localDate' => '2026-10-18', 'startTime' => '10:00', 'groupMode' => 'race',
        ]);
        $this->assertSame(200, $status);
        $this->assertCount(1, $replay['groups']);
        $this->assertSame(1, SessionGroup::count());
    }

    public function testOnlyTheCommitteeCreatesARaceAndNoGroupAppearsForOthers()
    {
        [$status] = $this->api('POST', '/sessions', 'plain', [
            'title' => 'Droitwich 10k', 'localDate' => '2026-10-18', 'startTime' => '10:00', 'groupMode' => 'race',
        ]);

        $this->assertSame(403, $status);
        $this->assertSame(0, SessionGroup::count());
    }

    public function testEventsAndOtherModesCreateNoGroupAtSessionCreate()
    {
        foreach (['events', 'paced', 'open'] as $mode) {
            $this->api('POST', '/sessions', 'committee', ['title' => "Run $mode", 'localDate' => '2026-10-18', 'startTime' => '10:00', 'groupMode' => $mode]);
        }

        $this->assertSame(0, SessionGroup::count());
    }

    public function testPeopleJoinARaceWithTheNormalAttendanceCall()
    {
        [, $session] = $this->api('POST', '/sessions', 'committee', [
            'title' => 'Droitwich 10k', 'localDate' => '2026-10-18', 'startTime' => '10:00', 'groupMode' => 'race',
        ]);
        $gid = $session['groups'][0]['id'];

        [$status, $row] = $this->api('PUT', "/sessions/{$session['id']}/attendance", 'plain', ['status' => 'going', 'groupId' => $gid]);
        $this->assertSame(200, $status);
        $this->assertSame($gid, $row['groupId']);

        [, $after] = $this->api('GET', '/sessions?from=2026-10-18&to=2026-10-18', 'leaderA');
        $this->assertSame(1, $after['items'][0]['groups'][0]['goingCount']);
    }

    public function testTheRaceGroupFollowsTheTitleAndCannotBeDeleted()
    {
        $race = $this->race(['date' => '2026-10-18']);
        $group = $this->eventGroup($race, ['label' => 'Droitwich 10k', 'created_by_member_id' => $this->committee->id]);

        $this->api('PATCH', "/sessions/{$race->id}", 'committee', ['title' => 'Droitwich Half']);
        $this->assertSame('Droitwich Half', SessionGroup::find($group->id)->label);

        foreach (['committee', 'admin', 'coord', 'plain'] as $sub) {
            [$status, $body] = $this->api('DELETE', "/groups/{$group->id}", $sub);
            $this->assertContains($status, [403, 409], $sub);
            $sub === 'plain' ? $this->assertSame('forbidden', $body['error']) : $this->assertSame('race_group_fixed', $body['error'], $sub);
        }

        $this->assertNotNull(SessionGroup::find($group->id));
    }

    // ---- editing and deleting event groups -----------------------------------------------------

    public function testWhoMayEditAnEventGroup()
    {
        $s = $this->events();
        $g = $this->eventGroup($s); // created by plain

        foreach (['leaderA' => 403, 'leaderB' => 403, 'plain' => 200, 'coord' => 200, 'committee' => 200, 'admin' => 200] as $sub => $expected) {
            [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", $sub, ['description' => "By $sub"]);
            $this->assertSame($expected, $status, $sub);

            if ($expected === 200) {
                $this->assertSame("By $sub", $body['description']);
            } else {
                $this->assertSame('forbidden', $body['error']);
            }
        }
    }

    public function testEditingAnEventGroupFields()
    {
        $s = $this->events();
        $loc = $this->location();
        $g = $this->eventGroup($s, ['location_id' => $loc->id]);

        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', [
            'label' => 'Worcester parkrun (cafe after)', 'description' => str_repeat('a', 1000), 'distanceValue' => 5, 'distanceUnit' => 'km',
        ]);

        $this->assertSame(200, $status);
        $this->assertSame('Worcester parkrun (cafe after)', $body['label']);
        $this->assertSame(5000, $body['distanceM']);
        $this->assertSame($loc->id, $body['locationId']);

        // locationId and kind are not editable.
        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', ['locationId' => $this->location('Other parkrun', ['slug' => 'other'])->id, 'kind' => 'event']);
        $this->assertSame(200, $status);
        $this->assertSame($loc->id, $body['locationId']);

        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', ['description' => str_repeat('a', 1001)]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('description', $body['errors']);

        // Clearing the description is fine, clearing the label is not.
        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', ['description' => null]);
        $this->assertSame(200, $status);
        $this->assertNull($body['description']);
        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', ['label' => null]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('label', $body['errors']);
    }

    public function testAnEventGroupHasNoPaceAndKeepsItsKind()
    {
        $g = $this->eventGroup($this->events());

        foreach ([['paceUnit' => 'mi'], ['paceFromS' => 570], ['paceToS' => 600]] as $data) {
            [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', $data);
            $this->assertSame(422, $status, json_encode($data));
            $this->assertArrayHasKey('paceFromS', $body['errors']);
        }

        [$status, $body] = $this->api('PATCH', "/groups/{$g->id}", 'plain', ['kind' => 'run']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('kind', $body['errors']);

        $this->assertNull(SessionGroup::find($g->id)->pace_from_s);
    }

    public function testEditingAndDeletingAreClosedOnPastAndCancelledRuns()
    {
        $past = $this->eventGroup($this->events(['date' => '2026-10-05']));
        $cancelled = $this->eventGroup($this->events(['date' => '2026-10-19', 'status' => 'cancelled']));

        foreach ([$past, $cancelled] as $g) {
            [$status] = $this->api('PATCH', "/groups/{$g->id}", 'plain', ['label' => 'x']);
            $this->assertSame(409, $status);
            [$status] = $this->api('DELETE', "/groups/{$g->id}", 'plain');
            $this->assertSame(409, $status);
        }
    }

    public function testWhoMayDeleteAnEventGroup()
    {
        $s = $this->events();

        foreach (['leaderA' => 403, 'leaderB' => 403, 'plain' => 204, 'coord' => 204, 'committee' => 204, 'admin' => 204] as $sub => $expected) {
            $g = $this->eventGroup($s, ['label' => "For $sub"]);
            [$status] = $this->api('DELETE', "/groups/{$g->id}", $sub);

            $this->assertSame($expected, $status, $sub);
            $this->assertSame($expected === 204, SessionGroup::find($g->id) === null, $sub);
        }
    }

    public function testDeletingAnEventGroupLeavesItsAttendeesGoingWithNoGroup()
    {
        $s = $this->events();
        $g = $this->eventGroup($s);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $this->leaderA, 'maybe', $g);

        [$status] = $this->api('DELETE', "/groups/{$g->id}", 'plain');
        $this->assertSame(204, $status);
        [$again] = $this->api('DELETE', "/groups/{$g->id}", 'plain');
        $this->assertSame(204, $again);

        $rows = SessionAttendee::where('session_id', $s->id)->get();
        $this->assertSame(['going', 'maybe'], $rows->pluck('status')->sort()->values()->all());
        $this->assertNull($rows->pluck('group_id')->filter()->first());
    }

    public function testTheLeaderEndpointsStillWorkButNeverMakeAnEventNeedALeader()
    {
        $s = $this->events();
        $g = $this->eventGroup($s);

        $this->api('POST', "/groups/{$g->id}/leaders", 'leaderB');
        [$status, $body] = $this->api('DELETE', "/groups/{$g->id}/leaders/me", 'leaderB');

        $this->assertSame(200, $status);
        $this->assertSame('active', $body['status']);
    }

    // ---- joining and leaving ----------------------------------------------------------------

    public function testJoiningAndLeavingAnEventMovesTheCounts()
    {
        $s = $this->events();
        $a = $this->eventGroup($s, ['label' => 'Worcester parkrun']);
        $b = $this->eventGroup($s, ['label' => 'Bushy parkrun']);

        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $a->id]);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'leaderA', ['status' => 'going', 'groupId' => $a->id]);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'leaderB', ['status' => 'maybe', 'groupId' => $a->id]);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'coord', ['status' => 'going', 'groupId' => $b->id]);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'committee', ['status' => 'going']); // event not chosen yet

        $counts = function () use ($s) {
            [, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
            $item = $body['items'][0];

            return [collect($item['groups'])->mapWithKeys(function ($g) {
                return [$g['label'] => [$g['goingCount'], $g['maybeCount']]];
            })->all(), $item['summary']];
        };

        [$groups, $summary] = $counts();
        $this->assertSame(['Worcester parkrun' => [2, 1], 'Bushy parkrun' => [1, 0]], $groups);
        $this->assertSame(4, $summary['goingCount']);
        $this->assertSame($a->id, $summary['myGroupId']);

        // Switch event, then leave.
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $b->id]);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'leaderA', ['status' => 'not_going']);

        [$groups] = $counts();
        $this->assertSame(['Worcester parkrun' => [0, 1], 'Bushy parkrun' => [2, 0]], $groups);
        $this->assertNull(SessionAttendee::where('member_id', $this->leaderA->id)->first()->group_id);
    }

    // ---- plan names ---------------------------------------------------------------------------

    private function planFixture(): array
    {
        $s = $this->events();
        $a = $this->eventGroup($s, ['label' => 'Worcester parkrun']);
        $b = $this->eventGroup($s, ['label' => 'Bushy parkrun']);
        $this->attend($s, $this->plain, 'going', $a);        // Pat P.
        $this->attend($s, $this->leaderA, 'maybe', $a);       // Lee
        $this->attend($s, $this->leaderB, 'going', $b);       // Lou
        $this->attend($s, $this->coord, 'not_going', $a);     // not counted
        $loose = $this->member('loose', 207, [], 'active', 'Lin');
        $this->attend($s, $loose, 'going');                   // going, no event yet
        $out = $this->member('outsider', 208, [], 'active', 'Oli');

        return [$s, $a, $b];
    }

    private function entry(array $plan, SessionGroup $group): array
    {
        return collect($plan['groups'])->firstWhere('groupId', $group->id);
    }

    public function testMembersOfAnEventSeeTheNamesInThatEventOnly()
    {
        [$s, $a, $b] = $this->planFixture();

        [$status, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'plain');

        $this->assertSame(200, $status);
        $mine = $this->entry($plan, $a);
        // Short names, sorted by name, and nothing about pace.
        $this->assertSame([
            ['memberId' => $this->leaderA->id, 'displayName' => 'Lee L.', 'status' => 'maybe'],
            ['memberId' => $this->plain->id, 'displayName' => 'Pat L.', 'status' => 'going'],
        ], $mine['attendees']);
        $this->assertArrayNotHasKey('attendees', $this->entry($plan, $b));
        $this->assertArrayNotHasKey('members', $plan['unassigned']);
        $this->assertSame(1, $plan['unassigned']['goingCount']);

        // A maybe member sees their own event too.
        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'leaderA');
        $this->assertCount(2, $this->entry($plan, $a)['attendees']);
        $this->assertArrayNotHasKey('attendees', $this->entry($plan, $b));

        // And Lou only their own.
        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'leaderB');
        $this->assertCount(1, $this->entry($plan, $b)['attendees']);
        $this->assertArrayNotHasKey('attendees', $this->entry($plan, $a));
    }

    public function testEveryoneElseGetsCountsOnly()
    {
        [$s, $a, $b] = $this->planFixture();

        foreach (['loose', 'outsider'] as $sub) {
            [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", $sub);

            foreach ([$a, $b] as $group) {
                $this->assertArrayNotHasKey('attendees', $this->entry($plan, $group), $sub);
            }
            $this->assertSame([], $this->entry($plan, $a)['paces']);
        }

        // A member who said not going sees no names, even though a stale row names the group.
        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'coord');
        $this->assertArrayHasKey('attendees', $this->entry($plan, $a)); // the coordinator sees all, not_going rows excluded
        $this->assertCount(2, $this->entry($plan, $a)['attendees']);
    }

    public function testCoordinatorAndCommitteeStillSeeEveryName()
    {
        [$s, $a, $b] = $this->planFixture();

        foreach (['coord', 'committee', 'admin'] as $sub) {
            [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", $sub);

            $this->assertCount(2, $this->entry($plan, $a)['attendees'], $sub);
            $this->assertCount(1, $this->entry($plan, $b)['attendees'], $sub);
            $this->assertCount(1, $plan['unassigned']['members'], $sub);
            $this->assertSame('Lin Last207', $plan['unassigned']['members'][0]['displayName'], $sub);
        }
    }

    public function testPaceGroupsKeepTheirRules()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570, 'pace_to_s' => 600]);
        $this->attend($s, $this->plain, 'going', $g);
        $this->attend($s, $this->leaderB, 'going', $g);

        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'plain');
        $this->assertArrayNotHasKey('attendees', $plan['groups'][0]);

        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'leaderA');
        $this->assertCount(2, $plan['groups'][0]['attendees']);
        $this->assertArrayHasKey('paceUnit', $plan['groups'][0]['attendees'][0]);
    }

    // ---- chat --------------------------------------------------------------------------------

    public function testAnEventGroupChatIsForItsAttendeesAndTheCoordinator()
    {
        [$s, $a] = $this->planFixture();
        $thread = ThreadAccess::find(Club::find(1), $a->id);

        $ids = $thread->participantIds();
        sort($ids);
        $expected = [$this->plain->id, $this->leaderA->id, $this->coord->id];
        sort($expected);

        $this->assertSame($expected, $ids);

        [$status] = $this->api('POST', "/groups/{$a->id}/messages", 'plain', ['body' => 'Anyone driving?']);
        $this->assertSame(201, $status);

        [$status] = $this->api('POST', "/groups/{$a->id}/messages", 'leaderB', ['body' => 'Can I join?']);
        $this->assertSame(403, $status, 'going to another event');

        [$status] = $this->api('GET', "/groups/{$a->id}/messages", 'committee');
        $this->assertSame(200, $status, 'staff may read every thread');
    }

    public function testACreatorWhoWithdrewIsNoLongerInTheChat()
    {
        $s = $this->events();
        [, $g] = $this->add('plain', $s, ['label' => 'Worcester parkrun']);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'not_going']);

        $thread = ThreadAccess::find(Club::find(1), $g['id']);

        $this->assertNotContains($this->plain->id, $thread->participantIds());
    }
}
