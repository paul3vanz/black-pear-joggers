<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\MemberPreference;

/**
 * "Days I may lead" (D106/D107) and "days I run" (D115): member_preferences.lead_days and run_days
 * through GET and PUT /preferences, and how the two lists are kept in line.
 */
class AppLeadDaysTest extends AppGroupsBase
{
    public function testNeverChosenIsNull()
    {
        [, $body] = $this->api('GET', '/preferences', 'plain');
        $this->assertArrayHasKey('leadDays', $body);
        $this->assertNull($body['leadDays']);

        // A row that exists for other reasons still reads as "never chosen".
        $this->api('PUT', '/preferences', 'plain', ['distanceUnit' => 'km']);
        [, $body] = $this->api('GET', '/preferences', 'plain');
        $this->assertNull($body['leadDays']);
        $this->assertNull(MemberPreference::first()->lead_days);
    }

    public function testSaveSortsAndDeduplicates()
    {
        [$status, $body] = $this->api('PUT', '/preferences', 'plain', ['leadDays' => [4, 2, 4, 7]]);

        $this->assertSame(200, $status);
        $this->assertSame([2, 4, 7], $body['leadDays']);
        $this->assertSame('2,4,7', MemberPreference::first()->lead_days);

        [, $again] = $this->api('GET', '/preferences', 'plain');
        $this->assertSame([2, 4, 7], $again['leadDays']);

        // Per member.
        [, $other] = $this->api('GET', '/preferences', 'coord');
        $this->assertNull($other['leadDays']);
    }

    public function testEmptyListMeansNoneAndNullResetsToNeverChosen()
    {
        $this->api('PUT', '/preferences', 'plain', ['leadDays' => [1]]);

        [$status, $body] = $this->api('PUT', '/preferences', 'plain', ['leadDays' => []]);
        $this->assertSame(200, $status);
        $this->assertSame([], $body['leadDays']);
        $this->assertSame('', MemberPreference::first()->lead_days);
        [, $again] = $this->api('GET', '/preferences', 'plain');
        $this->assertSame([], $again['leadDays']);

        [, $body] = $this->api('PUT', '/preferences', 'plain', ['leadDays' => null]);
        $this->assertNull($body['leadDays']);
        $this->assertNull(MemberPreference::first()->lead_days);
    }

    public function testOmittedKeyLeavesLeadDaysAlone()
    {
        $this->api('PUT', '/preferences', 'plain', ['leadDays' => [2, 4]]);

        [, $body] = $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'km', 'distanceUnit' => 'km']);
        $this->assertSame([2, 4], $body['leadDays']);
        $this->assertSame('km', $body['paceUnit']);

        // And saving only leadDays leaves the rest.
        $this->api('PUT', '/preferences', 'plain', ['paceUnit' => 'mi', 'paceFromS' => 540, 'paceToS' => 600]);
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['leadDays' => [3]]);
        $this->assertSame([3], $body['leadDays']);
        $this->assertSame([540, 600], [$body['paceFromS'], $body['paceToS']]);
        $this->assertSame(1, MemberPreference::count());
    }

    public function testRunDaysAreSavedLikeLeadDays()
    {
        [, $body] = $this->api('GET', '/preferences', 'plain');
        $this->assertArrayHasKey('runDays', $body);
        $this->assertNull($body['runDays']);

        [$status, $body] = $this->api('PUT', '/preferences', 'plain', ['runDays' => [3, 1, 3]]);
        $this->assertSame(200, $status);
        $this->assertSame([1, 3], $body['runDays']);
        $this->assertNull($body['leadDays']);
        $this->assertSame('1,3', MemberPreference::first()->run_days);

        // Omitted keys are left alone, and null resets to "never chosen".
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['distanceUnit' => 'km']);
        $this->assertSame([1, 3], $body['runDays']);
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['runDays' => null]);
        $this->assertNull($body['runDays']);
        $this->assertNull(MemberPreference::first()->run_days);
    }

    public function testSavingLeadDaysAddsThemToTheRunDays()
    {
        $this->api('PUT', '/preferences', 'plain', ['runDays' => [3]]);

        [, $body] = $this->api('PUT', '/preferences', 'plain', ['leadDays' => [1]]);
        $this->assertSame([1], $body['leadDays']);
        $this->assertSame([1, 3], $body['runDays']);

        // With no run days chosen, lead days do not invent any.
        [, $body] = $this->api('PUT', '/preferences', 'coord', ['leadDays' => [2]]);
        $this->assertNull($body['runDays']);
        $this->assertSame([2], $body['leadDays']);
    }

    public function testSavingRunDaysDropsLeadDaysOutsideThem()
    {
        $this->api('PUT', '/preferences', 'plain', ['runDays' => [1, 3], 'leadDays' => [1, 3]]);

        [, $body] = $this->api('PUT', '/preferences', 'plain', ['runDays' => [3, 5]]);
        $this->assertSame([3, 5], $body['runDays']);
        $this->assertSame([3], $body['leadDays']);

        // Clearing run days (every day) keeps the lead days.
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['runDays' => null]);
        $this->assertNull($body['runDays']);
        $this->assertSame([3], $body['leadDays']);

        // Both in one request: lead days are added to the run days.
        [, $body] = $this->api('PUT', '/preferences', 'plain', ['runDays' => [2], 'leadDays' => [4]]);
        $this->assertSame([2, 4], $body['runDays']);
        $this->assertSame([4], $body['leadDays']);
    }

    public function testValidation()
    {
        $cases = [
            ['leadDays' => 3],
            ['leadDays' => '2,4'],
            ['leadDays' => [0]],
            ['leadDays' => [8]],
            ['leadDays' => [2, 9]],
            ['leadDays' => ['2']],
            ['leadDays' => [2.5]],
            ['leadDays' => ['mon']],
            ['leadDays' => [true]],
            ['leadDays' => [[2]]],
            ['leadDays' => ['a' => 2]],
        ];

        foreach ($cases as $data) {
            [$status, $body] = $this->api('PUT', '/preferences', 'plain', $data);
            $this->assertSame(422, $status, json_encode($data));
            $this->assertArrayHasKey('leadDays', $body['errors'], json_encode($data));
        }

        foreach ([['runDays' => 3], ['runDays' => [0]], ['runDays' => ['1']], ['runDays' => ['a' => 2]]] as $data) {
            [$status, $body] = $this->api('PUT', '/preferences', 'plain', $data);
            $this->assertSame(422, $status, json_encode($data));
            $this->assertArrayHasKey('runDays', $body['errors'], json_encode($data));
        }

        $this->assertSame(0, MemberPreference::count());
    }
}
