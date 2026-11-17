<?php

namespace App\Console\Commands;

use App\Models\EventLocation;
use GuzzleHttp\Client;
use Illuminate\Console\Command;

/**
 * Fills event_locations.region (e.g. "Worcester, West Midlands") for rows that have lat/lng but no region,
 * using the free postcodes.io bulk reverse-geocode API (UK only, no key). Safe to run twice.
 *
 *   php artisan app:backfill-event-regions 1 --dry-run
 */
class BackfillEventRegions extends Command
{
    protected $signature = 'app:backfill-event-regions
        {clubId : clubs.id}
        {--dry-run : Show what would be set and write nothing}';

    protected $description = 'Set the region of event locations from their lat/lng (postcodes.io, UK only)';

    public function handle()
    {
        $dry = (bool) $this->option('dry-run');
        $rows = EventLocation::where('club_id', (int) $this->argument('clubId'))
            ->whereNull('region')->whereNotNull('lat')->whereNotNull('lng')
            ->where(function ($q) {
                $q->whereNull('country')->orWhere('country', 'GB');
            })->get();

        $client = new Client(['timeout' => 20]);
        $set = 0;
        $missed = 0;

        foreach ($rows->chunk(100) as $chunk) {
            $chunk = $chunk->values();

            $response = $client->post('https://api.postcodes.io/postcodes', ['json' => [
                'geolocations' => $chunk->map(fn ($l) => [
                    'longitude' => (float) $l->lng,
                    'latitude' => (float) $l->lat,
                    'radius' => 2000,
                    'limit' => 1,
                ])->all(),
            ]]);

            $results = json_decode((string) $response->getBody(), true)['result'] ?? [];

            foreach ($chunk as $i => $location) {
                $hit = $results[$i]['result'][0] ?? null;
                $region = $hit ? self::label($hit) : null;

                if ($region === null) {
                    $missed++;

                    continue;
                }

                $set++;
                $this->line(($dry ? '[dry] ' : '') . $location->name . ' => ' . $region);

                if (!$dry) {
                    $location->region = $region;
                    $location->save();
                }
            }
        }

        $this->info(sprintf('%sSet %d, no result for %d.', $dry ? '[dry run, nothing written] ' : '', $set, $missed));

        return 0;
    }

    /** "Worcester, West Midlands": the county (else district), then the region, without repeats. */
    public static function label(array $hit): ?string
    {
        $parts = [];

        foreach ([($hit['admin_county'] ?? null) ?: ($hit['admin_district'] ?? null), $hit['region'] ?? null] as $p) {
            $p = is_string($p) ? trim($p) : '';

            if ($p !== '' && !in_array($p, $parts, true)) {
                $parts[] = $p;
            }
        }

        return $parts ? mb_substr(implode(', ', $parts), 0, 80) : null;
    }
}
