<?php

namespace App\Services;

/**
 * Signed, versioned links to a member's photo (Phase 6.5, D60).
 *
 * sig = hex hmac-sha256("{clubId}|{memberId}|{version}", key). The key is the APP_KEY
 * string exactly as it is written in the env file (a `base64:` prefix is NOT decoded:
 * the raw string is the secret), so signing and checking always use the same bytes.
 * With no APP_KEY there is no key, so no link is ever issued and none is ever accepted.
 */
class MemberPhotoLink
{
    private static function key(): string
    {
        return (string) env('APP_KEY', '');
    }

    public static function sign($clubId, $memberId, $version): string
    {
        return hash_hmac('sha256', $clubId . '|' . $memberId . '|' . $version, self::key());
    }

    /** True when $sig is the signature for exactly this club, member and version. */
    public static function valid($clubId, $memberId, $version, $sig): bool
    {
        if (self::key() === '' || !is_string($version) || $version === '' || !is_string($sig) || $sig === '') {
            return false;
        }

        return hash_equals(self::sign($clubId, $memberId, $version), $sig);
    }

    /** Relative path the app prepends its API base URL to; null when there is no photo (or no key). */
    public static function path($clubId, $memberId, ?string $version): ?string
    {
        if ($version === null || $version === '' || self::key() === '') {
            return null;
        }

        return '/app/clubs/' . $clubId . '/members/' . $memberId . '/photo?v=' . $version
            . '&sig=' . self::sign($clubId, $memberId, $version);
    }
}
