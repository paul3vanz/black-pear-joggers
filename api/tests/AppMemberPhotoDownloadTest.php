<?php

require_once __DIR__ . '/AppProfilesBase.php';

use App\Models\MemberPhoto;
use App\Models\MemberProfile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;

/**
 * Phase 6.5a: the signed photo download. No Authorization header, so it is the
 * link itself that must be right.
 */
class AppMemberPhotoDownloadTest extends AppProfilesBase
{
    private function photoPathFor(string $sub, ?string $bytes = null): string
    {
        return $this->upload($sub, $bytes ?? $this->jpeg(512, 512, 50))[1]['photoPath'];
    }

    private function get_(string $path): array
    {
        $this->app['auth']->forgetGuards();
        $this->call('GET', $path);

        return [$this->response->getStatusCode(), $this->response->getContent()];
    }

    public function testAGoodLinkServesTheJpegWithoutAnyAuthHeader()
    {
        $path = $this->photoPathFor('plain');

        [$status, $content] = $this->get_($path);

        $this->assertSame(200, $status);
        $this->assertSame($this->jpeg(512, 512, 50), $content);
        $this->assertSame('image/jpeg', $this->response->headers->get('Content-Type'));
        $this->assertSame((string) strlen($content), $this->response->headers->get('Content-Length'));
        $this->assertSame('nosniff', $this->response->headers->get('X-Content-Type-Options'));
    }

    public function testCacheHeadersAllowAYearOfPrivateCaching()
    {
        $this->get_($this->photoPathFor('plain'));

        $cache = $this->response->headers->get('Cache-Control');
        $this->assertStringContainsString('private', $cache);
        $this->assertStringContainsString('max-age=31536000', $cache);
        $this->assertStringContainsString('immutable', $cache);
        $this->assertStringNotContainsString('no-cache', $cache);
        $this->assertStringNotContainsString('public', $cache);
    }

    public function testTheLinkIsRelativeAndSignedWithTheKeyExactlyAsWritten()
    {
        $path = $this->photoPathFor('plain');
        parse_str(parse_url($path, PHP_URL_QUERY), $q);

        $this->assertStringStartsWith('/app/clubs/1/members/' . $this->plain->id . '/photo?', $path);
        $this->assertSame(
            hash_hmac('sha256', '1|' . $this->plain->id . '|' . $q['v'], self::KEY),
            $q['sig'],
            'the base64: prefix is part of the secret and is not decoded'
        );
    }

    public function testABadOrMissingSignatureIs404()
    {
        $path = $this->photoPathFor('plain');
        parse_str(parse_url($path, PHP_URL_QUERY), $q);
        $base = parse_url($path, PHP_URL_PATH);

        $bad = [
            'wrong sig' => "$base?v={$q['v']}&sig=" . str_repeat('0', 64),
            'truncated sig' => "$base?v={$q['v']}&sig=" . substr($q['sig'], 0, 63),
            'upper-cased sig' => "$base?v={$q['v']}&sig=" . strtoupper($q['sig']),
            'no sig' => "$base?v={$q['v']}",
            'empty sig' => "$base?v={$q['v']}&sig=",
            'no v' => "$base?sig={$q['sig']}",
            'no query' => $base,
            'sig array' => "$base?v={$q['v']}&sig[]={$q['sig']}",
            'v array' => "$base?v[]={$q['v']}&sig={$q['sig']}",
        ];

        foreach ($bad as $why => $url) {
            [$status, $content] = $this->get_($url);
            $this->assertSame(404, $status, $why);
            $this->assertSame('not_found', json_decode($content, true)['error'], $why);
        }
    }

    public function testAStaleVersionIs404EvenWithAValidSignatureForIt()
    {
        $path = $this->photoPathFor('plain');
        parse_str(parse_url($path, PHP_URL_QUERY), $q);
        $stale = '00000000';

        // Properly signed, but not the member's current version.
        $sig = hash_hmac('sha256', '1|' . $this->plain->id . '|' . $stale, self::KEY);
        $this->assertSame(404, $this->get_(parse_url($path, PHP_URL_PATH) . "?v=$stale&sig=$sig")[0]);

        // A real version with the stale signature.
        $this->assertSame(404, $this->get_(parse_url($path, PHP_URL_PATH) . "?v={$q['v']}&sig=$sig")[0]);
    }

    public function testNoPhotoIs404()
    {
        $profile = $this->seedProfile($this->plain, ['bio' => 'Hi']);
        $sig = hash_hmac('sha256', '1|' . $this->plain->id . '|abcd1234', self::KEY);

        // No version at all.
        $this->assertSame(404, $this->get_("/app/clubs/1/members/{$this->plain->id}/photo?v=abcd1234&sig=$sig")[0]);

        // A version but no image row (never happens through the API; must not 500).
        $profile->photo_version = 'abcd1234';
        $profile->save();
        $this->assertSame(404, $this->get_("/app/clubs/1/members/{$this->plain->id}/photo?v=abcd1234&sig=$sig")[0]);

        // Unknown member, with a valid signature for it.
        $ghost = $this->uuid();
        $sig = hash_hmac('sha256', "1|$ghost|abcd1234", self::KEY);
        $this->assertSame(404, $this->get_("/app/clubs/1/members/$ghost/photo?v=abcd1234&sig=$sig")[0]);
    }

    public function testAnotherMembersSignatureDoesNotUnlockThisPhoto()
    {
        $mine = $this->photoPathFor('plain');
        $theirs = $this->photoPathFor('leaderA');
        parse_str(parse_url($mine, PHP_URL_QUERY), $a);
        parse_str(parse_url($theirs, PHP_URL_QUERY), $b);

        // leaderA's path with plain's version and signature, and the other way round.
        $this->assertSame(404, $this->get_("/app/clubs/1/members/{$this->leaderA->id}/photo?v={$a['v']}&sig={$a['sig']}")[0]);
        $this->assertSame(404, $this->get_("/app/clubs/1/members/{$this->plain->id}/photo?v={$b['v']}&sig={$b['sig']}")[0]);
        $this->assertSame(200, $this->get_($mine)[0]);
        $this->assertSame(200, $this->get_($theirs)[0]);
    }

    public function testTheClubIsPartOfTheSignature()
    {
        $this->otherClub();
        $path = $this->photoPathFor('plain');
        parse_str(parse_url($path, PHP_URL_QUERY), $q);

        $this->assertSame(404, $this->get_("/app/clubs/2/members/{$this->plain->id}/photo?v={$q['v']}&sig={$q['sig']}")[0]);
        $this->assertSame(404, $this->get_("/app/clubs/x/members/{$this->plain->id}/photo?v={$q['v']}&sig={$q['sig']}")[0]);
    }

    public function testADifferentKeyInvalidatesEveryLink()
    {
        $path = $this->photoPathFor('plain');
        $this->assertSame(200, $this->get_($path)[0]);

        $this->setKey('some-other-key');
        $this->assertSame(404, $this->get_($path)[0]);

        // And a plain (no base64: prefix) key signs and verifies too.
        $new = $this->api('GET', '/member-profile', 'plain')[1]['photoPath'];
        $this->assertNotSame($path, $new);
        $this->assertSame(200, $this->get_($new)[0]);
    }

    public function testWithNoKeyConfiguredNoLinkIsIssuedOrAccepted()
    {
        $path = $this->photoPathFor('plain');
        parse_str(parse_url($path, PHP_URL_QUERY), $q);

        $this->setKey('');
        $this->assertNull($this->api('GET', '/member-profile', 'plain')[1]['photoPath']);

        // The signature an empty key would produce is not accepted either.
        $sig = hash_hmac('sha256', '1|' . $this->plain->id . '|' . $q['v'], '');
        $this->assertSame(404, $this->get_(parse_url($path, PHP_URL_PATH) . "?v={$q['v']}&sig=$sig")[0]);
    }

    public function testADeletedOrClearedPhotoStopsServing()
    {
        $path = $this->photoPathFor('plain');
        $this->assertSame(200, $this->get_($path)[0]);

        $this->api('DELETE', '/member-profile/photo', 'plain');
        $this->assertSame(404, $this->get_($path)[0]);

        $path = $this->photoPathFor('plain');
        $this->assertSame(200, $this->get_($path)[0]);
        $this->api('DELETE', '/members/' . $this->plain->id . '/profile', 'committee');
        $this->assertSame(404, $this->get_($path)[0]);
    }

    public function testTheDownloadIsThrottledTo120PerMinutePerIp()
    {
        $path = $this->photoPathFor('plain');

        for ($i = 1; $i <= 120; $i++) {
            $this->assertSame(200, $this->get_($path)[0], "request $i");
        }

        [$status, $content] = $this->get_($path);
        $this->assertSame(429, $status);
        $this->assertSame('too_many_requests', json_decode($content, true)['error']);
        $this->assertTrue($this->response->headers->has('Retry-After'));

        // The window rolls over.
        Carbon::setTestNow(Carbon::now()->addMinutes(2));
        Cache::flush(); // the array store ignores faked time
        $this->assertSame(200, $this->get_($path)[0]);
    }

    public function testBadLinksCountAgainstTheThrottleToo()
    {
        $base = "/app/clubs/1/members/{$this->plain->id}/photo";

        for ($i = 1; $i <= 120; $i++) {
            $this->assertSame(404, $this->get_("$base?v=abcd1234&sig=nope")[0], "request $i");
        }

        $this->assertSame(429, $this->get_("$base?v=abcd1234&sig=nope")[0]);
    }

    public function testRequestsOnOtherRoutesAreNotThrottledByThePhotoLimit()
    {
        $path = $this->photoPathFor('plain');

        for ($i = 0; $i < 121; $i++) {
            $this->get_($path);
        }

        $this->assertSame(200, $this->api('GET', '/member-profile', 'plain')[0]);
    }
}
