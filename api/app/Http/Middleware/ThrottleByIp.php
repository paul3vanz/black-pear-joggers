<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Cache;

/**
 * Registered as `throttle`. Lumen has no throttle middleware, so this is a
 * tiny fixed-window limiter per client IP and path: `throttle:30,1` allows 30
 * requests a minute. Over the limit: 429 { error: 'too_many_requests' }.
 * Uses the default cache store, so it is only as strict as that store is
 * atomic. That is fine for a loose guard on an unauthenticated endpoint.
 */
class ThrottleByIp
{
    public function handle($request, Closure $next, $maxAttempts = 30, $minutes = 1)
    {
        $window = max(1, (int) $minutes) * 60;
        $key = 'throttle:' . sha1($request->ip() . '|' . $request->path());

        Cache::add($key, 0, $window);
        $hits = Cache::increment($key);

        if ($hits !== false && $hits > (int) $maxAttempts) {
            return response()->json([
                'error' => 'too_many_requests',
                'message' => 'Too many requests. Try again in a minute.',
            ], 429, ['Retry-After' => $window]);
        }

        return $next($request);
    }
}
