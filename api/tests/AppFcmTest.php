<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Jobs\SendPushNotificationsJob;
use App\Models\Device;
use App\Models\MemberLogin;
use App\Models\Notification;
use App\Services\FcmClient;
use App\Services\GoogleAccessToken;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Response;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use phpseclib3\Crypt\PublicKeyLoader;
use phpseclib3\Crypt\RSA;

/**
 * FcmClient, GoogleAccessToken and SendPushNotificationsJob, with Guzzle's
 * MockHandler standing in for Google. No network.
 */
class AppFcmTest extends AppApiTestCase
{
    private static $privateKey;
    private static $publicKey;

    private $files = [];
    private $history = [];

    public static function setUpBeforeClass(): void
    {
        $key = RSA::createKey(2048);
        self::$privateKey = $key->toString('PKCS8');
        self::$publicKey = $key->getPublicKey();
    }

    protected function setUp(): void
    {
        parent::setUp();

        FcmClient::resetWarning();
    }

    protected function tearDown(): void
    {
        foreach ($this->files as $file) {
            @unlink($file);
        }

        parent::tearDown();
    }

    private function tempFile(string $contents = null): string
    {
        $file = tempnam(sys_get_temp_dir(), 'bpjfcm');
        $this->files[] = $file;

        if ($contents !== null) {
            file_put_contents($file, $contents);
        }

        return $file;
    }

    private function serviceAccountFile(): string
    {
        return $this->tempFile(json_encode([
            'type' => 'service_account',
            'project_id' => 'bpj-test',
            'client_email' => 'push@bpj-test.iam.gserviceaccount.com',
            'private_key' => self::$privateKey,
        ]));
    }

    /** A Guzzle client that answers from $responses and records every request. */
    private function mockClient(array $responses): Client
    {
        $this->history = [];
        $stack = HandlerStack::create(new MockHandler($responses));
        $stack->push(Middleware::history($this->history));

        return new Client(['handler' => $stack]);
    }

    private function tokenResponse(): Response
    {
        return new Response(200, [], json_encode(['access_token' => 'ya29.test', 'expires_in' => 3600, 'token_type' => 'Bearer']));
    }

    private function fcm(array $responses, ?string $account = ''): FcmClient
    {
        $http = $this->mockClient($responses);
        $cache = $this->tempFile();
        unlink($cache); // start with no cached token

        $auth = new GoogleAccessToken($http, $account === '' ? $this->serviceAccountFile() : ($account ?? '/no/such/file.json'), $cache);

        return new FcmClient($http, $auth);
    }

    private function errorResponse(int $code, string $status, string $message = 'x', array $details = []): Response
    {
        return new Response($code, [], json_encode(['error' => ['code' => $code, 'status' => $status, 'message' => $message, 'details' => $details]]));
    }

    private function seedNotification(string $sub = 'u|1', array $devices = ['tok-a']): array
    {
        $member = $this->member($sub, 1);
        $notification = Notification::create([
            'club_id' => 1, 'member_id' => $member->id, 'category' => 'club_updates',
            'title' => 'Hi', 'body' => 'There', 'data' => ['route' => '/updates/abc'],
        ]);

        $made = [];
        foreach ($devices as $token) {
            $made[$token] = Device::create(['user_id' => $sub, 'token' => $token, 'platform' => 'android']);
        }

        return [$member, $notification, $made];
    }

    // ---- JWT and token exchange -----------------------------------------------

    public function testJwtHasTheRightClaimsAndAValidRs256Signature()
    {
        $auth = new GoogleAccessToken($this->mockClient([]), $this->serviceAccountFile(), $this->tempFile());

        $jwt = $auth->buildJwt(1700000000);
        [$header, $claims, $signature] = explode('.', $jwt);

        $decode = function ($part) {
            return base64_decode(strtr($part, '-_', '+/'));
        };

        $this->assertSame(['alg' => 'RS256', 'typ' => 'JWT'], json_decode($decode($header), true));
        $this->assertSame([
            'iss' => 'push@bpj-test.iam.gserviceaccount.com',
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => 1700000000,
            'exp' => 1700003600,
        ], json_decode($decode($claims), true));

        $verifier = self::$publicKey->withPadding(RSA::SIGNATURE_PKCS1)->withHash('sha256');
        $this->assertTrue($verifier->verify("$header.$claims", $decode($signature)));
        $this->assertStringNotContainsString('=', $jwt);
    }

    public function testAccessTokenIsExchangedOnceThenCached()
    {
        $http = $this->mockClient([$this->tokenResponse()]);
        $cache = $this->tempFile();
        unlink($cache);
        $auth = new GoogleAccessToken($http, $this->serviceAccountFile(), $cache);

        $this->assertSame('ya29.test', $auth->get());
        $this->assertSame('ya29.test', $auth->get()); // would fail on an empty mock queue if it called out again

        $this->assertCount(1, $this->history);
        $request = $this->history[0]['request'];
        $this->assertSame('https://oauth2.googleapis.com/token', (string) $request->getUri());
        parse_str((string) $request->getBody(), $form);
        $this->assertSame('urn:ietf:params:oauth:grant-type:jwt-bearer', $form['grant_type']);
        $this->assertCount(3, explode('.', $form['assertion']));
    }

    public function testAnExpiredCachedTokenIsRefreshed()
    {
        $http = $this->mockClient([$this->tokenResponse()]);
        $cache = $this->tempFile(json_encode(['token' => 'stale', 'expires_at' => Carbon::now()->timestamp + 30]));
        $auth = new GoogleAccessToken($http, $this->serviceAccountFile(), $cache);

        $this->assertSame('ya29.test', $auth->get());
        $this->assertCount(1, $this->history);
        $this->assertSame('ya29.test', json_decode(file_get_contents($cache), true)['token']);
    }

    // ---- message building and sending -----------------------------------------

    public function testBuildMessageMatchesTheContractPayload()
    {
        [, $notification, $devices] = $this->seedNotification();
        $fcm = $this->fcm([]);

        $message = $fcm->buildMessage($devices['tok-a'], $notification)['message'];

        $this->assertSame([
            'token' => 'tok-a',
            'notification' => ['title' => 'Hi', 'body' => 'There'],
            'data' => [
                'notificationId' => $notification->id,
                'clubId' => '1',
                'userId' => 'u|1',
                'category' => 'club_updates',
                'route' => '/updates/abc',
            ],
            'android' => ['notification' => ['channel_id' => 'club_updates']],
            'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
        ], $message);

        foreach ($message['data'] as $value) {
            $this->assertIsString($value);
        }
    }

    public function testSendPostsOneMessagePerDeviceWithABearerToken()
    {
        [, $notification, $devices] = $this->seedNotification('u|1', ['tok-a', 'tok-b']);
        $fcm = $this->fcm([$this->tokenResponse(), new Response(200, [], '{}'), new Response(200, [], '{}')]);

        $delivered = $fcm->send([[$devices['tok-a'], $notification], [$devices['tok-b'], $notification]]);

        $this->assertSame([$notification->id => true], $delivered);
        $this->assertCount(3, $this->history); // token + 2 sends

        $sends = array_slice($this->history, 1);
        $tokens = [];
        foreach ($sends as $entry) {
            $request = $entry['request'];
            $this->assertSame('https://fcm.googleapis.com/v1/projects/bpj-test/messages:send', (string) $request->getUri());
            $this->assertSame('Bearer ya29.test', $request->getHeaderLine('Authorization'));
            $tokens[] = json_decode((string) $request->getBody(), true)['message']['token'];
        }
        $this->assertEqualsCanonicalizing(['tok-a', 'tok-b'], $tokens);
        $this->assertSame(2, Device::count());
    }

    public function testDevicesFcmSaysAreGoneAreDeleted()
    {
        [, $notification, $devices] = $this->seedNotification('u|1', ['unreg', 'notfound', 'badtoken', 'good']);
        $fcm = $this->fcm([
            $this->tokenResponse(),
            $this->errorResponse(404, 'NOT_FOUND', 'Requested entity was not found.', [['errorCode' => 'UNREGISTERED']]),
            $this->errorResponse(404, 'NOT_FOUND'),
            $this->errorResponse(400, 'INVALID_ARGUMENT', 'The registration token is not a valid FCM registration token'),
            new Response(200, [], '{}'),
        ]);

        $delivered = $fcm->send([
            [$devices['unreg'], $notification],
            [$devices['notfound'], $notification],
            [$devices['badtoken'], $notification],
            [$devices['good'], $notification],
        ]);

        $this->assertSame(['good'], Device::pluck('token')->all());
        $this->assertSame([$notification->id => true], $delivered);
    }

    public function testOtherFailuresKeepTheDeviceAndDoNotCountAsDelivered()
    {
        [, $notification, $devices] = $this->seedNotification('u|1', ['tok-a', 'tok-b']);
        $fcm = $this->fcm([
            $this->tokenResponse(),
            $this->errorResponse(500, 'INTERNAL'),
            $this->errorResponse(400, 'INVALID_ARGUMENT', 'Invalid JSON payload received.'),
        ]);

        $delivered = $fcm->send([[$devices['tok-a'], $notification], [$devices['tok-b'], $notification]]);

        $this->assertSame([], $delivered);
        $this->assertSame(2, Device::count());
    }

    // ---- unconfigured -----------------------------------------------------------

    public function testUnconfiguredClientSkipsSendingAndWarnsOnce()
    {
        [, $notification, $devices] = $this->seedNotification();

        $log = new class {
            public $warnings = [];

            public function warning($message, $context = [])
            {
                $this->warnings[] = $message;
            }
        };
        Log::swap($log);

        $fcm = $this->fcm([], null);

        $this->assertSame([], $fcm->send([[$devices['tok-a'], $notification]]));
        $this->assertSame([], $fcm->send([[$devices['tok-a'], $notification]]));
        $this->assertCount(0, $this->history);
        $this->assertCount(1, $log->warnings);
    }

    public function testAMissingServiceAccountFileCountsAsUnconfigured()
    {
        $auth = new GoogleAccessToken($this->mockClient([]), '/no/such/file.json', $this->tempFile());

        $this->assertFalse($auth->isConfigured());
        $this->assertFalse((new GoogleAccessToken($this->mockClient([]), $this->tempFile('not json'), $this->tempFile()))->isConfigured());
    }

    // ---- the job ----------------------------------------------------------------

    public function testJobSkipsGracefullyWhenFcmIsUnconfigured()
    {
        [, $notification] = $this->seedNotification();

        (new SendPushNotificationsJob([$notification->id]))->handle($this->fcm([], null));

        $this->assertNull($notification->fresh()->pushed_at);
        $this->assertCount(0, $this->history);
        $this->assertSame(1, Device::count());
    }

    public function testJobSendsToEveryDeviceOfEveryLoginOfTheMemberAndSetsPushedAt()
    {
        [$member, $notification] = $this->seedNotification('u|1', ['phone', 'tablet']);
        MemberLogin::create(['club_id' => 1, 'member_id' => $member->id, 'user_id' => 'u|1b', 'linked_at' => Carbon::now()]);
        Device::create(['user_id' => 'u|1b', 'token' => 'other-login', 'platform' => 'ios']);
        Device::create(['user_id' => 'u|stranger', 'token' => 'stranger', 'platform' => 'ios']);

        $fcm = $this->fcm([$this->tokenResponse(), new Response(200, [], '{}'), new Response(200, [], '{}'), new Response(200, [], '{}')]);

        (new SendPushNotificationsJob([$notification->id]))->handle($fcm);

        $this->assertCount(4, $this->history); // token + 3 sends
        $sent = [];
        foreach (array_slice($this->history, 1) as $entry) {
            $message = json_decode((string) $entry['request']->getBody(), true)['message'];
            $sent[$message['token']] = $message['data']['userId'];
        }
        $this->assertEqualsCanonicalizing(['phone' => 'u|1', 'tablet' => 'u|1', 'other-login' => 'u|1b'], $sent);
        $this->assertNotNull($notification->fresh()->pushed_at);
    }

    public function testJobLeavesPushedAtEmptyWhenNothingWasDelivered()
    {
        [, $notification] = $this->seedNotification();
        $fcm = $this->fcm([$this->tokenResponse(), $this->errorResponse(500, 'INTERNAL')]);

        (new SendPushNotificationsJob([$notification->id]))->handle($fcm);

        $this->assertNull($notification->fresh()->pushed_at);
    }

    public function testJobIgnoresAlreadyPushedNotifications()
    {
        [, $notification] = $this->seedNotification();
        $notification->update(['pushed_at' => Carbon::now()]);
        $fcm = $this->fcm([]);

        (new SendPushNotificationsJob([$notification->id]))->handle($fcm);

        $this->assertCount(0, $this->history);
    }
}
