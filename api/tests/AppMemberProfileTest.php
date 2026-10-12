<?php

require_once __DIR__ . '/AppProfilesBase.php';

use App\Models\MemberPhoto;
use App\Models\MemberProfile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 6.5a: the caller's own card (GET/PUT member-profile) and photo (PUT/DELETE).
 */
class AppMemberProfileTest extends AppProfilesBase
{
    // ---- schema ----------------------------------------------------------------------

    public function testTablesExistWithTheContractColumns()
    {
        $this->assertTrue(Schema::hasTable('member_profiles'));
        $this->assertTrue(Schema::hasTable('member_photos'));
        $this->assertSame(
            ['bio', 'club_id', 'created_at', 'goals', 'goals_visible', 'id', 'member_id', 'photo_updated_at', 'photo_version', 'updated_at'],
            collect(Schema::getColumnListing('member_profiles'))->sort()->values()->all()
        );
        $this->assertSame(
            ['club_id', 'created_at', 'image', 'member_id', 'updated_at'],
            collect(Schema::getColumnListing('member_photos'))->sort()->values()->all()
        );
    }

    public function testTheBlobSurvivesARoundTripIncludingNulBytes()
    {
        $bytes = $this->jpeg(512, 512, 1000) . "\x00\x00\xFF\x80binary";
        MemberPhoto::create(['club_id' => 1, 'member_id' => $this->plain->id, 'image' => $bytes]);

        $this->assertSame($bytes, MemberPhoto::where('member_id', $this->plain->id)->value('image'));
    }

    // ---- GET -------------------------------------------------------------------------

    public function testAMemberWithNoCardGetsNullsAndNoRowIsCreated()
    {
        [$status, $body] = $this->api('GET', '/member-profile', 'plain');

        $this->assertSame(200, $status);
        $this->assertSame(
            ['bio' => null, 'goals' => null, 'goalsVisible' => false, 'photoPath' => null, 'updatedAt' => null],
            $body
        );
        $this->assertSame(0, MemberProfile::count());
    }

    public function testNeedsSignInAndAClubMembership()
    {
        [$status] = $this->api('GET', '/member-profile', null);
        $this->assertSame(401, $status);
        [$status] = $this->api('PUT', '/member-profile', null, ['bio' => 'x']);
        $this->assertSame(401, $status);

        $this->member('stranger', 399);
        [$status, $body] = $this->call_('GET', '/app/clubs/2/member-profile', 'stranger');
        $this->assertSame(404, $status);
        $this->assertSame('club_not_found', $body['error']);

        $this->otherClub();
        [$status, $body] = $this->call_('GET', '/app/clubs/2/member-profile', 'stranger');
        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);
    }

    // ---- PUT -------------------------------------------------------------------------

    public function testPutSavesAndTrims()
    {
        [$status, $body] = $this->api('PUT', '/member-profile', 'plain', [
            'bio' => "  Likes hills.  \n",
            'goals' => ' Sub-25 5k ',
            'goalsVisible' => true,
        ]);

        $this->assertSame(200, $status);
        $this->assertSame('Likes hills.', $body['bio']);
        $this->assertSame('Sub-25 5k', $body['goals']);
        $this->assertTrue($body['goalsVisible']);
        $this->assertNull($body['photoPath']);
        $this->assertSame('2026-10-12T09:00:00.000Z', $body['updatedAt']);

        $this->assertSame($body, $this->api('GET', '/member-profile', 'plain')[1]);
        $this->assertSame(1, MemberProfile::count());
    }

    public function testPartialUpdatesLeaveOmittedKeysAlone()
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Hello', 'goals' => 'Goal', 'goalsVisible' => true]);

        [, $body] = $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Changed']);
        $this->assertSame(['Changed', 'Goal', true], [$body['bio'], $body['goals'], $body['goalsVisible']]);

        [, $body] = $this->api('PUT', '/member-profile', 'plain', ['goalsVisible' => false]);
        $this->assertSame(['Changed', 'Goal', false], [$body['bio'], $body['goals'], $body['goalsVisible']]);

        [, $body] = $this->api('PUT', '/member-profile', 'plain', ['goals' => 'Other']);
        $this->assertSame(['Changed', 'Other', false], [$body['bio'], $body['goals'], $body['goalsVisible']]);

        [$status, $body] = $this->api('PUT', '/member-profile', 'plain', []);
        $this->assertSame(200, $status);
        $this->assertSame(['Changed', 'Other', false], [$body['bio'], $body['goals'], $body['goalsVisible']]);
        $this->assertSame(1, MemberProfile::count());
    }

    public function testNullOrBlankClearsATextField()
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Hello', 'goals' => 'Goal']);

        [, $body] = $this->api('PUT', '/member-profile', 'plain', ['bio' => null]);
        $this->assertNull($body['bio']);
        $this->assertSame('Goal', $body['goals']);

        [, $body] = $this->api('PUT', '/member-profile', 'plain', ['goals' => "  \n\t "]);
        $this->assertNull($body['goals']);
        $this->assertNull(MemberProfile::first()->goals);
    }

    public function testLimitsAreCountedAfterTrimmingAndInCharacters()
    {
        [$status, $body] = $this->api('PUT', '/member-profile', 'plain', ['bio' => str_repeat('a', 300), 'goals' => str_repeat('g', 1000)]);
        $this->assertSame(200, $status);
        $this->assertSame(300, strlen($body['bio']));

        [$status] = $this->api('PUT', '/member-profile', 'plain', ['bio' => '  ' . str_repeat('b', 300) . '  ']);
        $this->assertSame(200, $status);

        // 300 two-byte characters are fine: it is a character limit.
        [$status, $body] = $this->api('PUT', '/member-profile', 'plain', ['bio' => str_repeat('é', 300)]);
        $this->assertSame(200, $status);
        $this->assertSame(str_repeat('é', 300), $body['bio']);
    }

    /**
     * @dataProvider invalidBodies
     */
    public function testValidationMatrix(array $data, string $field)
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Keep me']);

        [$status, $body] = $this->api('PUT', '/member-profile', 'plain', $data);

        $this->assertSame(422, $status);
        $this->assertSame('validation_failed', $body['error']);
        $this->assertArrayHasKey($field, $body['errors']);
        $this->assertSame('Keep me', MemberProfile::first()->bio, 'nothing is saved');
    }

    public static function invalidBodies(): array
    {
        return [
            '301-char bio' => [['bio' => str_repeat('a', 301)], 'bio'],
            '1001-char goals' => [['goals' => str_repeat('g', 1001)], 'goals'],
            'bio number' => [['bio' => 12], 'bio'],
            'bio array' => [['bio' => ['x']], 'bio'],
            'bio bool' => [['bio' => true], 'bio'],
            'goals number' => [['goals' => 5], 'goals'],
            'goals object' => [['goals' => ['a' => 'b']], 'goals'],
            'goalsVisible string' => [['goalsVisible' => 'true'], 'goalsVisible'],
            'goalsVisible 1' => [['goalsVisible' => 1], 'goalsVisible'],
            'goalsVisible 0' => [['goalsVisible' => 0], 'goalsVisible'],
            'goalsVisible null' => [['goalsVisible' => null], 'goalsVisible'],
            'goalsVisible array' => [['goalsVisible' => [true]], 'goalsVisible'],
            'one bad key spoils a good one' => [['goals' => 'fine', 'bio' => str_repeat('a', 301)], 'bio'],
        ];
    }

    public function testEveryWriteBumpsUpdatedAt()
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'a']);
        $this->tick(120);
        [, $body] = $this->api('PUT', '/member-profile', 'plain', ['bio' => 'b']);
        $this->assertSame('2026-10-12T09:02:00.000Z', $body['updatedAt']);

        $this->tick(120);
        [, $body] = $this->upload('plain', $this->jpeg()) ;
        $this->assertSame('2026-10-12T09:04:00.000Z', $body['updatedAt']);

        $this->tick(120);
        [, $body] = $this->api('DELETE', '/member-profile/photo', 'plain');
        $this->assertSame('2026-10-12T09:06:00.000Z', $body['updatedAt']);
    }

    public function testCardsAreIndependentPerMember()
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'mine']);
        $this->api('PUT', '/member-profile', 'leaderA', ['bio' => 'theirs']);

        $this->assertSame('mine', $this->api('GET', '/member-profile', 'plain')[1]['bio']);
        $this->assertSame('theirs', $this->api('GET', '/member-profile', 'leaderA')[1]['bio']);
        $this->assertNull($this->api('GET', '/member-profile', 'coord')[1]['bio']);
    }

    // ---- photo upload ----------------------------------------------------------------

    public function testUploadStoresThePhotoAndReturnsASignedRelativePath()
    {
        [$status, $body] = $this->upload('plain', $this->jpeg(512, 512, 3000));

        $this->assertSame(200, $status);
        $this->assertMatchesRegularExpression(
            '#^/app/clubs/1/members/' . $this->plain->id . '/photo\?v=[0-9a-f]{8}&sig=[0-9a-f]{64}$#',
            $body['photoPath']
        );
        $this->assertNull($body['bio']);
        $this->assertFalse($body['goalsVisible']);

        $profile = $this->profile($this->plain);
        $this->assertMatchesRegularExpression('/^[0-9a-f]{8}$/', $profile->photo_version);
        $this->assertNotNull($profile->photo_updated_at);
        $this->assertSame(1, MemberPhoto::count());
        $this->assertSame($this->jpeg(512, 512, 3000), MemberPhoto::value('image'));
        $this->assertSame($body, $this->api('GET', '/member-profile', 'plain')[1]);
    }

    public function testUploadKeepsTheTextFields()
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Hi', 'goals' => 'Go', 'goalsVisible' => true]);

        [, $body] = $this->upload('plain', $this->jpeg());

        $this->assertSame(['Hi', 'Go', true], [$body['bio'], $body['goals'], $body['goalsVisible']]);
    }

    public function testBoundaryDimensionsAndSizeAreAccepted()
    {
        foreach ([[64, 64], [1024, 1024], [64, 1024], [1024, 64], [200, 700]] as [$w, $h]) {
            [$status] = $this->upload('plain', $this->jpeg($w, $h));
            $this->assertSame(200, $status, "{$w}x{$h}");
        }

        $exact = $this->jpeg(512, 512);
        $exact .= str_repeat("\x5A", 400 * 1024 - strlen($exact));
        $this->assertSame(400 * 1024, strlen($exact));
        [$status] = $this->upload('plain', $exact);
        $this->assertSame(200, $status, '400 KB exactly');
    }

    /**
     * @dataProvider badPhotos
     */
    public function testBadPhotosAre422OnThePhotoField(string $kind, string $messagePart)
    {
        $this->upload('plain', $this->jpeg()); // an existing photo must survive a bad upload
        $before = $this->api('GET', '/member-profile', 'plain')[1]['photoPath'];

        $bytes = [
            'png' => $this->png(),
            'text' => 'definitely not an image',
            'empty header' => "\xFF\xD8\xFF",
            'truncated' => "\xFF\xD8\xFF\xE0\x00\x10JFIF",
            'small' => $this->jpeg(63, 512),
            'short' => $this->jpeg(512, 63),
            'wide' => $this->jpeg(1025, 512),
            'tall' => $this->jpeg(512, 1025),
            'oversize' => $this->jpeg(512, 512, 400 * 1024),
            'gif' => "GIF89a\x01\x00\x01\x00\x00\x00\x00;",
        ][$kind];

        [$status, $body] = $this->upload('plain', $bytes);

        $this->assertSame(422, $status, $kind);
        $this->assertSame('validation_failed', $body['error']);
        $this->assertArrayHasKey('photo', $body['errors']);
        $this->assertStringContainsString($messagePart, $body['message']);
        $this->assertSame($body['message'], $body['errors']['photo'][0]);
        $this->assertSame($before, $this->api('GET', '/member-profile', 'plain')[1]['photoPath'], 'unchanged');
        $this->assertSame(1, MemberPhoto::count());
    }

    public static function badPhotos(): array
    {
        return [
            'png' => ['png', 'JPEG'],
            'text' => ['text', 'JPEG'],
            'gif' => ['gif', 'JPEG'],
            'magic bytes only' => ['empty header', 'valid JPEG'],
            'truncated header' => ['truncated', 'valid JPEG'],
            '63 px wide' => ['small', 'too small'],
            '63 px tall' => ['short', 'too small'],
            '1025 px wide' => ['wide', 'too big'],
            '1025 px tall' => ['tall', 'too big'],
            'over 400 KB' => ['oversize', 'too large'],
        ];
    }

    public function testAJpegNamedAsAnythingIsJudgedByItsBytes()
    {
        // The client's file name and mime type are ignored: a PNG sent as image/jpeg is refused.
        [$status] = $this->upload('plain', $this->png());
        $this->assertSame(422, $status);
    }

    public function testMissingFileOrWrongFieldIs422()
    {
        $this->app['auth']->forgetGuards();
        $this->call('PUT', $this->path('/photo'), [], [], [], ['HTTP_X_TEST_SUB' => 'plain']);
        $this->assertSame(422, $this->response->getStatusCode());
        $body = json_decode($this->response->getContent(), true);
        $this->assertArrayHasKey('photo', $body['errors']);

        [$status, $body] = $this->upload('plain', $this->jpeg(), 'PUT', 'image');
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('photo', $body['errors']);

        [$status] = $this->api('PUT', '/member-profile/photo', 'plain', ['photo' => 'not a file']);
        $this->assertSame(422, $status);

        $this->assertSame(0, MemberPhoto::count());
        $this->assertSame(0, MemberProfile::count());
    }

    public function testAFailedUploadIsReportedNotThrown()
    {
        $tmp = tempnam(sys_get_temp_dir(), 'bpj');
        file_put_contents($tmp, '');
        $this->app['auth']->forgetGuards();
        $file = new \Illuminate\Http\UploadedFile($tmp, 'photo.jpg', 'image/jpeg', UPLOAD_ERR_INI_SIZE, true);
        $this->call('PUT', $this->path('/photo'), [], [], ['photo' => $file], ['HTTP_X_TEST_SUB' => 'plain']);
        @unlink($tmp);

        $this->assertSame(422, $this->response->getStatusCode());
        $this->assertStringContainsString('too large', json_decode($this->response->getContent(), true)['message']);
    }

    public function testAMultipartPutThatPhpDidNotParseIsReadByHand()
    {
        [$status, $body] = $this->rawUpload('plain', $this->jpeg(300, 300, 500));

        $this->assertSame(200, $status);
        $this->assertNotNull($body['photoPath']);
        $this->assertSame($this->jpeg(300, 300, 500), MemberPhoto::value('image'));

        [$status, $body] = $this->rawUpload('plain', $this->png());
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('photo', $body['errors']);

        [$status, $body] = $this->rawUpload('plain', $this->jpeg(), 'PUT', 'other');
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('photo', $body['errors']);
    }

    public function testPostWorksToo()
    {
        [$status, $body] = $this->upload('plain', $this->jpeg(), 'POST');
        $this->assertSame(200, $status);
        $this->assertNotNull($body['photoPath']);
    }

    public function testReplacingChangesTheVersionAndKillsTheOldLink()
    {
        [, $first] = $this->upload('plain', $this->jpeg(512, 512, 10));
        $this->assertSame(200, $this->download($first['photoPath']));

        [, $second] = $this->upload('plain', $this->jpeg(256, 256, 20));

        $this->assertNotSame($first['photoPath'], $second['photoPath']);
        $this->assertNotSame(
            $this->versionOf($first['photoPath']),
            $this->versionOf($second['photoPath'])
        );
        $this->assertSame(404, $this->download($first['photoPath']));
        $this->assertSame(200, $this->download($second['photoPath']));
        $this->assertSame($this->jpeg(256, 256, 20), $this->response->getContent());
        $this->assertSame(1, MemberPhoto::count(), 'the old image is replaced, not kept');
    }

    public function testUploadingTheSameBytesAgainStillGetsAFreshVersion()
    {
        $seen = [];

        for ($i = 0; $i < 5; $i++) {
            [, $body] = $this->upload('plain', $this->jpeg());
            $seen[] = $this->versionOf($body['photoPath']);
        }

        $this->assertSame($seen, array_values(array_unique($seen)));
    }

    // ---- photo delete ----------------------------------------------------------------

    public function testDeleteRemovesTheImageAndIsIdempotent()
    {
        $this->api('PUT', '/member-profile', 'plain', ['bio' => 'Hi']);
        [, $card] = $this->upload('plain', $this->jpeg());

        [$status, $body] = $this->api('DELETE', '/member-profile/photo', 'plain');
        $this->assertSame(200, $status);
        $this->assertNull($body['photoPath']);
        $this->assertSame('Hi', $body['bio']);
        $this->assertSame(0, MemberPhoto::count());
        $this->assertNull($this->profile($this->plain)->photo_version);
        $this->assertNull($this->profile($this->plain)->photo_updated_at);
        $this->assertSame(404, $this->download($card['photoPath']));

        [$status, $again] = $this->api('DELETE', '/member-profile/photo', 'plain');
        $this->assertSame(200, $status);
        $this->assertSame($body['photoPath'], $again['photoPath']);
    }

    public function testDeleteWithNothingStoredCreatesNothing()
    {
        [$status, $body] = $this->api('DELETE', '/member-profile/photo', 'plain');

        $this->assertSame(200, $status);
        $this->assertNull($body['photoPath']);
        $this->assertSame(0, MemberProfile::count());
    }

    public function testDeletingOnlyAffectsTheCaller()
    {
        $this->upload('plain', $this->jpeg());
        $this->upload('leaderA', $this->jpeg());

        $this->api('DELETE', '/member-profile/photo', 'plain');

        $this->assertSame(1, MemberPhoto::count());
        $this->assertNotNull($this->api('GET', '/member-profile', 'leaderA')[1]['photoPath']);
    }

    public function testPhotoWritesNeedSignIn()
    {
        [$status] = $this->upload(null, $this->jpeg());
        $this->assertSame(401, $status);
        [$status] = $this->api('DELETE', '/member-profile/photo', null);
        $this->assertSame(401, $status);
    }

    private function versionOf(string $path): string
    {
        parse_str((string) parse_url($path, PHP_URL_QUERY), $q);

        return $q['v'];
    }
}
