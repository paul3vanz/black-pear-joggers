<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\EventLocation;
use App\Models\SessionGroup;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Phase 8a: /event-locations (list with since and tombstones, add, edit, delete) and who may do what.
 */
class AppEventLocationsTest extends AppGroupsBase
{
    private function loc(array $overrides = []): EventLocation
    {
        return EventLocation::create($overrides + [
            'club_id' => 1, 'kind' => 'parkrun', 'name' => 'Worcester parkrun', 'slug' => 'worcester', 'source' => 'import',
        ]);
    }

    private function otherClub(): void
    {
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other', 'slug' => 'other', 'timezone' => 'Europe/London', 'created_at' => '2026-01-01', 'updated_at' => '2026-01-01']);
    }

    // ---- list ---------------------------------------------------------------------------------

    public function testListsEveryLiveRowWithoutSince()
    {
        $this->loc();
        $this->loc(['name' => 'Bushy parkrun', 'slug' => 'bushy', 'country' => 'GB', 'region' => 'London', 'lat' => 51.410991, 'lng' => -0.34, 'url' => 'https://www.parkrun.org.uk/bushy/']);
        $gone = $this->loc(['name' => 'Old parkrun', 'slug' => 'old']);
        $gone->delete();
        $this->otherClub();
        EventLocation::create(['club_id' => 2, 'kind' => 'parkrun', 'name' => 'Elsewhere parkrun', 'slug' => 'elsewhere']);

        [$status, $body] = $this->api('GET', '/event-locations', 'plain');

        $this->assertSame(200, $status);
        $this->assertCount(2, $body['items']);
        $this->assertNotEmpty($body['serverTime']);
        $bushy = collect($body['items'])->firstWhere('slug', 'bushy');
        $this->assertSame('parkrun', $bushy['kind']);
        $this->assertSame('Bushy parkrun', $bushy['name']);
        $this->assertSame('GB', $bushy['country']);
        $this->assertSame('London', $bushy['region']);
        $this->assertSame(51.410991, $bushy['lat']);
        $this->assertSame(-0.34, $bushy['lng']);
        $this->assertSame('https://www.parkrun.org.uk/bushy/', $bushy['url']);
        $this->assertSame('import', $bushy['source']);
        $this->assertNull($bushy['deletedAt']);
        $this->assertNotNull($bushy['updatedAt']);
    }

    public function testSinceReturnsChangesAndTombstones()
    {
        $old = $this->loc(['slug' => 'old', 'name' => 'Old parkrun']);
        $kept = $this->loc(['slug' => 'kept', 'name' => 'Kept parkrun']);
        $this->tick(120);
        $mark = Carbon::now()->toIso8601String();
        $this->tick(120);
        $changed = $this->loc(['slug' => 'new', 'name' => 'New parkrun']);
        $old->delete();

        [$status, $body] = $this->api('GET', '/event-locations?since=' . urlencode($mark), 'plain');

        $this->assertSame(200, $status);
        $bySlug = collect($body['items'])->keyBy('slug');
        $this->assertSame(['new', 'old'], $bySlug->keys()->sort()->values()->all());
        $this->assertNotNull($bySlug['old']['deletedAt']);
        $this->assertNull($bySlug['new']['deletedAt']);
    }

    public function testBadSinceIs422()
    {
        [$status, $body] = $this->api('GET', '/event-locations?since=yesterday-ish', 'plain');

        $this->assertSame(422, $status);
        $this->assertArrayHasKey('since', $body['errors']);
    }

    public function testNeedsALinkedMember()
    {
        [$status] = $this->api('GET', '/event-locations', null);
        $this->assertSame(401, $status);

        [$status] = $this->api('GET', '/event-locations', 'stranger');
        $this->assertSame(403, $status);

        [$status] = $this->api('POST', '/event-locations', 'stranger', ['name' => 'x']);
        $this->assertSame(403, $status);
    }

    // ---- add ----------------------------------------------------------------------------------

    public function testAnyMemberAddsARaceOrOtherLocation()
    {
        [$status, $body] = $this->api('POST', '/event-locations', 'plain', [
            'kind' => 'race', 'name' => '  Droitwich 10k  ', 'region' => 'Worcestershire', 'lat' => 52.2678123, 'lng' => -2.1544567, 'url' => 'https://example.org/10k',
        ]);

        $this->assertSame(201, $status);
        $this->assertSame('race', $body['kind']);
        $this->assertSame('Droitwich 10k', $body['name']);
        $this->assertSame('manual', $body['source']);
        $this->assertNull($body['slug']);
        $this->assertSame('Worcestershire', $body['region']);
        $this->assertSame(52.267812, $body['lat']);
        $this->assertSame(-2.154457, $body['lng']);

        // kind defaults to other.
        [$status, $body] = $this->api('POST', '/event-locations', 'plain', ['name' => 'Cotswold trail']);
        $this->assertSame(201, $status);
        $this->assertSame('other', $body['kind']);
        $this->assertSame(1, EventLocation::where('kind', 'other')->count());
    }

    public function testParkrunLocationsAreCommitteeOnly()
    {
        foreach (['plain', 'leaderA', 'leaderB', 'coord'] as $sub) {
            [$status, $body] = $this->api('POST', '/event-locations', $sub, ['kind' => 'parkrun', 'name' => 'Bushy parkrun']);
            $this->assertSame(403, $status, $sub);
            $this->assertSame('forbidden', $body['error']);
        }

        [$status, $body] = $this->api('POST', '/event-locations', 'committee', ['kind' => 'parkrun', 'name' => 'Bushy parkrun']);
        $this->assertSame(201, $status);
        $this->assertSame('parkrun', $body['kind']);

        [$status] = $this->api('POST', '/event-locations', 'admin', ['kind' => 'parkrun', 'name' => 'Cardiff parkrun']);
        $this->assertSame(201, $status);
        $this->assertSame(2, EventLocation::count());
    }

    public function testTheSameKindAndNameInAnyCaseReturnsTheExistingRow()
    {
        [, $first] = $this->api('POST', '/event-locations', 'plain', ['kind' => 'race', 'name' => 'Droitwich 10k']);

        [$status, $again] = $this->api('POST', '/event-locations', 'leaderA', ['kind' => 'race', 'name' => ' droitwich 10K ', 'region' => 'ignored']);

        $this->assertSame(200, $status);
        $this->assertSame($first['id'], $again['id']);
        $this->assertSame(1, EventLocation::count());

        // The same name under another kind is a different place.
        [$status] = $this->api('POST', '/event-locations', 'plain', ['kind' => 'other', 'name' => 'Droitwich 10k']);
        $this->assertSame(201, $status);

        // A deleted location does not block adding it again.
        EventLocation::find($first['id'])->delete();
        [$status, $new] = $this->api('POST', '/event-locations', 'plain', ['kind' => 'race', 'name' => 'Droitwich 10k']);
        $this->assertSame(201, $status);
        $this->assertNotSame($first['id'], $new['id']);
    }

    public function testAddingIsIdempotentOnId()
    {
        $id = '0b1c2d3e-4f50-4a6b-8c7d-9e0f1a2b3c4d';

        [$first, $a] = $this->api('POST', '/event-locations', 'plain', ['id' => $id, 'kind' => 'race', 'name' => 'Droitwich 10k']);
        [$second, $b] = $this->api('POST', '/event-locations', 'plain', ['id' => $id, 'kind' => 'race', 'name' => 'Droitwich 10k']);
        // Even a replay with other content returns what was stored.
        [$third, $c] = $this->api('POST', '/event-locations', 'leaderA', ['id' => $id, 'kind' => 'other', 'name' => 'Different']);

        $this->assertSame([201, 200, 200], [$first, $second, $third]);
        $this->assertSame([$id, $id, $id], [$a['id'], $b['id'], $c['id']]);
        $this->assertSame('Droitwich 10k', $c['name']);
        $this->assertSame(1, EventLocation::count());
    }

    public function testAnIdOfAnotherClubIs409()
    {
        $this->otherClub();
        $theirs = EventLocation::create(['club_id' => 2, 'kind' => 'race', 'name' => 'Theirs']);

        [$status, $body] = $this->api('POST', '/event-locations', 'plain', ['id' => $theirs->id, 'name' => 'Mine']);

        $this->assertSame(409, $status);
        $this->assertSame('conflict', $body['error']);
    }

    public function testValidationNeverThrows()
    {
        $cases = [
            'no name' => [[], 'name'],
            'blank name' => [['name' => '   '], 'name'],
            'name too long' => [['name' => str_repeat('x', 121)], 'name'],
            'bad kind' => [['name' => 'x', 'kind' => 'marathon'], 'kind'],
            'bad id' => [['name' => 'x', 'id' => 'nope'], 'id'],
            'lat out of range' => [['name' => 'x', 'lat' => 91], 'lat'],
            'lng out of range' => [['name' => 'x', 'lng' => -181], 'lng'],
            'lat not a number' => [['name' => 'x', 'lat' => 'north'], 'lat'],
            'url not http' => [['name' => 'x', 'url' => 'javascript:alert(1)'], 'url'],
            'region too long' => [['name' => 'x', 'region' => str_repeat('r', 81)], 'region'],
        ];

        foreach ($cases as $label => [$data, $field]) {
            [$status, $body] = $this->api('POST', '/event-locations', 'plain', $data);
            $this->assertSame(422, $status, $label);
            $this->assertSame('validation_failed', $body['error'], $label);
            $this->assertArrayHasKey($field, $body['errors'], $label);
        }

        $this->assertSame(0, EventLocation::count());
    }

    // ---- edit and delete ----------------------------------------------------------------------

    public function testOnlyCommitteeAndAdminEditAndDelete()
    {
        $loc = $this->loc();

        foreach (['plain', 'leaderA', 'leaderB', 'coord'] as $sub) {
            [$status] = $this->api('PATCH', "/event-locations/{$loc->id}", $sub, ['name' => 'Hacked']);
            $this->assertSame(403, $status, $sub);
            [$status] = $this->api('DELETE', "/event-locations/{$loc->id}", $sub);
            $this->assertSame(403, $status, $sub);
        }

        $this->assertSame('Worcester parkrun', EventLocation::find($loc->id)->name);

        [$status, $body] = $this->api('PATCH', "/event-locations/{$loc->id}", 'committee', [
            'name' => 'Worcester parkrun (Gheluvelt)', 'region' => 'Worcestershire', 'lat' => 52.2, 'lng' => -2.2, 'url' => 'https://www.parkrun.org.uk/worcester/',
        ]);
        $this->assertSame(200, $status);
        $this->assertSame('Worcester parkrun (Gheluvelt)', $body['name']);
        $this->assertSame('Worcestershire', $body['region']);
        $this->assertSame('worcester', $body['slug']);
        $this->assertSame('parkrun', $body['kind']);

        [$status] = $this->api('DELETE', "/event-locations/{$loc->id}", 'admin');
        $this->assertSame(204, $status);
        $this->assertNull(EventLocation::find($loc->id));
        $this->assertNotNull(EventLocation::withTrashed()->find($loc->id));
    }

    public function testEditValidationAndKindIsFixed()
    {
        $loc = $this->loc();

        [$status, $body] = $this->api('PATCH', "/event-locations/{$loc->id}", 'committee', ['name' => '']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('name', $body['errors']);

        [$status, $body] = $this->api('PATCH', "/event-locations/{$loc->id}", 'committee', ['lat' => 120]);
        $this->assertSame(422, $status);

        [$status, $body] = $this->api('PATCH', "/event-locations/{$loc->id}", 'committee', ['kind' => 'race', 'region' => null]);
        $this->assertSame(200, $status);
        $this->assertSame('parkrun', $body['kind']);
        $this->assertNull($body['region']);
    }

    public function testMissingOrForeignLocationsAre404AndDeleteIsIdempotent()
    {
        $this->otherClub();
        $theirs = EventLocation::create(['club_id' => 2, 'kind' => 'race', 'name' => 'Theirs']);
        $mine = $this->loc();

        foreach ([$theirs->id, '5b1ebc59-3ab4-4f0d-9c4b-111111111111'] as $id) {
            [$status] = $this->api('PATCH', "/event-locations/$id", 'committee', ['name' => 'x']);
            $this->assertSame(404, $status);
            [$status] = $this->api('DELETE', "/event-locations/$id", 'committee');
            $this->assertSame(404, $status);
        }

        $this->assertSame(204, $this->api('DELETE', "/event-locations/{$mine->id}", 'committee')[0]);
        $this->assertSame(204, $this->api('DELETE', "/event-locations/{$mine->id}", 'committee')[0]);
        [$status] = $this->api('PATCH', "/event-locations/{$mine->id}", 'committee', ['name' => 'x']);
        $this->assertSame(404, $status, 'a deleted location cannot be edited');
    }

    public function testDeletingALocationInUseKeepsItsGroups()
    {
        $loc = $this->loc();
        $s = $this->session(['group_mode' => 'events']);
        [, $group] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['locationId' => $loc->id]);

        [$status] = $this->api('DELETE', "/event-locations/{$loc->id}", 'committee');

        $this->assertSame(204, $status);
        $kept = SessionGroup::find($group['id']);
        $this->assertSame('Worcester parkrun', $kept->label);
        $this->assertSame($loc->id, $kept->location_id);

        // The deleted location can no longer be used for a new event.
        $other = $this->session(['group_mode' => 'events', 'date' => '2026-10-19']);
        [$status, $body] = $this->api('POST', "/sessions/{$other->id}/groups", 'plain', ['locationId' => $loc->id]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('locationId', $body['errors']);
    }

    public function testEditingALocationKeepsTheLabelOfItsGroups()
    {
        $loc = $this->loc();
        $s = $this->session(['group_mode' => 'events']);
        [, $group] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['locationId' => $loc->id]);

        $this->api('PATCH', "/event-locations/{$loc->id}", 'committee', ['name' => 'Renamed parkrun']);

        $this->assertSame('Worcester parkrun', SessionGroup::find($group['id'])->label);
    }
}
