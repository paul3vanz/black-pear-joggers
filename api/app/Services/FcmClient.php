<?php

namespace App\Services;

use App\Models\Device;
use App\Models\Notification;
use GuzzleHttp\Client;
use GuzzleHttp\ClientInterface;
use GuzzleHttp\Exception\RequestException;
use GuzzleHttp\Pool;
use GuzzleHttp\Psr7\Request;
use Illuminate\Support\Facades\Log;
use Psr\Http\Message\ResponseInterface;

/**
 * Sends push messages through FCM HTTP v1, one message per device token.
 *
 * Auth is handled by GoogleAccessToken (service-account JSON from
 * FCM_SERVICE_ACCOUNT_PATH). With no usable file the client logs one warning
 * and skips sending, so the API can be deployed before Firebase is set up
 * (inbox rows are written regardless).
 */
class FcmClient
{
    const SEND_URL = 'https://fcm.googleapis.com/v1/projects/%s/messages:send';

    private static $warned = false;

    private $http;
    private $auth;

    public function __construct(?ClientInterface $http = null, ?GoogleAccessToken $auth = null)
    {
        $this->http = $http ?? new Client(['timeout' => 15]);
        $this->auth = $auth ?? new GoogleAccessToken($this->http);
    }

    /** Resets the log-once flag (tests). */
    public static function resetWarning(): void
    {
        self::$warned = false;
    }

    public function isConfigured(): bool
    {
        if ($this->auth->isConfigured()) {
            return true;
        }

        if (!self::$warned) {
            self::$warned = true;
            Log::warning('FCM is not configured (FCM_SERVICE_ACCOUNT_PATH unset or unreadable); push notifications are skipped.');
        }

        return false;
    }

    /** The FCM v1 request body for one notification to one device. */
    public function buildMessage(Device $device, Notification $notification): array
    {
        $data = $notification->data ?? [];

        return ['message' => [
            'token' => $device->token,
            'notification' => [
                'title' => $notification->title,
                'body' => $notification->body,
            ],
            'data' => [
                'notificationId' => (string) $notification->id,
                'clubId' => (string) $notification->club_id,
                'userId' => (string) $device->user_id,
                'category' => (string) $notification->category,
                'route' => (string) ($data['route'] ?? ''),
            ],
            'android' => [
                'notification' => ['channel_id' => $notification->category],
            ],
            'apns' => [
                'payload' => ['aps' => ['sound' => 'default']],
            ],
        ]];
    }

    /**
     * Sends each [device, notification] pair as its own message.
     *
     * Devices FCM says are gone (UNREGISTERED, NOT_FOUND, invalid token) are
     * deleted. Returns the ids of notifications with at least one accepted send.
     *
     * @param array<int, array{0: Device, 1: Notification}> $pairs
     * @return array<string, true> notification id => true
     */
    public function send(array $pairs): array
    {
        if (!$pairs || !$this->isConfigured()) {
            return [];
        }

        $accessToken = $this->auth->get();
        $url = sprintf(self::SEND_URL, $this->auth->projectId());
        $delivered = [];

        $requests = function () use ($pairs, $url, $accessToken) {
            foreach ($pairs as $i => [$device, $notification]) {
                yield $i => new Request('POST', $url, [
                    'Authorization' => 'Bearer ' . $accessToken,
                    'Content-Type' => 'application/json',
                ], json_encode($this->buildMessage($device, $notification)));
            }
        };

        $pool = new Pool($this->http, $requests(), [
            'concurrency' => 10,
            'fulfilled' => function (ResponseInterface $response, $i) use ($pairs, &$delivered) {
                $delivered[$pairs[$i][1]->id] = true;
            },
            'rejected' => function ($reason, $i) use ($pairs) {
                $this->handleFailure($reason, $pairs[$i][0]);
            },
        ]);

        $pool->promise()->wait();

        return $delivered;
    }

    private function handleFailure($reason, Device $device): void
    {
        $response = $reason instanceof RequestException ? $reason->getResponse() : null;

        if (!$response) {
            Log::warning('FCM send failed', ['error' => $reason instanceof \Throwable ? $reason->getMessage() : (string) $reason]);

            return;
        }

        $status = $response->getStatusCode();
        $error = json_decode((string) $response->getBody(), true)['error'] ?? [];

        if (self::isDeadToken($error)) {
            Device::where('id', $device->id)->delete();

            return;
        }

        if ($status === 401) {
            $this->auth->forget();
        }

        Log::warning('FCM send rejected', ['status' => $status, 'error' => $error['status'] ?? null]);
    }

    /** True when the error says the registration token will never work again. */
    public static function isDeadToken(array $error): bool
    {
        if (in_array($error['status'] ?? '', ['NOT_FOUND', 'UNREGISTERED'], true)) {
            return true;
        }

        foreach ($error['details'] ?? [] as $detail) {
            if (($detail['errorCode'] ?? '') === 'UNREGISTERED') {
                return true;
            }
        }

        return ($error['status'] ?? '') === 'INVALID_ARGUMENT'
            && stripos($error['message'] ?? '', 'registration token') !== false;
    }
}
