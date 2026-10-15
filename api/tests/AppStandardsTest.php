<?php

require_once __DIR__ . '/AppApiTestCase.php';

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * GET /app/clubs/{clubId}/standards on in-memory SQLite. The legacy standards,
 * awards and events tables have no migrations, so this test creates minimal versions.
 */
class AppStandardsTest extends AppApiTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('awards', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('name');
        });
        Schema::create('events', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->string('event');
            $table->float('distance');
            $table->string('alias')->nullable();
            $table->integer('has_standard')->nullable();
        });
        Schema::create('standards', function (Blueprint $table) {
            $table->increments('id');
            $table->string('gender');
            $table->string('category');
            $table->integer('event_id');
            $table->integer('award_id');
            $table->string('time');
            $table->float('time_parsed')->nullable();
        });

        // Inserted out of order on purpose.
        DB::table('awards')->insert([
            ['id' => 4, 'name' => 'Platinum'],
            ['id' => 2, 'name' => 'Silver'],
            ['id' => 1, 'name' => 'Bronze'],
            ['id' => 3, 'name' => 'Gold'],
        ]);
        DB::table('events')->insert([
            ['id' => 10, 'event' => 'Marathon', 'distance' => 42195, 'alias' => 'Mar'],
            ['id' => 11, 'event' => 'Mile', 'distance' => 1609.34, 'alias' => '1M'],
            ['id' => 12, 'event' => '5K', 'distance' => 5000, 'alias' => '5K'],
            ['id' => 13, 'event' => 'Half Marathon', 'distance' => 21097.5, 'alias' => 'HM'],
            ['id' => 14, 'event' => 'Parkrun', 'distance' => 5000, 'alias' => 'parkrun'], // no standards: not listed
        ]);

        $this->standard('M', 'V45', 11, 1, '7:25', 445);
        $this->standard('M', 'V45', 11, 2, '6:50', 410);
        $this->standard('M', 'V45', 12, 1, '25:48', 1548);
        $this->standard('M', 'V45', 10, 1, '3:58:26', 14306);
        $this->standard('M', 'SEN', 13, 1, '1:58:26', null);   // parsed from the text
        $this->standard('M', 'U23', 11, 1, '7:00', 420);
        $this->standard('M', 'U20', 11, 1, '7:10', 430);
        $this->standard('M', 'V100', 11, 1, '12:00', 720);      // an out-of-range band, still ordered numerically
        $this->standard('M', 'V80', 11, 1, '10:00', 600);
        $this->standard('M', 'V35', 11, 1, '7:20', 440);
        $this->standard('M', 'V70', 11, 1, '9:00', 540);
        $this->standard('W', 'SEN', 12, 3, '22:00', 1320);
        $this->standard('W', 'V35', 12, 1, '28:00', 1680);
    }

    private function standard(string $gender, string $category, int $event, int $award, string $time, $parsed): void
    {
        DB::table('standards')->insert([
            'gender' => $gender,
            'category' => $category,
            'event_id' => $event,
            'award_id' => $award,
            'time' => $time,
            'time_parsed' => $parsed,
        ]);
    }

    private function dobForAge(int $age): string
    {
        return Carbon::now()->subYears($age)->subDays(10)->format('Y-m-d');
    }

    private function memberAged(string $sub, int $id, string $gender, ?int $age): void
    {
        $this->member($sub, $id);
        DB::table('athletes')->where('id', $id)->update([
            'gender' => $gender,
            'dob' => $age === null ? Carbon::now()->format('Y-m-d') : $this->dobForAge($age), // born today: age 0, no category
        ]);
    }

    public function testShapeAndOrdering()
    {
        $this->member('auth0|a', 1);

        [$status, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertSame(200, $status);
        $this->assertSame(['awards', 'events', 'categories', 'items', 'mine', 'updatedAt'], array_keys($body));
        $this->assertSame(['Bronze', 'Silver', 'Gold', 'Platinum'], $body['awards']);
        $this->assertSame([
            ['event' => 'Mile', 'distanceM' => 1609.34],
            ['event' => '5K', 'distanceM' => 5000],
            ['event' => 'Half Marathon', 'distanceM' => 21097.5],
            ['event' => 'Marathon', 'distanceM' => 42195],
        ], $body['events']);
        $this->assertMatchesRegularExpression('/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/', $body['updatedAt']);

        $this->assertSame(
            ['gender' => 'male', 'category' => 'U20', 'event' => 'Mile', 'award' => 'Bronze', 'time' => '7:10', 'timeS' => 430],
            $body['items'][0]
        );

        // Male rows first, then by category, event distance, then award.
        $keys = array_map(fn ($i) => "{$i['gender']}/{$i['category']}/{$i['event']}/{$i['award']}", $body['items']);
        $this->assertSame([
            'male/U20/Mile/Bronze',
            'male/U23/Mile/Bronze',
            'male/SEN/Half Marathon/Bronze',
            'male/V35/Mile/Bronze',
            'male/V45/Mile/Bronze',
            'male/V45/Mile/Silver',
            'male/V45/5K/Bronze',
            'male/V45/Marathon/Bronze',
            'male/V70/Mile/Bronze',
            'male/V80/Mile/Bronze',
            'male/V100/Mile/Bronze',
            'female/SEN/5K/Gold',
            'female/V35/5K/Bronze',
        ], $keys);
    }

    public function testCategoriesAreOrderedPerGender()
    {
        $this->member('auth0|a', 1);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertSame(['U20', 'U23', 'SEN', 'V35', 'V45', 'V70', 'V80', 'V100'], $body['categories']['male']);
        $this->assertSame(['SEN', 'V35'], $body['categories']['female']);
    }

    public function testTimeSecondsFromMinutesSecondsAndHoursMinutesSeconds()
    {
        $this->member('auth0|a', 1);
        // Both parsed from the text because time_parsed is empty.
        $this->standard('W', 'V40', 12, 1, '25:48', null);
        $this->standard('W', 'V40', 10, 1, '1:58:26', null);
        $this->standard('W', 'V40', 11, 1, '7:25', 0);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $v40 = [];
        foreach ($body['items'] as $item) {
            if ($item['gender'] === 'female' && $item['category'] === 'V40') {
                $v40[$item['event']] = [$item['time'], $item['timeS']];
            }
        }

        $this->assertSame(['25:48', 1548], $v40['5K']);
        $this->assertSame(['1:58:26', 7106], $v40['Marathon']);
        $this->assertSame(['7:25', 445], $v40['Mile']);
    }

    public function testTimeSecondsPrefersTimeParsed()
    {
        $this->member('auth0|a', 1);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $sen = array_values(array_filter($body['items'], fn ($i) => $i['category'] === 'SEN' && $i['gender'] === 'male'));
        $this->assertSame(7106, $sen[0]['timeS']); // text only: 1:58:26
        $marathon = array_values(array_filter($body['items'], fn ($i) => $i['event'] === 'Marathon'));
        $this->assertSame(14306, $marathon[0]['timeS']);
    }

    public function testMineForAMaleV45()
    {
        $this->memberAged('auth0|a', 1, 'M', 47);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertSame(['gender' => 'male', 'category' => 'V45'], $body['mine']);
    }

    public function testMineForAFemaleSen()
    {
        $this->memberAged('auth0|a', 1, 'W', 30);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertSame(['gender' => 'female', 'category' => 'SEN'], $body['mine']);
    }

    public function testMineIsNullWithoutADateOfBirth()
    {
        $this->memberAged('auth0|a', 1, 'M', null);

        [$status, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertSame(200, $status);
        $this->assertNull($body['mine']);
    }

    public function testMineIsNullWithoutAGender()
    {
        $this->memberAged('auth0|a', 1, '', 40);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertNull($body['mine']);
    }

    public function testMineFallsBackToTheOldestBandInTheTable()
    {
        // Women's table stops at V35 here; a 52-year-old woman is V50.
        $this->memberAged('auth0|a', 1, 'W', 52);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertSame(['gender' => 'female', 'category' => 'V35'], $body['mine']);
    }

    public function testMineIsNullWhenTheTableHasNoRowsForTheGender()
    {
        DB::table('standards')->where('gender', 'W')->delete();
        $this->memberAged('auth0|a', 1, 'W', 30);

        [, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|a');

        $this->assertNull($body['mine']);
        $this->assertSame([], $body['categories']['female']);
    }

    public function testEtagAndNotModified()
    {
        $this->memberAged('auth0|a', 1, 'M', 47);

        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|a']);
        $this->assertSame(200, $this->response->getStatusCode());
        $etag = $this->response->headers->get('ETag');
        $this->assertMatchesRegularExpression('/^"[0-9a-f]{40}"$/', $etag);

        // Same data, same tag, and a matching If-None-Match gets an empty 304.
        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|a', 'If-None-Match' => $etag]);
        $this->assertSame(304, $this->response->getStatusCode());
        $this->assertSame('', $this->response->getContent());
        $this->assertSame($etag, $this->response->headers->get('ETag'));

        // A weak or listed validator matches too.
        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|a', 'If-None-Match' => '"other", W/' . $etag]);
        $this->assertSame(304, $this->response->getStatusCode());

        // A stale tag gets the full body.
        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|a', 'If-None-Match' => '"stale"']);
        $this->assertSame(200, $this->response->getStatusCode());

        // Changing a standard changes the tag.
        DB::table('standards')->where('time', '25:48')->update(['time' => '25:30', 'time_parsed' => 1530]);
        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|a', 'If-None-Match' => $etag]);
        $this->assertSame(200, $this->response->getStatusCode());
        $this->assertNotSame($etag, $this->response->headers->get('ETag'));
    }

    public function testEtagDiffersWhenMineDiffers()
    {
        $this->memberAged('auth0|a', 1, 'M', 47);
        $this->memberAged('auth0|b', 2, 'W', 30);

        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|a']);
        $a = $this->response->headers->get('ETag');
        $this->app['auth']->forgetGuards();
        $this->json('GET', '/app/clubs/1/standards', [], ['X-Test-Sub' => 'auth0|b']);

        $this->assertNotSame($a, $this->response->headers->get('ETag'));
    }

    public function testUnlinkedCallerGets403()
    {
        [$status, $body] = $this->call_('GET', '/app/clubs/1/standards', 'auth0|nobody');

        $this->assertSame(403, $status);
        $this->assertSame('not_a_member', $body['error']);
    }

    public function testUnauthenticatedGets401()
    {
        [$status] = $this->call_('GET', '/app/clubs/1/standards', null);

        $this->assertSame(401, $status);
    }

    public function testUnknownClubGets404()
    {
        $this->member('auth0|a', 1);

        [$status, $body] = $this->call_('GET', '/app/clubs/2/standards', 'auth0|a');

        $this->assertSame(404, $status);
        $this->assertSame('club_not_found', $body['error']);
    }
}
