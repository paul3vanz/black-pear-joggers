<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubMember;
use App\Models\MemberPhoto;
use App\Models\MemberProfile;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\UploadedFile;

/**
 * Shared fixtures for the Phase 6.5 (member profile card) tests. "Now" is Monday
 * 2026-10-12 09:00 UTC. Photos are tiny hand-built JPEG headers (no GD needed:
 * the API only reads the header, and the app does the real encoding).
 */
abstract class AppProfilesBase extends AppGroupsBase
{
    protected const KEY = 'base64:dGVzdC1rZXktZm9yLXRoZS1waG90by1saW5rcyEhIQ==';

    protected $savedKey;

    protected function setUp(): void
    {
        parent::setUp();

        $this->savedKey = [getenv('APP_KEY'), $_ENV['APP_KEY'] ?? null, $_SERVER['APP_KEY'] ?? null];
        $this->setKey(self::KEY);
    }

    protected function tearDown(): void
    {
        [$env, $envArray, $server] = $this->savedKey;
        putenv($env === false ? 'APP_KEY' : 'APP_KEY=' . $env);
        unset($_ENV['APP_KEY'], $_SERVER['APP_KEY']);

        if ($envArray !== null) {
            $_ENV['APP_KEY'] = $envArray;
        }

        if ($server !== null) {
            $_SERVER['APP_KEY'] = $server;
        }

        parent::tearDown();
    }

    protected function setKey(string $key): void
    {
        putenv('APP_KEY=' . $key);
        $_ENV['APP_KEY'] = $key;
        $_SERVER['APP_KEY'] = $key;
    }

    /** A JPEG whose header says $w x $h; $pad extra bytes go before the end marker. */
    protected function jpeg(int $w = 512, int $h = 512, int $pad = 0): string
    {
        return "\xFF\xD8"
            . "\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
            . "\xFF\xC0\x00\x0B\x08" . pack('n', $h) . pack('n', $w) . "\x01\x01\x11\x00"
            . "\xFF\xDA\x00\x08\x01\x01\x00\x00\x3F\x00"
            . str_repeat("\x5A", $pad)
            . "\xFF\xD9";
    }

    protected function png(): string
    {
        return base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
    }

    protected function uuid(): string
    {
        return (string) \Illuminate\Support\Str::uuid();
    }

    protected function path(string $uri = ''): string
    {
        return '/app/clubs/1/member-profile' . $uri;
    }

    /** Uploads bytes as the multipart file field $field. Returns [status, json]. */
    protected function upload(?string $sub, string $bytes, string $method = 'PUT', string $field = 'photo'): array
    {
        $tmp = tempnam(sys_get_temp_dir(), 'bpj');
        file_put_contents($tmp, $bytes);
        $this->app['auth']->forgetGuards();

        $server = $sub ? ['HTTP_X_TEST_SUB' => $sub, 'HTTP_ACCEPT' => 'application/json'] : [];
        $this->call($method, $this->path('/photo'), [], [], [$field => new UploadedFile($tmp, 'photo.jpg', 'image/jpeg', null, true)], $server);
        @unlink($tmp);

        return [$this->response->getStatusCode(), json_decode($this->response->getContent(), true)];
    }

    /** A multipart body built by hand, as PHP would leave it for a PUT (no $_FILES). */
    protected function rawUpload(?string $sub, string $bytes, string $method = 'PUT', string $field = 'photo'): array
    {
        $boundary = '----bpjtest' . bin2hex(random_bytes(4));
        $body = "--$boundary\r\nContent-Disposition: form-data; name=\"$field\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n"
            . $bytes . "\r\n--$boundary--\r\n";
        $this->app['auth']->forgetGuards();

        $server = ['CONTENT_TYPE' => 'multipart/form-data; boundary=' . $boundary, 'HTTP_ACCEPT' => 'application/json'];
        if ($sub) {
            $server['HTTP_X_TEST_SUB'] = $sub;
        }
        $this->call($method, $this->path('/photo'), [], [], [], $server, $body);

        return [$this->response->getStatusCode(), json_decode($this->response->getContent(), true)];
    }

    /** GET a (relative, signed) photo path with no credentials. Returns the status. */
    protected function download(string $path): int
    {
        $this->app['auth']->forgetGuards();
        $this->call('GET', $path);

        return $this->response->getStatusCode();
    }

    protected function profile(ClubMember $member): ?MemberProfile
    {
        return MemberProfile::where('member_id', $member->id)->first();
    }

    /** Gives a member a profile row (and optionally a photo) directly. */
    protected function seedProfile(ClubMember $member, array $attrs = [], bool $photo = false): MemberProfile
    {
        $profile = MemberProfile::create($attrs + ['club_id' => 1, 'member_id' => $member->id]);

        if ($photo) {
            MemberPhoto::create(['club_id' => 1, 'member_id' => $member->id, 'image' => $this->jpeg()]);
            $profile->photo_version = 'abcd1234';
            $profile->photo_updated_at = \Illuminate\Support\Carbon::now();
            $profile->save();
        }

        return $profile;
    }

    protected function otherClub(): void
    {
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other club', 'slug' => 'other', 'timezone' => 'Europe/London']);
    }
}
