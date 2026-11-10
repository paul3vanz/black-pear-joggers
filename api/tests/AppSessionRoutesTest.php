<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\SessionGroup;
use App\Models\SessionRoute;

/**
 * D130: routes set for a run, and groups picking one with routeId.
 */
class AppSessionRoutesTest extends AppGroupsBase
{
    private function route(string $sub, $session, array $body = []): array
    {
        return $this->api('POST', "/sessions/{$session->id}/routes", $sub, $body + [
            'label' => '10 mile', 'url' => 'https://www.plotaroute.com/route/403075', 'distanceValue' => 10, 'distanceUnit' => 'mi',
        ]);
    }

    public function testManagersAndTheCoordinatorAddRoutesOthersCannot()
    {
        $s = $this->session();

        foreach (['plain', 'leaderA', 'leaderB'] as $sub) {
            [$status, $body] = $this->route($sub, $s);
            $this->assertSame(403, $status, $sub);
            $this->assertSame('forbidden', $body['error']);
        }

        foreach (['coord', 'committee', 'admin'] as $i => $sub) {
            [$status, $body] = $this->route($sub, $s, ['label' => "By $sub"]);
            $this->assertSame(201, $status, $sub);
            $this->assertSame($i, $body['sortOrder']);
            $this->assertEquals(10.0, $body["distanceValue"]);
            $this->assertSame(16093, $body['distanceM']);
        }

        $this->assertSame(3, SessionRoute::where('session_id', $s->id)->count());
    }

    public function testRoutesComeWithTheRunInOrderAndAreIdempotentOnId()
    {
        $s = $this->session();
        $id = '11111111-1111-4111-8111-111111111111';
        [$status] = $this->route('committee', $s, ['id' => $id]);
        $this->assertSame(201, $status);
        [$status] = $this->route('committee', $s, ['id' => $id]);
        $this->assertSame(200, $status);
        $this->route('committee', $s, ['label' => '14 mile', 'url' => 'https://example.com/14', 'distanceValue' => 14]);

        [$status, $body] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
        $this->assertSame(200, $status);
        $this->assertSame(['10 mile', '14 mile'], array_column($body['items'][0]['routes'], 'label'));
    }

    public function testRouteValidation()
    {
        $s = $this->session();

        foreach ([
            ['url' => 'javascript:alert(1)'], ['url' => 'not a url'], ['label' => ''], ['url' => ''],
            ['distanceValue' => 500], ['distanceUnit' => null],
        ] as $bad) {
            [$status] = $this->route('committee', $s, $bad);
            $this->assertSame(422, $status, json_encode($bad));
        }
    }

    public function testEditAndDeleteARoute()
    {
        $s = $this->session();
        [, $r] = $this->route('committee', $s);

        [$status, $body] = $this->api('PATCH', "/routes/{$r['id']}", 'plain', ['label' => 'Nope']);
        $this->assertSame(403, $status);

        [$status, $body] = $this->api('PATCH', "/routes/{$r['id']}", 'coord', ['label' => 'Ten', 'distanceValue' => null, 'distanceUnit' => null]);
        $this->assertSame(200, $status);
        $this->assertSame('Ten', $body['label']);
        $this->assertNull($body['distanceValue']);

        [$status] = $this->api('DELETE', "/routes/{$r['id']}", 'coord');
        $this->assertSame(204, $status);
        [$status] = $this->api('DELETE', "/routes/{$r['id']}", 'coord');
        $this->assertSame(204, $status);

        [, $run] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
        $this->assertSame([], $run['items'][0]['routes']);
    }

    public function testAGroupPicksARouteAndEveryoneGetsItsLink()
    {
        $s = $this->session();
        [, $r] = $this->route('committee', $s);

        [$status, $g] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', [
            'label' => 'Steady', 'routeId' => $r['id'], 'lead' => true,
        ]);
        $this->assertSame(201, $status);
        $this->assertSame($r['id'], $g['routeId']);
        $this->assertSame('10 mile', $g['routeLabel']);
        $this->assertSame($r['url'], $g['routeUrl']);

        // Editing the route is followed by the group.
        [$st, $pb] = $this->api("PATCH", "/routes/{$r['id']}", "committee", ["url" => "https://example.com/new"]);
        $this->assertSame(200, $st, json_encode($pb));
        [, $run] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
        $this->assertSame('https://example.com/new', $run['items'][0]['groups'][0]['routeUrl']);
    }

    public function testAGroupHasARouteOrItsOwnLinkNeverBoth()
    {
        $s = $this->session();
        [, $r] = $this->route('committee', $s);
        $g = $this->group($s, [$this->leaderA], ['label' => 'Steady']);

        [$status] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['routeId' => $r['id'], 'routeUrl' => 'https://example.com/own']);
        $this->assertSame(422, $status);

        [, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['routeId' => $r['id'], 'routeUrl' => null]);
        $this->assertSame($r['id'], $body['routeId']);

        // Their own link replaces the route.
        [, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['routeUrl' => 'https://example.com/own']);
        $this->assertNull($body['routeId']);
        $this->assertNull($body['routeLabel']);
        $this->assertSame('https://example.com/own', $body['routeUrl']);

        // And picking a route again clears the link.
        [, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['routeId' => $r['id']]);
        $this->assertSame($r['url'], $body['routeUrl']);
        $this->assertNull(SessionGroup::find($g->id)->route_url);

        [, $body] = $this->api('PATCH', "/groups/{$g->id}", 'leaderA', ['routeId' => null]);
        $this->assertNull($body['routeUrl']);
    }

    public function testARouteOfAnotherRunOrAnUnknownRouteIsRefused()
    {
        $s = $this->session();
        $other = $this->session(['date' => '2026-10-19']);
        [, $theirs] = $this->route('committee', $other);

        foreach ([$theirs['id'], '22222222-2222-4222-8222-222222222222'] as $id) {
            [$status, $body] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', [
                'label' => 'Steady', 'routeId' => $id, 'lead' => true,
            ]);
            $this->assertSame(422, $status);
            $this->assertArrayHasKey('routeId', $body['errors']);
        }
    }

    public function testDeletingARouteLeavesItsGroupsWithNone()
    {
        $s = $this->session();
        [, $r] = $this->route('committee', $s);
        [, $g] = $this->api('POST', "/sessions/{$s->id}/groups", 'leaderA', ['label' => 'Steady', 'routeId' => $r['id'], 'lead' => true]);

        $this->api('DELETE', "/routes/{$r['id']}", 'committee');

        [, $run] = $this->api('GET', '/sessions?from=2026-10-12&to=2026-10-12', 'plain');
        $group = $run['items'][0]['groups'][0];
        $this->assertSame($g['id'], $group['id']);
        $this->assertNull($group['routeId']);
        $this->assertNull($group['routeUrl']);
    }
}
