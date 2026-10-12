<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Models\EventLocation;
use Illuminate\Support\Facades\DB;

/**
 * Phase 8a: php artisan app:import-event-locations (parkrun events.json in both shapes, CSV).
 */
class ImportEventLocationsTest extends AppApiTestCase
{
    private function fixture(string $name): string
    {
        return __DIR__ . '/fixtures/event-locations/' . $name;
    }

    /** Runs the command; returns [exit code, output]. */
    private function import(string $file, array $options = [], $club = 1): array
    {
        $kernel = $this->app['Illuminate\Contracts\Console\Kernel'];
        $code = $kernel->call('app:import-event-locations', ['clubId' => $club, 'file' => $file] + $options);

        return [$code, $kernel->output()];
    }

    private function clubTwo(): void
    {
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other', 'slug' => 'other', 'timezone' => 'Europe/London', 'created_at' => '2026-01-01', 'updated_at' => '2026-01-01']);
    }

    public function testImportsTheNestedEventsFileForTheUk()
    {
        [$code, $out] = $this->import($this->fixture('events.json'));

        $this->assertSame(0, $code, $out);
        // worcester, bushy, shortonly and nocoords are in; sydney is another country and one row has no name or code.
        $this->assertStringContainsString('Created 4, updated 0, unchanged 0, skipped 2.', $out);

        $rows = EventLocation::orderBy('slug')->get()->keyBy('slug');
        $this->assertSame(['bushy', 'nocoords', 'shortonly', 'worcester'], $rows->keys()->all());

        $worcester = $rows['worcester'];
        $this->assertSame(1, $worcester->club_id);
        $this->assertSame('parkrun', $worcester->kind);
        $this->assertSame('Worcester parkrun', $worcester->name);
        $this->assertSame('import', $worcester->source);
        $this->assertSame('GB', $worcester->country);
        $this->assertSame('https://www.parkrun.org.uk/worcester/', $worcester->url);
        $this->assertEqualsWithDelta(52.19623, $worcester->lat, 0.000001);
        $this->assertEqualsWithDelta(-2.2258, $worcester->lng, 0.000001);

        $this->assertSame('Short Only', $rows['shortonly']->name, 'falls back to the short name');
        $this->assertNull($rows['nocoords']->lat);
        $this->assertNull($rows['nocoords']->lng);
    }

    public function testImportsTheTopLevelFeaturesShapeWithAByteOrderMark()
    {
        $raw = file_get_contents($this->fixture('events-flat-bom.json'));
        $this->assertSame("\xEF\xBB\xBF", substr($raw, 0, 3), 'the fixture must carry the BOM');

        [$code, $out] = $this->import($this->fixture('events-flat-bom.json'));

        $this->assertSame(0, $code, $out);
        $this->assertStringContainsString('Created 2, updated 0, unchanged 0, skipped 1.', $out);
        $this->assertSame(['malvern', 'worcester'], EventLocation::orderBy('slug')->pluck('slug')->all());
    }

    public function testTheCountryOptionFiltersOnParkrunsCountryCode()
    {
        [$code, $out] = $this->import($this->fixture('events-flat-bom.json'), ['--country' => 42]);

        $this->assertSame(0, $code, $out);
        $this->assertSame(['galway'], EventLocation::pluck('slug')->all());
        $this->assertNull(EventLocation::first()->country, 'only the UK code has a known ISO mapping');
    }

    public function testReImportingUpdatesInPlaceAndNeverDeletes()
    {
        $this->import($this->fixture('events.json'));
        $id = EventLocation::where('slug', 'worcester')->value('id');
        EventLocation::where('slug', 'worcester')->update(['name' => 'Old name', 'lat' => 1.0]);
        EventLocation::create(['club_id' => 1, 'kind' => 'parkrun', 'name' => 'Handmade parkrun', 'slug' => 'handmade', 'source' => 'manual']);
        EventLocation::where('slug', 'bushy')->first()->delete(); // the committee removed it

        [$code, $out] = $this->import($this->fixture('events.json'));

        $this->assertSame(0, $code, $out);
        $this->assertStringContainsString('Created 0, updated 1, unchanged 2, skipped 3.', $out);
        $this->assertSame($id, EventLocation::where('slug', 'worcester')->value('id'));
        $this->assertSame('Worcester parkrun', EventLocation::where('slug', 'worcester')->value('name'));
        $this->assertEqualsWithDelta(52.19623, EventLocation::where('slug', 'worcester')->value('lat'), 0.000001);
        $this->assertSame(1, EventLocation::where('slug', 'handmade')->count(), 'rows missing from the file are kept');
        $this->assertNull(EventLocation::where('slug', 'bushy')->first(), 'a location the committee deleted stays deleted');
        $this->assertSame(1, EventLocation::withTrashed()->where('slug', 'bushy')->count());
    }

    public function testAnUpdateMovesTheRowsUpdatedAtSoSyncDeliversIt()
    {
        $this->import($this->fixture('events.json'));
        DB::table('event_locations')->where('slug', 'worcester')->update(['name' => 'Old name', 'updated_at' => '2026-01-01 00:00:00']);
        DB::table('event_locations')->where('slug', 'bushy')->update(['updated_at' => '2026-01-01 00:00:00']);

        $this->import($this->fixture('events.json'));

        $this->assertGreaterThan('2026-01-01 00:00:00', (string) DB::table('event_locations')->where('slug', 'worcester')->value('updated_at'));
        $this->assertSame('2026-01-01 00:00:00', (string) DB::table('event_locations')->where('slug', 'bushy')->value('updated_at'), 'an unchanged row is not touched');
    }

    public function testDryRunWritesNothing()
    {
        [$code, $out] = $this->import($this->fixture('events.json'), ['--dry-run' => true]);

        $this->assertSame(0, $code, $out);
        $this->assertStringContainsString('dry run', $out);
        $this->assertStringContainsString('Created 4,', $out);
        $this->assertSame(0, EventLocation::count());

        $this->import($this->fixture('events.json'));
        EventLocation::where('slug', 'worcester')->update(['name' => 'Old name']);
        [, $out] = $this->import($this->fixture('events.json'), ['--dry-run' => true]);

        $this->assertStringContainsString('updated 1,', $out);
        $this->assertSame('Old name', EventLocation::where('slug', 'worcester')->value('name'));
    }

    public function testImportsACsvByExtension()
    {
        [$code, $out] = $this->import($this->fixture('places.csv'), ['--kind' => 'race']);

        $this->assertSame(0, $code, $out);
        $this->assertStringContainsString('Created 2, updated 0, unchanged 0, skipped 2.', $out);

        $droitwich = EventLocation::where('slug', 'droitwich-10k')->first();
        $this->assertSame('race', $droitwich->kind);
        $this->assertSame('Droitwich 10k', $droitwich->name);
        $this->assertSame('GB', $droitwich->country);
        $this->assertSame('Worcestershire', $droitwich->region);
        $this->assertSame('https://example.org/droitwich', $droitwich->url);
        $this->assertEqualsWithDelta(52.2678, $droitwich->lat, 0.000001);

        $mudder = EventLocation::where('slug', 'tm-eastnor')->first();
        $this->assertSame('Tough Mudder, Eastnor', $mudder->name);
        $this->assertSame('GB', $mudder->country);
        $this->assertNull($mudder->lat);
        $this->assertNull($mudder->url);
    }

    public function testTheSameSlugInDifferentKindsOrClubsDoesNotCollide()
    {
        $this->clubTwo();

        $this->import($this->fixture('events-flat-bom.json'));
        $this->import($this->fixture('events-flat-bom.json'), [], 2);
        $this->import($this->fixture('events-flat-bom.json'), ['--kind' => 'other']);

        $this->assertSame(6, EventLocation::count());
        $this->assertSame(2, EventLocation::where('club_id', 2)->count());
        $this->assertSame(2, EventLocation::where('kind', 'other')->count());
        $this->assertNull(EventLocation::where('kind', 'other')->first()->url, 'only parkrun rows get a parkrun url');
    }

    public function testClearErrorsForBadInput()
    {
        [$code, $out] = $this->import($this->fixture('events.json'), [], 99);
        $this->assertSame(1, $code);
        $this->assertStringContainsString('No club with id 99', $out);

        [$code, $out] = $this->import($this->fixture('missing.json'));
        $this->assertSame(1, $code);
        $this->assertStringContainsString('Cannot read the file', $out);

        [$code, $out] = $this->import($this->fixture('truncated.json'));
        $this->assertSame(1, $code);
        $this->assertStringContainsString('not valid JSON', $out);

        [$code, $out] = $this->import($this->fixture('no-features.json'));
        $this->assertSame(1, $code);
        $this->assertStringContainsString('features', $out);

        [$code, $out] = $this->import($this->fixture('bad-header.csv'));
        $this->assertSame(1, $code);
        $this->assertStringContainsString('name and slug', $out);

        [$code, $out] = $this->import($this->fixture('events.json'), ['--kind' => 'marathon']);
        $this->assertSame(1, $code);
        $this->assertStringContainsString('--kind must be one of', $out);

        $this->assertSame(0, EventLocation::count());
    }
}
