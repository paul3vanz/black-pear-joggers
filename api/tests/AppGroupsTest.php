<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Facades\DB;

/**
 * Phase 4: groups and leaders (create, edit, delete, join, withdraw),
 * their permissions, validation and the session payload.
 */
class AppGroupsTest extends AppGroupsBase
{
    // ---- create + permissions -------------------------------------------

    public function testAnyLinkedMemberCreatesAGroupAndLeadsIt()
    {
        $s = $this->session();
        [$status, $body] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', [
            'paceUnit' => 'mi', 'paceFromS' => 570, 'paceToS' => 600, 'distanceValue' => 3, 'distanceUnit' => 'mi', 'lead' => true,
        ]);

        $this->assertSame(201, $status);
        $this->assertSame($s->id, $body['sessionId']);
        $this->assertSame('run', $body['kind']);
        $this->assertSame('active', $body['status']);
        $this->assertSame(0, $body['sortOrder']);
        $this->assertSame($this->plain->id, $body['leaders'][0]['memberId']);
        $this->assertSame('leader', $body['leaders'][0]['role']);
        $this->assertSame(0, $body['goingCount']);
    }

    public function testLeaderlessGroupNeedsCommitteeAdminOrCoordinator()
    {
        $s = $this->session();
        $path = "/sessions/{$s->id}/groups";

        foreach (['plain', 'leaderA', 'leaderB'] as $sub) {
            [$status, $body] = $this->api('POST', $path, $sub, ['label' => 'Routes']);
            $this->assertSame(403, $status, $sub);
            $this->assertSame('forbidden', $body['error']);
        }

        [$status] = $this->api('POST', $path, 'plain', ['label' => 'Routes', 'lead' => false]);
        $this->assertSame(403, $status);

        foreach (['coord', 'committee', 'admin'] as $sub) {
            [$status, $body] = $this->api('POST', $path, $sub, ['label' => "By $sub", 'lead' => false]);
            $this->assertSame(201, $status, $sub);
            $this->assertSame([], $body['leaders']);
            // A paced run expects leaders, so a leaderless group is flagged.
            $this->assertSame('needs_leader', $body['status']);
        }

        $this->assertSame(3, SessionGroup::where('session_id', $s->id)->count());
    }

    public function testLeaderlessGroupInARoutesRunStaysActive()
    {
        $s = $this->session(['group_mode' => 'routes']);
        [$status, $body] = $this->api('POST', "/sessions/{$s->id}/groups", 'committee', ['label' => '5 mile route', 'kind' => 'route', 'lead' => false]);

        $this->assertSame(201, $status);
        $this->assertSame('active', $body['status']);
        $this->assertSame('route', $body['kind']);
    }

    public function testCreateIsIdempotentOnId()
    {
        $s = $this->session();
        $id = '11111111-1111-4111-8111-111111111111';
        $path = "/sessions/{$s->id}/groups";

        [$status, $first] = $this->api('POST', $path, 'plain', ['id' => $id, 'lead' => true, 'label' => 'A']);
        [$status2, $second] = $this->api('POST', $path, 'plain', ['id' => $id, 'lead' => true, 'label' => 'A']);

        $this->assertSame(201, $status);
        $this->assertSame(200, $status2);
        $this->assertSame($id, $second['id']);
        $this->assertSame(1, SessionGroup::where('session_id', $s->id)->count());
        $this->assertSame(1, SessionGroupLeader::count());

        // The same id on another run is a conflict, not a silent reuse.
        $other = $this->session(['date' => '2026-10-19']);
        [$status3, $body3] = $this->api('POST', "/sessions/{$other->id}/groups", 'plain', ['id' => $id, 'lead' => true]);
        $this->assertSame(409, $status3);
        $this->assertSame('conflict', $body3['error']);
    }

    public function testCreateOnCancelledPastOrUnknownSession()
    {
        $cancelled = $this->session(['status' => 'cancelled']);
        [$status, $body] = $this->api('POST', "/sessions/{$cancelled->id}/groups", 'plain', ['lead' => true]);
        $this->assertSame(409, $status);
        $this->assertSame('session_cancelled', $body['error']);

        $past = $this->pastSession();
        [$status, $body] = $this->api('POST', "/sessions/{$past->id}/groups", 'plain', ['lead' => true]);
        $this->assertSame(409, $status);
        $this->assertSame('session_past', $body['error']);

        [$status, $body] = $this->api('POST', '/sessions/22222222-2222-4222-8222-222222222222/groups', 'plain', ['lead' => true]);
        $this->assertSame(404, $status);
        $this->assertSame('not_found', $body['error']);
    }

    public function testGroupRoutesNeedALinkedMember()
    {
        $s = $this->session();
        [$status] = $this->call_('POST', "/app/clubs/1/sessions/{$s->id}/groups", null, ['lead' => true]);
        $this->assertSame(401, $status);

        [$status, $body] = $this->call_('POST', "/app/clubs/1/sessions/{$s->id}/groups", 'stranger', ['lead' => true]);
        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);
    }

    // ---- validation ------------------------------------------------------

    /** @dataProvider validSpecs */
    public function testValidGroupSpecs(array $body)
    {
        $s = $this->session();
        [$status] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', $body + ['lead' => true]);

        $this->assertSame(201, $status);
    }

    public function validSpecs(): array
    {
        return [
            'single pace' => [['paceUnit' => 'mi', 'paceFromS' => 570]],
            'range' => [['paceUnit' => 'km', 'paceFromS' => 330, 'paceToS' => 360]],
            'equal range ends' => [['paceUnit' => 'mi', 'paceFromS' => 600, 'paceToS' => 600]],
            'no pace' => [['kind' => 'jog_walk', 'label' => 'Jog/walk']],
            'distance only' => [['distanceValue' => 5, 'distanceUnit' => 'km']],
            'bounds' => [['paceUnit' => 'mi', 'paceFromS' => 180, 'paceToS' => 1800, 'distanceValue' => 0.1, 'distanceUnit' => 'mi']],
            'nothing at all' => [[]],
        ];
    }

    /** @dataProvider invalidSpecs */
    public function testInvalidGroupSpecs(array $body, string $field)
    {
        $s = $this->session();
        [$status, $res] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', $body + ['lead' => true]);

        $this->assertSame(422, $status);
        $this->assertSame('validation_failed', $res['error']);
        $this->assertArrayHasKey($field, $res['errors']);
        $this->assertSame(0, SessionGroup::count());
    }

    public function invalidSpecs(): array
    {
        return [
            'pace without unit' => [['paceFromS' => 570], 'paceUnit'],
            'range without unit' => [['paceFromS' => 570, 'paceToS' => 600], 'paceUnit'],
            'to without from' => [['paceUnit' => 'mi', 'paceToS' => 600], 'paceFromS'],
            'from slower than to' => [['paceUnit' => 'mi', 'paceFromS' => 700, 'paceToS' => 600], 'paceToS'],
            'pace too fast' => [['paceUnit' => 'mi', 'paceFromS' => 179], 'paceFromS'],
            'pace too slow' => [['paceUnit' => 'mi', 'paceFromS' => 570, 'paceToS' => 1801], 'paceToS'],
            'bad pace unit' => [['paceUnit' => 'yd', 'paceFromS' => 570], 'paceUnit'],
            'distance without unit' => [['distanceValue' => 3], 'distanceUnit'],
            'distance too short' => [['distanceValue' => 0.05, 'distanceUnit' => 'mi'], 'distanceValue'],
            'distance too long' => [['distanceValue' => 201, 'distanceUnit' => 'km'], 'distanceValue'],
            'unknown kind' => [['kind' => 'sprint'], 'kind'],
            'label too long' => [['label' => str_repeat('x', 81)], 'label'],
            'description too long' => [['description' => str_repeat('x', 1001)], 'description'],
            'lead not boolean' => [['lead' => 'maybe'], 'lead'],
        ];
    }

    public function testDerivedCanonicalValues()
    {
        $s = $this->session();
        [, $mi] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', [
            'paceUnit' => 'mi', 'paceFromS' => 570, 'paceToS' => 600, 'distanceValue' => 3, 'distanceUnit' => 'mi', 'lead' => true,
        ]);

        // 570 s/mi / 1.609344 = 354.2 s/km; 600 / 1.609344 = 372.8; 3 mi = 4828.03 m
        $this->assertSame(570, $mi['paceFromS']);
        $this->assertSame(354, $mi['paceFromSPerKm']);
        $this->assertSame(373, $mi['paceToSPerKm']);
        $this->assertEquals(3.0, $mi["distanceValue"]); // JSON may carry 3 or 3.0
        $this->assertSame(4828, $mi['distanceM']);

        [, $km] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', [
            'paceUnit' => 'km', 'paceFromS' => 330, 'distanceValue' => 5, 'distanceUnit' => 'km', 'lead' => true,
        ]);

        $this->assertSame(330, $km['paceFromSPerKm']);
        $this->assertNull($km['paceToS']);
        $this->assertNull($km['paceToSPerKm']);
        $this->assertSame(5000, $km['distanceM']);

        [, $none] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['lead' => true]);
        $this->assertNull($none['paceUnit']);
        $this->assertNull($none['paceFromSPerKm']);
        $this->assertNull($none['distanceM']);
    }
}
