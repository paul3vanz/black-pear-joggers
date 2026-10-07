<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Validator;

/**
 * Helpers shared by the /app controllers.
 */
trait AppResponses
{
    /**
     * Validates by hand: the app's exception handler turns a thrown
     * ValidationException into a 500. Returns the validator (check ->fails()).
     */
    protected function makeValidator(array $data, array $rules)
    {
        return Validator::make($data, $rules);
    }

    protected function validationFailed($validator)
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => $validator->errors()->first(),
            'errors' => $validator->errors(),
        ], 422);
    }

    protected function forbidden(string $message = 'You do not have permission to do that.')
    {
        return response()->json(['error' => 'forbidden', 'message' => $message], 403);
    }

    protected function notFound(string $message = 'Not found.')
    {
        return response()->json(['error' => 'not_found', 'message' => $message], 404);
    }

    /** True when ?since= is absent or parses as a date. */
    protected function sinceIsValid(Request $request): bool
    {
        $since = $request->query('since');

        if ($since === null || $since === '') {
            return true;
        }

        try {
            Carbon::parse($since);

            return true;
        } catch (\Throwable $e) {
            return false;
        }
    }

    /** The ?since= value as a Carbon, null when absent. */
    protected function since(Request $request): ?Carbon
    {
        $since = $request->query('since');

        return $since === null || $since === '' ? null : Carbon::parse($since);
    }

    /**
     * Timestamps are second-precision in the DB, so the server time is floored
     * to the second and `since` filters use >=. A row written later in the
     * same second is re-sent rather than missed (clients upsert by id).
     */
    protected function serverTime(): Carbon
    {
        return Carbon::now()->startOfSecond();
    }

    protected function invalidSince()
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => 'since must be an ISO8601 timestamp.',
            'errors' => ['since' => ['since must be an ISO8601 timestamp.']],
        ], 422);
    }
}
