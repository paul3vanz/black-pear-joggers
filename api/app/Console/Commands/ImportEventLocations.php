<?php

namespace App\Console\Commands;

use App\Models\Club;
use App\Models\EventLocation;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Fills the club's event location list from a file (Phase 8, D78): parkrun's public events.json
 * (GeoJSON-like, downloaded by hand) or a CSV with the header
 * `name,slug,country,region,lat,lng,url`. Upserts by (club, kind, slug), never deletes.
 * A location the committee deleted stays deleted.
 *
 *   php artisan app:import-event-locations 1 events.json
 *   php artisan app:import-event-locations 1 events.json --country=97 --dry-run
 *   php artisan app:import-event-locations 1 places.csv --kind=race
 */
class ImportEventLocations extends Command
{
    protected $signature = 'app:import-event-locations
        {clubId : clubs.id}
        {file : parkrun events.json, or a .csv with the header name,slug,country,region,lat,lng,url}
        {--kind=parkrun : parkrun, race or other}
        {--country=97 : For events.json, keep only this parkrun country code (97 = UK)}
        {--dry-run : Show what would happen and write nothing}';

    protected $description = 'Import event locations (parkruns) into the club list from a JSON or CSV file';

    /** parkrun country code => ISO 3166 alpha-2, for the few we can be sure of. */
    const COUNTRIES = [97 => 'GB'];

    public function handle()
    {
        $club = Club::find((int) $this->argument('clubId'));

        if (!$club) {
            $this->error('No club with id ' . $this->argument('clubId') . '.');

            return 1;
        }

        $kind = (string) $this->option('kind');

        if (!in_array($kind, EventLocation::KINDS, true)) {
            $this->error('--kind must be one of: ' . implode(', ', EventLocation::KINDS) . '.');

            return 1;
        }

        $path = (string) $this->argument('file');

        if (!is_file($path) || !is_readable($path)) {
            $this->error("Cannot read the file: $path");

            return 1;
        }

        $raw = (string) file_get_contents($path);
        $raw = preg_replace('/^\xEF\xBB\xBF/', '', $raw);

        try {
            $rows = strtolower(pathinfo($path, PATHINFO_EXTENSION)) === 'csv'
                ? $this->fromCsv($raw)
                : $this->fromJson($raw, (int) $this->option('country'), $kind);
        } catch (\RuntimeException $e) {
            $this->error($e->getMessage());

            return 1;
        }

        $dry = (bool) $this->option('dry-run');
        $counts = ['created' => 0, 'updated' => 0, 'unchanged' => 0, 'skipped' => $rows['skipped']];

        $existing = EventLocation::withTrashed()->where('club_id', $club->id)->where('kind', $kind)
            ->whereNotNull('slug')->get()->keyBy('slug');

        DB::transaction(function () use ($rows, $club, $kind, $dry, $existing, &$counts) {
            $seen = [];

            foreach ($rows['items'] as $item) {
                if (isset($seen[$item['slug']])) {
                    $counts['skipped']++; // the file lists the same site twice

                    continue;
                }

                $seen[$item['slug']] = true;
                $location = $existing->get($item['slug']);

                if (!$location) {
                    $counts['created']++;

                    if (!$dry) {
                        EventLocation::create($item + ['club_id' => $club->id, 'kind' => $kind, 'source' => 'import']);
                    }

                    continue;
                }

                if ($location->trashed()) {
                    $counts['skipped']++;

                    continue;
                }

                $location->fill($item);

                if ($location->isDirty()) {
                    $counts['updated']++;

                    if (!$dry) {
                        $location->save();
                    }
                } else {
                    $counts['unchanged']++;
                }
            }
        });

        $this->info(sprintf(
            '%sCreated %d, updated %d, unchanged %d, skipped %d.',
            $dry ? '[dry run, nothing written] ' : '',
            $counts['created'],
            $counts['updated'],
            $counts['unchanged'],
            $counts['skipped']
        ));

        return 0;
    }

    /** @return array{items: array[], skipped: int} */
    private function fromJson(string $raw, int $country, string $kind): array
    {
        $data = json_decode($raw, true);

        if (!is_array($data)) {
            throw new \RuntimeException('The file is not valid JSON (' . json_last_error_msg() . ').');
        }

        $features = $data['features'] ?? ($data['events']['features'] ?? null);

        if (!is_array($features)) {
            throw new \RuntimeException('No "features" list found (expected top-level "features" or "events.features").');
        }

        $items = [];
        $skipped = 0;

        foreach ($features as $feature) {
            $props = is_array($feature) ? ($feature['properties'] ?? null) : null;

            if (!is_array($props) || (int) ($props['countrycode'] ?? -1) !== $country) {
                $skipped++;

                continue;
            }

            $slug = trim((string) ($props['eventname'] ?? ''));
            $name = trim((string) ($props['EventLongName'] ?? '')) ?: trim((string) ($props['EventShortName'] ?? ''));

            if ($slug === '' || $name === '') {
                $skipped++;

                continue;
            }

            $coordinates = $feature['geometry']['coordinates'] ?? [];

            $items[] = [
                'slug' => mb_substr($slug, 0, 80),
                'name' => mb_substr($name, 0, 120),
                'country' => self::COUNTRIES[$country] ?? null,
                'region' => null,
                'lat' => $this->coordinate($coordinates[1] ?? null, 90),
                'lng' => $this->coordinate($coordinates[0] ?? null, 180),
                'url' => $kind === 'parkrun' ? 'https://www.parkrun.org.uk/' . rawurlencode($slug) . '/' : null,
            ];
        }

        return ['items' => $items, 'skipped' => $skipped];
    }

    /** @return array{items: array[], skipped: int} */
    private function fromCsv(string $raw): array
    {
        $lines = preg_split('/\r\n|\n|\r/', $raw);
        $header = null;
        $items = [];
        $skipped = 0;

        foreach ($lines as $line) {
            if (trim($line) === '') {
                continue;
            }

            $cells = str_getcsv($line);

            if ($header === null) {
                $header = array_map(function ($cell) {
                    return strtolower(trim((string) $cell));
                }, $cells);

                if (!in_array('name', $header, true) || !in_array('slug', $header, true)) {
                    throw new \RuntimeException('The CSV header must include at least name and slug (name,slug,country,region,lat,lng,url).');
                }

                continue;
            }

            $row = [];
            foreach ($header as $i => $column) {
                $row[$column] = trim((string) ($cells[$i] ?? ''));
            }

            if (($row['slug'] ?? '') === '' || ($row['name'] ?? '') === '') {
                $skipped++;

                continue;
            }

            $country = strtoupper($row['country'] ?? '');

            $items[] = [
                'slug' => mb_substr($row['slug'], 0, 80),
                'name' => mb_substr($row['name'], 0, 120),
                'country' => strlen($country) === 2 ? $country : null,
                'region' => ($row['region'] ?? '') !== '' ? mb_substr($row['region'], 0, 80) : null,
                'lat' => $this->coordinate($row['lat'] ?? null, 90),
                'lng' => $this->coordinate($row['lng'] ?? null, 180),
                'url' => ($row['url'] ?? '') !== '' ? mb_substr($row['url'], 0, 255) : null,
            ];
        }

        if ($header === null) {
            throw new \RuntimeException('The CSV file is empty.');
        }

        return ['items' => $items, 'skipped' => $skipped];
    }

    /** A coordinate rounded to the column's 6 decimals, null when missing or out of range. */
    private function coordinate($value, int $limit): ?float
    {
        if ($value === null || $value === '' || !is_numeric($value) || abs((float) $value) > $limit) {
            return null;
        }

        return round((float) $value, 6);
    }
}
