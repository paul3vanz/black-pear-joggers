<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\Schema;
use Log;

/**
 * The API deploys straight to the server by FTP on every push to master, but
 * migrations are run by hand afterwards. That leaves a window where the code
 * expects athletes.po10_guid and the column is not there yet.
 *
 * Without this guard the nightly performance and ranking jobs would throw an
 * SQL error every night into the Slack error webhook. Check once and log
 * something that says what to do instead.
 */
trait ChecksPowerOfTenColumn
{
    private function powerOfTenColumnExists(): bool
    {
        if (Schema::hasColumn('athletes', 'po10_guid')) {
            return true;
        }

        Log::warning(
            'athletes.po10_guid is missing, skipping Power of 10 fetch. '
            . 'Run: php artisan migrate'
        );

        return false;
    }
}
