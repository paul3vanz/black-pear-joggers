<?php

namespace App\Services;

use GuzzleHttp\Client;
use GuzzleHttp\ClientInterface;
use Illuminate\Support\Carbon;
use phpseclib3\Crypt\PublicKeyLoader;
use phpseclib3\Crypt\RSA;

/**
 * OAuth for a Google service account: signs an RS256 JWT with phpseclib,
 * exchanges it for an access token and caches that token in a small file
 * until shortly before it expires.
 *
 * The key file path comes from env FCM_SERVICE_ACCOUNT_PATH (absolute, or
 * relative to the api folder).
 */
class GoogleAccessToken
{
    const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
    const TOKEN_URL = 'https://oauth2.googleapis.com/token';

    /** Refresh the cached token this many seconds before it expires. */
    const EXPIRY_MARGIN = 120;

    private $http;
    private $path;
    private $cachePath;
    private $account;
    private $accountLoaded = false;

    public function __construct(?ClientInterface $http = null, ?string $serviceAccountPath = null, ?string $cachePath = null)
    {
        $this->http = $http ?? new Client(['timeout' => 15]);
        $this->path = $serviceAccountPath ?? env('FCM_SERVICE_ACCOUNT_PATH');
        $this->cachePath = $cachePath ?? storage_path('app/fcm-access-token.json');
    }

    /** The decoded service-account file, or null when missing or invalid. */
    public function account(): ?array
    {
        if ($this->accountLoaded) {
            return $this->account;
        }

        $this->accountLoaded = true;

        if (!$this->path) {
            return null;
        }

        $path = $this->path;
        if (!preg_match('#^([A-Za-z]:[\\\\/]|/)#', $path)) {
            $path = base_path($path);
        }

        if (!is_file($path) || !is_readable($path)) {
            return null;
        }

        $json = json_decode((string) file_get_contents($path), true);

        if (!is_array($json) || empty($json['client_email']) || empty($json['private_key']) || empty($json['project_id'])) {
            return null;
        }

        return $this->account = $json;
    }

    public function isConfigured(): bool
    {
        return $this->account() !== null;
    }

    public function projectId(): string
    {
        return $this->account()['project_id'];
    }

    private static function b64(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /** The claims of the JWT we exchange for an access token. */
    public function jwtClaims(?int $now = null): array
    {
        $now = $now ?? Carbon::now()->timestamp;

        return [
            'iss' => $this->account()['client_email'],
            'scope' => self::SCOPE,
            'aud' => self::TOKEN_URL,
            'iat' => $now,
            'exp' => $now + 3600,
        ];
    }

    /** An RS256-signed JWT (header.claims.signature). */
    public function buildJwt(?int $now = null): string
    {
        $signing = self::b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']))
            . '.' . self::b64(json_encode($this->jwtClaims($now)));

        $key = PublicKeyLoader::load($this->account()['private_key'])
            ->withPadding(RSA::SIGNATURE_PKCS1)
            ->withHash('sha256');

        return $signing . '.' . self::b64($key->sign($signing));
    }

    /** A valid access token, from the cache file or freshly exchanged. */
    public function get(): string
    {
        $now = Carbon::now()->timestamp;

        if (is_file($this->cachePath)) {
            $cached = json_decode((string) file_get_contents($this->cachePath), true);

            if (is_array($cached) && !empty($cached['token']) && ($cached['expires_at'] ?? 0) > $now + self::EXPIRY_MARGIN) {
                return $cached['token'];
            }
        }

        $response = $this->http->request('POST', self::TOKEN_URL, [
            'form_params' => [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $this->buildJwt($now),
            ],
        ]);

        $body = json_decode((string) $response->getBody(), true);
        $token = $body['access_token'] ?? null;

        if (!$token) {
            throw new \RuntimeException('Google token exchange returned no access_token.');
        }

        $this->writeCache($token, $now + (int) ($body['expires_in'] ?? 3600));

        return $token;
    }

    /** Drops the cached token, e.g. after a 401. */
    public function forget(): void
    {
        if (is_file($this->cachePath)) {
            @unlink($this->cachePath);
        }
    }

    private function writeCache(string $token, int $expiresAt): void
    {
        $dir = dirname($this->cachePath);

        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }

        @file_put_contents($this->cachePath, json_encode(['token' => $token, 'expires_at' => $expiresAt]), LOCK_EX);
    }
}
