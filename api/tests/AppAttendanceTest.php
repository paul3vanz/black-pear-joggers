<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\MemberPreference;
use App\Models\SessionAttendee;

/**
 * Phase 4: attendance, the session plan and preferences.
 */
class AppAttendanceTest extends AppGroupsBase
{
    // ---- attendance ------------------------------------------------------

    public function testPutUpsertsTheCallersSingleRow()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);

        [$status, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'maybe']);
        $this->assertSame(200, $status);
        $this->assertSame($s->id, $body['sessionId']);
        $this->assertSame('maybe', $body['status']);
        $this->assertNull($body['groupId']);
        $this->assertNotNull($body['updatedAt']);

        [, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $g->id]);
        $this->assertSame('going', $body['status']);
        $this->assertSame($g->id, $body['groupId']);
        $this->assertSame(1, SessionAttendee::where('session_id', $s->id)->count());

        [, $mine] = $this->api('GET', "/sessions/{$s->id}/attendance", 'plain');
        $this->assertSame($g->id, $mine['groupId']);

        // Nobody else sees it as theirs.
        [$status, $other] = $this->api('GET', "/sessions/{$s->id}/attendance", 'coord');
        $this->assertSame(200, $status);
        $this->assertNull($other);
    }

    public function testNotGoingClearsTheGroup()
    {
        $s = $this->session();
        $g = $this->group($s, [$this->leaderA]);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $g->id]);

        [, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'not_going', 'groupId' => $g->id]);

        $this->assertSame('not_going', $body['status']);
        $this->assertNull($body['groupId']);
    }

    public function testPaceOverrideIsReplacedOnEveryPut()
    {
        $s = $this->session();

        [, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', [
            'status' => 'going', 'paceUnit' => 'mi', 'paceFromS' => 540, 'paceToS' => 570,
        ]);
        $this->assertSame(['mi', 540, 570], [$body['paceUnit'], $body['paceFromS'], $body['paceToS']]);

        [, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going']);
        $this->assertSame([null, null, null], [$body['paceUnit'], $body['paceFromS'], $body['paceToS']]);
    }

    public function testAttendanceValidation()
    {
        $s = $this->session();
        $path = "/sessions/{$s->id}/attendance";

        $cases = [
            [[], 'status'],
            [['status' => 'perhaps'], 'status'],
            [['status' => 'going', 'groupId' => 'nope'], 'groupId'],
            [['status' => 'going', 'paceFromS' => 540], 'paceUnit'],
            [['status' => 'going', 'paceUnit' => 'mi', 'paceFromS' => 700, 'paceToS' => 600], 'paceToS'],
            [['status' => 'going', 'paceUnit' => 'mi', 'paceFromS' => 100], 'paceFromS'],
        ];

        foreach ($cases as [$data, $field]) {
            [$status, $body] = $this->api('PUT', $path, 'plain', $data);
            $this->assertSame(422, $status, $field);
            $this->assertArrayHasKey($field, $body['errors']);
        }
    }

    public function testGroupFromAnotherSessionOrDeletedIsRejected()
    {
        $s = $this->session();
        $other = $this->session(['date' => '2026-10-19']);
        $foreign = $this->group($other, [$this->leaderA]);
        $deleted = $this->group($s, [$this->leaderA]);
        $deleted->delete();

        foreach ([$foreign, $deleted] as $group) {
            [$status, $body] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => $group->id]);
            $this->assertSame(422, $status);
            $this->assertArrayHasKey('groupId', $body['errors']);
        }

        [$status] = $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going', 'groupId' => '66666666-6666-4666-8666-666666666666']);
        $this->assertSame(422, $status);
        $this->assertSame(0, SessionAttendee::count());
    }

    public function testAttendanceOnPastCancelledAndUnknownSessions()
    {
        $past = $this->pastSession();
        [$status, $body] = $this->api('PUT', "/sessions/{$past->id}/attendance", 'plain', ['status' => 'going']);
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);

        $cancelled = $this->session(['status' => 'cancelled']);
        [$status, $body] = $this->api('PUT', "/sessions/{$cancelled->id}/attendance", 'plain', ['status' => 'going']);
        $this->assertSame(409, $status);
        $this->assertSame('session_cancelled', $body['error']);

        // Reading a past run's attendance is still fine.
        [$status] = $this->api('GET', "/sessions/{$past->id}/attendance", 'plain');
        $this->assertSame(200, $status);

        [$status] = $this->api('PUT', '/sessions/77777777-7777-4777-8777-777777777777/attendance', 'plain', ['status' => 'going']);
        $this->assertSame(404, $status);
        [$status] = $this->api('GET', '/sessions/77777777-7777-4777-8777-777777777777/attendance', 'plain');
        $this->assertSame(404, $status);
    }

    public function testAttendanceBumpsTheSessionAndAppearsInTheSummary()
    {
        $s = $this->session();
        $before = $this->sessionUpdatedAt($s);

        $this->tick(60);
        $this->api('PUT', "/sessions/{$s->id}/attendance", 'plain', ['status' => 'going']);

        $this->assertGreaterThan($before, $this->sessionUpdatedAt($s));

        $since = \Illuminate\Support\Carbon::now()->subSeconds(30)->utc()->format('Y-m-d\TH:i:s\Z');
        [, $feed] = $this->api('GET', '/sessions?since=' . urlencode($since), 'plain');
        $this->assertSame([$s->id], array_column($feed['items'], 'id'));
        $this->assertSame(1, $feed['items'][0]['summary']['goingCount']);
        $this->assertSame('going', $feed['items'][0]['summary']['myStatus']);
    }

    // ---- plan ------------------------------------------------------------

    /** A run with two groups and a mix of going/maybe/not_going/unassigned members. */
    private function planFixture(): array
    {
        $s = $this->session();
        $g1 = $this->group($s, [$this->leaderA], ['label' => 'Fast']);
        $g2 = $this->group($s, [$this->leaderB], ['label' => 'Slow']);

        $this->prefs($this->plain, 'mi', 570, 600); // profile range, no override
        $this->attend($s, $this->plain, 'going', $g1);
        // override beats the profile range
        $this->prefs($this->coord, 'km', 300, 320);
        $this->attend($s, $this->coord, 'maybe', $g1, ['pace_unit' => 'mi', 'pace_from_s' => 540]);
        $this->attend($s, $this->admin, 'not_going', $g1, ['pace_unit' => 'mi', 'pace_from_s' => 500]);
        // no pace anywhere: counted but left out of paces
        $this->attend($s, $this->leaderB, 'going', $g2);
        // unassigned
        $this->prefs($this->committee, 'km', 330, 360);
        $this->attend($s, $this->committee, 'going');

        return [$s, $g1, $g2];
    }

    private function prefs($member, string $unit, ?int $from, ?int $to): void
    {
        MemberPreference::create([
            'club_id' => 1, 'member_id' => $member->id, 'pace_unit' => $unit, 'distance_unit' => 'mi',
            'pace_from_s' => $from, 'pace_to_s' => $to,
        ]);
    }

    public function testPlanForAPlainMemberHasNoNamesAndOmitsTheKeys()
    {
        [$s, $g1, $g2] = $this->planFixture();
        $this->attend($s, $this->leaderA, 'going', $g1, ['pace_unit' => 'km', 'pace_from_s' => 330]);

        [$status, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'plain');

        $this->assertSame(200, $status);
        $this->assertSame($s->id, $plan['sessionId']);
        $this->assertCount(2, $plan['groups']);

        foreach ($plan['groups'] as $group) {
            $this->assertArrayNotHasKey('attendees', $group);
            $this->assertSame(['groupId', 'paces'], array_keys($group));
        }

        $this->assertArrayNotHasKey('members', $plan['unassigned']);
        $this->assertSame(['goingCount', 'maybeCount', 'paces'], array_keys($plan['unassigned']));
        $this->assertStringNotContainsString('Pat', json_encode($plan));
        $this->assertStringNotContainsString('memberId', json_encode($plan));

        $paces = [];
        foreach ($plan['groups'] as $group) {
            $paces[$group['groupId']] = $group['paces'];
        }

        // Fast: Pat 570-600 mi (354-373 /km), Cory override 540 mi (336 /km, single), Lee 330 /km. Admin is not_going.
        $this->assertSame([
            ['fromSPerKm' => 330, 'toSPerKm' => null],
            ['fromSPerKm' => 336, 'toSPerKm' => null],
            ['fromSPerKm' => 354, 'toSPerKm' => 373],
        ], $paces[$g1->id]);
        $this->assertSame([], $paces[$g2->id]); // Lou has no pace
        $this->assertSame(1, $plan['unassigned']['goingCount']);
        $this->assertSame([['fromSPerKm' => 330, 'toSPerKm' => 360]], $plan['unassigned']['paces']);
    }

    public function testPlanNamesForALeaderOnlyCoverTheirOwnGroup()
    {
        [$s, $g1, $g2] = $this->planFixture();

        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'leaderB'); // leads g2 only
        $byId = [];
        foreach ($plan['groups'] as $group) {
            $byId[$group['groupId']] = $group;
        }

        $this->assertArrayNotHasKey('attendees', $byId[$g1->id]);
        $this->assertSame(['Lou Last203'], array_column($byId[$g2->id]['attendees'], 'displayName'));
        $this->assertArrayNotHasKey('members', $plan['unassigned']);

        [, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", 'leaderA'); // leads g1
        $byId = [];
        foreach ($plan['groups'] as $group) {
            $byId[$group['groupId']] = $group;
        }

        $names = array_column($byId[$g1->id]['attendees'], 'displayName');
        sort($names);
        $this->assertSame(['Cory Last204', 'Pat Last201'], $names); // going + maybe only
        $this->assertArrayNotHasKey('attendees', $byId[$g2->id]);

        $pat = array_values(array_filter($byId[$g1->id]['attendees'], function ($a) {
            return $a['displayName'] === 'Pat Last201';
        }))[0];
        $this->assertSame(['going', 'mi', 570, 600], [$pat['status'], $pat['paceUnit'], $pat['paceFromS'], $pat['paceToS']]);
    }

    public function testPlanShowsEverythingToCommitteeAdminAndCoordinator()
    {
        [$s, $g1, $g2] = $this->planFixture();

        foreach (['committee', 'admin', 'coord'] as $sub) {
            [$status, $plan] = $this->api('GET', "/sessions/{$s->id}/plan", $sub);

            $this->assertSame(200, $status, $sub);

            foreach ($plan['groups'] as $group) {
                $this->assertArrayHasKey('attendees', $group, $sub);
            }

            $this->assertSame(['Cam Last205'], array_column($plan['unassigned']['members'], 'displayName'), $sub);
            $this->assertSame(['km', 330, 360], [
                $plan['unassigned']['members'][0]['paceUnit'],
                $plan['unassigned']['members'][0]['paceFromS'],
                $plan['unassigned']['members'][0]['paceToS'],
            ]);
        }

        // The coordinator of a different run gets no extra rights here.
        $otherRun = $this->session(['date' => '2026-10-20', 'coordinator_member_id' => $this->leaderA->id]);
        $this->attend($otherRun, $this->plain, 'going');
        [, $plan] = $this->api('GET', "/sessions/{$otherRun->id}/plan", 'coord');
        $this->assertArrayNotHasKey('members', $plan['unassigned']);
    }

    public function testPlanOfUnknownSessionIs404()
    {
        [$status] = $this->api('GET', '/sessions/88888888-8888-4888-8888-888888888888/plan', 'plain');
        $this->assertSame(404, $status);
    }

    // ---- preferences -----------------------------------------------------

    public function testPreferencesDefaultsWhenNeverSaved()
    {
        [$status, $body] = $this->api('GET', '/preferences', 'plain');

        $this->assertSame(200, $status);
        $this->assertSame(['paceUnit' => 'mi', 'distanceUnit' => 'mi', 'paceFromS' => null, 'paceToS' => null, 'updatedAt' => null], $body);
        $this->assertSame(0, MemberPreference::count());
    }

    public function testPreferencesSaveAndAreRememberedPerMember()
    {
        [$status, $body] = $this->api('PUT', '/preferences', 'plain', [
            'paceUnit' => 'km', 'distanceUnit' => 'mi', 'paceFromS' => 330, 'paceToS' => 360,
        ]);

        $this->assertSame(200, $status);
        $this->assertSame(['km', 'mi', 330, 360], [$body['paceUnit'], $body['distanceUnit'], $body['paceFromS'], $body['paceToS']]);
        $this->assertNotNull($body['updatedAt']);

        [, $again] = $this->api('GET', '/preferences', 'plain');
        $this->assertSame(330, $again['paceFromS']);

        [, $other] = $this->api('GET', '/preferences', 'coord');
        $this->assertNull($other['paceFromS']);

        // A partial PUT leaves the rest alone, and there is only ever one row.
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['distanceUnit' => 'km']);
        $this->assertSame(['km', 'km', 330, 360], [$body['paceUnit'], $body['distanceUnit'], $body['paceFromS'], $body['paceToS']]);
        $this->assertSame(1, MemberPreference::count());
    }

    public function testPreferencesNullClearsTheRange()
    {
        $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'mi', 'paceFromS' => 540, 'paceToS' => 600]);

        [, $body] = $this->api('PUT', '/preferences', 'plain', ['paceFromS' => null, 'paceToS' => null]);
        $this->assertNull($body['paceFromS']);
        $this->assertNull($body['paceToS']);
        $this->assertSame('mi', $body['paceUnit']);

        // Clearing the faster end alone clears the whole range.
        $this->api('PUT', '/preferences', 'plain', ['paceFromS' => 540, 'paceToS' => 600]);
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['paceFromS' => null]);
        $this->assertNull($body['paceFromS']);
        $this->assertNull($body['paceToS']);
    }

    public function testChangingThePaceUnitWithoutARangeClearsIt()
    {
        $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'mi', 'paceFromS' => 540, 'paceToS' => 600]);

        [, $body] = $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'km']);
        $this->assertSame('km', $body['paceUnit']);
        $this->assertNull($body['paceFromS']);
        $this->assertNull($body['paceToS']);

        // Sending the unit and a range together keeps the range.
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'mi', 'paceFromS' => 540, 'paceToS' => 600]);
        $this->assertSame([540, 600], [$body['paceFromS'], $body['paceToS']]);

        // Re-sending the same unit leaves it.
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'mi']);
        $this->assertSame([540, 600], [$body['paceFromS'], $body['paceToS']]);
    }

    public function testPreferencesValidation()
    {
        $cases = [
            [['paceUnit' => 'yd'], 'paceUnit'],
            [['distanceUnit' => 'm'], 'distanceUnit'],
            [['paceUnit' => null], 'paceUnit'],
            [['paceFromS' => 100], 'paceFromS'],
            [['paceFromS' => 540, 'paceToS' => 2000], 'paceToS'],
            [['paceFromS' => 700, 'paceToS' => 600], 'paceToS'],
            [['paceToS' => 600], 'paceFromS'],
        ];

        foreach ($cases as [$data, $field]) {
            [$status, $body] = $this->api('PUT', '/preferences', 'plain', $data);
            $this->assertSame(422, $status, $field);
            $this->assertArrayHasKey($field, $body['errors']);
        }

        $this->assertSame(0, MemberPreference::count());
    }
}
